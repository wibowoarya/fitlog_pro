import 'package:flutter/foundation.dart';
import '../data/models/exercise_model.dart';
import '../data/models/user_model.dart';
import '../data/models/workout_log_model.dart';
import '../data/models/workout_plan_model.dart';
import '../data/repositories/workout_repository.dart';

class WorkoutProvider extends ChangeNotifier {
  final WorkoutRepository _repository;

  List<WorkoutPlan> _plans = [];
  String _activePlanId = '';
  List<WorkoutSessionLog> _logs = [];

  // Active gym session state
  int _selectedWeekday = DateTime.now().weekday;
  final Map<String, List<LoggedSet>> _activeSetsByExercise = {};
  DateTime? _sessionStartedAt;
  bool _isSyncing = false;
  String? _syncMessage;
  AuthSession? _attachedSession;
  String? _loadedSupabaseUserId;

  WorkoutProvider({required WorkoutRepository repository})
      : _repository = repository {
    _plans = _repository.loadPlans();
    final savedActive = _repository.loadActivePlanId();
    _activePlanId =
        (savedActive != null && _plans.any((p) => p.id == savedActive))
            ? savedActive
            : _plans.first.id;
    _logs = _repository.loadLogs();
    _prepareActiveSetsForDay(selectedWorkoutDay);
  }

  List<WorkoutPlan> get plans => _plans;
  List<WorkoutSessionLog> get logs => _logs;
  int get selectedWeekday => _selectedWeekday;
  bool get isSyncing => _isSyncing;
  String? get syncMessage => _syncMessage;

  WorkoutPlan get activePlan => _plans.firstWhere(
        (p) => p.id == _activePlanId,
        orElse: () => _plans.first,
      );

  WorkoutDay? get selectedWorkoutDay {
    for (final d in activePlan.days) {
      if (d.weekday == _selectedWeekday) return d;
    }
    return activePlan.days.isNotEmpty ? activePlan.days.first : null;
  }

  List<LoggedSet> setsForPlannedExercise(PlannedExercise pe) {
    return _activeSetsByExercise[pe.id] ?? [];
  }

  int get totalActiveSetsCount => _activeSetsByExercise.values
      .fold(0, (sum, list) => sum + list.length);

  int get completedActiveSetsCount => _activeSetsByExercise.values.fold(
      0, (sum, list) => sum + list.where((s) => s.isCompleted).length);

  double get activeSessionProgress => totalActiveSetsCount == 0
      ? 0
      : completedActiveSetsCount / totalActiveSetsCount;

  void selectWeekday(int weekday) {
    _selectedWeekday = weekday;
    _prepareActiveSetsForDay(selectedWorkoutDay);
    notifyListeners();
  }

  void _prepareActiveSetsForDay(WorkoutDay? day) {
    _activeSetsByExercise.clear();
    _sessionStartedAt = DateTime.now();
    if (day == null || day.isRestDay) return;

    for (final pe in day.exercises) {
      _activeSetsByExercise[pe.id] = List.generate(
        pe.targetSets,
        (index) => LoggedSet(
          id: '${pe.id}_set_${index + 1}',
          exerciseId: pe.exerciseId,
          exerciseName: pe.exerciseName,
          setNumber: index + 1,
          weightKg: pe.targetWeightKg,
          reps: pe.targetReps,
          isCompleted: false,
        ),
      );
    }
  }

  void updateActiveSet({
    required String plannedExerciseId,
    required int setIndex,
    double? weightKg,
    int? reps,
    bool? isCompleted,
  }) {
    final list = _activeSetsByExercise[plannedExerciseId];
    if (list == null || setIndex < 0 || setIndex >= list.length) return;
    list[setIndex] = list[setIndex].copyWith(
      weightKg: weightKg,
      reps: reps,
      isCompleted: isCompleted,
    );
    notifyListeners();
  }

  void addExtraSetToActiveExercise(PlannedExercise pe) {
    final list = _activeSetsByExercise.putIfAbsent(pe.id, () => []);
    final last = list.isNotEmpty ? list.last : null;
    list.add(
      LoggedSet(
        id: '${pe.id}_set_${list.length + 1}_${DateTime.now().millisecondsSinceEpoch}',
        exerciseId: pe.exerciseId,
        exerciseName: pe.exerciseName,
        setNumber: list.length + 1,
        weightKg: last?.weightKg ?? pe.targetWeightKg,
        reps: last?.reps ?? pe.targetReps,
        isCompleted: false,
      ),
    );
    notifyListeners();
  }

  /// Load user's cloud plans & sessions from Supabase when authenticated
  Future<void> syncFromSupabase(AuthSession? session) async {
    _attachedSession = session;
    if (session == null ||
        !session.isSupabaseConnected ||
        session.userId == null) {
      return;
    }
    if (_loadedSupabaseUserId == session.userId) return;
    _loadedSupabaseUserId = session.userId;

    _isSyncing = true;
    notifyListeners();

    try {
      final remotePlans = await _repository.fetchPlansFromSupabase(session);
      if (remotePlans.isNotEmpty) {
        _plans = remotePlans;
        _activePlanId = _plans.first.id;
        await _repository.savePlans(_plans);
        await _repository.saveActivePlanId(_activePlanId);
        _prepareActiveSetsForDay(selectedWorkoutDay);
      } else {
        // Upload starter plan so Web & Android stay synced immediately
        await _repository.savePlanToSupabase(
          session: session,
          plan: activePlan,
          isActive: true,
        );
      }

      final remoteLogs = await _repository.fetchSessionsFromSupabase(session);
      if (remoteLogs.isNotEmpty) {
        _logs = remoteLogs;
        await _repository.saveLogs(_logs);
      }
    } catch (_) {
      // Keep local cache if offline
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<WorkoutSessionLog?> finishAndSaveSession({
    AuthSession? authSession,
  }) async {
    final day = selectedWorkoutDay;
    if (day == null) return null;

    final allSets = _activeSetsByExercise.values.expand((e) => e).toList();
    final completed = allSets.where((s) => s.isCompleted).toList();
    if (completed.isEmpty) return null;

    final duration = _sessionStartedAt == null
        ? 45
        : DateTime.now()
            .difference(_sessionStartedAt!)
            .inMinutes
            .clamp(1, 240);

    var newLog = WorkoutSessionLog(
      id: 'log_${DateTime.now().millisecondsSinceEpoch}',
      dayName: day.name,
      date: DateTime.now(),
      durationMinutes: duration,
      sets: completed,
    );

    final effectiveSession = authSession ?? _attachedSession;
    if (effectiveSession != null &&
        !effectiveSession.isDemo &&
        effectiveSession.hasToken) {
      _isSyncing = true;
      notifyListeners();

      bool synced = false;
      if (effectiveSession.isSupabaseConnected) {
        synced = await _repository.saveSessionToSupabase(
          session: effectiveSession,
          log: newLog,
        );
      } else {
        synced = await _repository.syncSessionToWger(
          session: effectiveSession,
          log: newLog,
        );
      }

      if (synced) {
        newLog = WorkoutSessionLog(
          id: newLog.id,
          dayName: newLog.dayName,
          date: newLog.date,
          durationMinutes: newLog.durationMinutes,
          sets: newLog.sets,
          isSyncedWithWger: true,
        );
      }
      _isSyncing = false;
    }

    _logs = [newLog, ..._logs];
    await _repository.saveLogs(_logs);
    _prepareActiveSetsForDay(day);
    notifyListeners();
    return newLog;
  }

  // --- Workout Split Planner Management ---

  Future<void> setActivePlan(String planId) async {
    _activePlanId = planId;
    await _repository.saveActivePlanId(planId);
    _prepareActiveSetsForDay(selectedWorkoutDay);
    notifyListeners();
  }

  Future<void> createNewPlan({
    required String name,
    String description = '',
    AuthSession? authSession,
  }) async {
    final newPlan = WorkoutPlan(
      id: 'plan_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      description: description.trim(),
      updatedAt: DateTime.now(),
      days: List.generate(
        7,
        (i) => WorkoutDay(
          id: 'day_${DateTime.now().millisecondsSinceEpoch}_${i + 1}',
          name: i == 6 ? 'Rest Day' : 'Workout Day ${i + 1}',
          weekday: i + 1,
          isRestDay: i == 6,
        ),
      ),
    );

    _plans = [..._plans, newPlan];
    _activePlanId = newPlan.id;
    await _repository.savePlans(_plans);
    await _repository.saveActivePlanId(_activePlanId);
    _prepareActiveSetsForDay(selectedWorkoutDay);
    notifyListeners();

    if (authSession != null && !authSession.isDemo && authSession.hasToken) {
      await syncActivePlanToWger(authSession);
    }
  }

  Future<void> updateDayInfo({
    required int weekday,
    required String name,
    required bool isRestDay,
  }) async {
    final updatedDays = activePlan.days.map((d) {
      if (d.weekday != weekday) return d;
      return d.copyWith(name: name.trim(), isRestDay: isRestDay);
    }).toList();

    await _replaceActivePlan(
      activePlan.copyWith(days: updatedDays, updatedAt: DateTime.now()),
    );
  }

  Future<void> addExerciseToDay({
    required int weekday,
    required ExerciseModel exercise,
    int targetSets = 3,
    int targetReps = 10,
    double targetWeightKg = 20,
    int restSeconds = 90,
  }) async {
    final planned = PlannedExercise(
      id: 'pe_${DateTime.now().millisecondsSinceEpoch}',
      exerciseId: exercise.id,
      exerciseName: exercise.name,
      categoryName: exercise.category.name,
      imageUrl: exercise.mainImageUrl,
      targetSets: targetSets,
      targetReps: targetReps,
      targetWeightKg: targetWeightKg,
      restSeconds: restSeconds,
    );

    final updatedDays = activePlan.days.map((d) {
      if (d.weekday != weekday) return d;
      return d.copyWith(
        isRestDay: false,
        exercises: [...d.exercises, planned],
      );
    }).toList();

    await _replaceActivePlan(
      activePlan.copyWith(days: updatedDays, updatedAt: DateTime.now()),
    );
  }

  Future<void> updatePlannedExercise({
    required int weekday,
    required PlannedExercise updated,
  }) async {
    final updatedDays = activePlan.days.map((d) {
      if (d.weekday != weekday) return d;
      return d.copyWith(
        exercises: d.exercises
            .map((e) => e.id == updated.id ? updated : e)
            .toList(),
      );
    }).toList();

    await _replaceActivePlan(
      activePlan.copyWith(days: updatedDays, updatedAt: DateTime.now()),
    );
  }

  Future<void> removeExerciseFromDay({
    required int weekday,
    required String plannedExerciseId,
  }) async {
    final updatedDays = activePlan.days.map((d) {
      if (d.weekday != weekday) return d;
      return d.copyWith(
        exercises: d.exercises.where((e) => e.id != plannedExerciseId).toList(),
      );
    }).toList();

    await _replaceActivePlan(
      activePlan.copyWith(days: updatedDays, updatedAt: DateTime.now()),
    );
  }

  Future<bool> syncActivePlanToWger(AuthSession session) async {
    if (session.isDemo || !session.hasToken) {
      _syncMessage = 'Mode Demo: jadwal tersimpan di perangkat lokal.';
      notifyListeners();
      return false;
    }

    _isSyncing = true;
    _syncMessage = null;
    notifyListeners();

    if (session.isSupabaseConnected) {
      final ok = await _repository.savePlanToSupabase(
        session: session,
        plan: activePlan,
        isActive: true,
      );
      _isSyncing = false;
      if (ok) {
        await _replaceActivePlan(activePlan.copyWith(isSyncedWithWger: true));
        _syncMessage = 'Jadwal Split berhasil disinkronkan ke Supabase PostgreSQL!';
      } else {
        _syncMessage =
            'Jadwal tersimpan lokal. Gagal sinkronisasi ke Supabase (periksa koneksi).';
      }
      notifyListeners();
      return ok;
    }

    final routineId = await _repository.syncPlanToWger(
      session: session,
      plan: activePlan,
    );

    _isSyncing = false;
    if (routineId != null) {
      await _replaceActivePlan(
        activePlan.copyWith(
          wgerRoutineId: routineId,
          isSyncedWithWger: true,
        ),
      );
      _syncMessage = 'Jadwal berhasil disinkronkan ke akun Wger (#$routineId).';
      notifyListeners();
      return true;
    } else {
      _syncMessage =
          'Jadwal tersimpan lokal. Sinkronisasi Wger dilewati (periksa token/koneksi).';
      notifyListeners();
      return false;
    }
  }

  Future<void> _replaceActivePlan(WorkoutPlan updated) async {
    _plans = _plans.map((p) => p.id == updated.id ? updated : p).toList();
    await _repository.savePlans(_plans);
    _prepareActiveSetsForDay(selectedWorkoutDay);
    notifyListeners();

    final session = _attachedSession;
    if (session != null && session.isSupabaseConnected && session.hasToken) {
      await _repository.savePlanToSupabase(
        session: session,
        plan: updated,
        isActive: updated.id == _activePlanId,
      );
    }
  }

  // --- Progress & Analytics Helpers ---

  List<String> get trackedExerciseNames {
    final names = <String>{};
    for (final log in _logs) {
      for (final s in log.sets) {
        if (s.isCompleted) names.add(s.exerciseName);
      }
    }
    final sorted = names.toList()..sort();
    return sorted;
  }

  double get totalLifetimeVolume =>
      _logs.fold(0.0, (sum, log) => sum + log.totalVolume);

  int get totalCompletedSets =>
      _logs.fold(0, (sum, log) => sum + log.completedSetsCount);

  double get highestWeightLifted {
    double best = 0;
    for (final log in _logs) {
      for (final s in log.sets) {
        if (s.isCompleted && s.weightKg > best) best = s.weightKg;
      }
    }
    return best;
  }

  List<({DateTime date, double value})> volumeSeries() {
    final sorted = [..._logs]..sort((a, b) => a.date.compareTo(b.date));
    return sorted
        .map((l) => (date: l.date, value: l.totalVolume))
        .toList();
  }

  List<({DateTime date, double value})> exerciseMaxWeightSeries(
    String exerciseName,
  ) {
    final sorted = [..._logs]..sort((a, b) => a.date.compareTo(b.date));
    final points = <({DateTime date, double value})>[];
    for (final log in sorted) {
      final maxW = log.maxWeightForExercise(exerciseName);
      if (maxW > 0) {
        points.add((date: log.date, value: maxW));
      }
    }
    return points;
  }
}
