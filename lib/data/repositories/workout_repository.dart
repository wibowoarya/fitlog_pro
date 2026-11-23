import '../datasources/local_storage_service.dart';
import '../datasources/supabase_service.dart';
import '../datasources/wger_api_service.dart';
import '../models/user_model.dart';
import '../models/workout_log_model.dart';
import '../models/workout_plan_model.dart';

class WorkoutRepository {
  final LocalStorageService _storage;
  final WgerApiService _apiService;
  final SupabaseService _supabaseService;

  WorkoutRepository({
    required LocalStorageService storage,
    required WgerApiService apiService,
    required SupabaseService supabaseService,
  })  : _storage = storage,
        _apiService = apiService,
        _supabaseService = supabaseService;

  List<WorkoutPlan> loadPlans() {
    final stored = _storage.loadWorkoutPlans();
    if (stored.isNotEmpty) return stored;
    final defaultPlans = [_buildDefaultPplPlan()];
    _storage.saveWorkoutPlans(defaultPlans);
    return defaultPlans;
  }

  Future<void> savePlans(List<WorkoutPlan> plans) async {
    await _storage.saveWorkoutPlans(plans);
  }

  String? loadActivePlanId() => _storage.loadActivePlanId();

  Future<void> saveActivePlanId(String id) async {
    await _storage.saveActivePlanId(id);
  }

  List<WorkoutSessionLog> loadLogs() {
    final stored = _storage.loadWorkoutLogs();
    if (stored.isNotEmpty) return stored;
    final seeded = _buildSeededLogs();
    _storage.saveWorkoutLogs(seeded);
    return seeded;
  }

  Future<void> saveLogs(List<WorkoutSessionLog> logs) async {
    await _storage.saveWorkoutLogs(logs);
  }

  Future<List<WorkoutPlan>> fetchPlansFromSupabase(AuthSession session) {
    return _supabaseService.fetchWorkoutPlans(session);
  }

  Future<bool> savePlanToSupabase({
    required AuthSession session,
    required WorkoutPlan plan,
    required bool isActive,
  }) {
    return _supabaseService.upsertWorkoutPlan(
      session: session,
      plan: plan,
      isActive: isActive,
    );
  }

  Future<List<WorkoutSessionLog>> fetchSessionsFromSupabase(
    AuthSession session,
  ) {
    return _supabaseService.fetchWorkoutSessions(session);
  }

  Future<bool> saveSessionToSupabase({
    required AuthSession session,
    required WorkoutSessionLog log,
  }) {
    return _supabaseService.saveWorkoutSession(session: session, log: log);
  }

  Future<int?> syncPlanToWger({
    required AuthSession session,
    required WorkoutPlan plan,
  }) {
    return _apiService.createWgerRoutine(
      session: session,
      name: plan.name,
      description: plan.description.isEmpty
          ? 'Workout split dibuat dengan FitLog Pro'
          : plan.description,
    );
  }

  Future<bool> syncSessionToWger({
    required AuthSession session,
    required WorkoutSessionLog log,
  }) async {
    if (session.isDemo || !session.hasToken) return false;
    bool anySynced = false;
    for (final set in log.sets.where((s) => s.isCompleted)) {
      final ok = await _apiService.syncWorkoutLog(
        session: session,
        exerciseId: set.exerciseId,
        weightKg: set.weightKg,
        reps: set.reps,
        date: log.date,
      );
      if (ok) anySynced = true;
    }
    return anySynced;
  }

  WorkoutPlan _buildDefaultPplPlan() {
    return WorkoutPlan(
      id: 'plan_ppl_default',
      name: 'Push / Pull / Legs (Pro Split)',
      description: 'Jadwal hipertrofi 5 hari/minggu seimbang untuk massa otot & kekuatan.',
      updatedAt: DateTime.now(),
      days: const [
        WorkoutDay(
          id: 'day_mon',
          name: 'Push Day (Chest, Shoulders, Triceps)',
          weekday: 1,
          exercises: [
            PlannedExercise(
              id: 'pe_1',
              exerciseId: 192,
              exerciseName: 'Barbell Bench Press',
              categoryName: 'Chest',
              targetSets: 4,
              targetReps: 8,
              targetWeightKg: 60,
              restSeconds: 120,
            ),
            PlannedExercise(
              id: 'pe_2',
              exerciseId: 163,
              exerciseName: 'Incline Dumbbell Press',
              categoryName: 'Chest',
              targetSets: 3,
              targetReps: 10,
              targetWeightKg: 22.5,
              restSeconds: 90,
            ),
            PlannedExercise(
              id: 'pe_3',
              exerciseId: 119,
              exerciseName: 'Overhead Shoulder Press',
              categoryName: 'Shoulders',
              targetSets: 3,
              targetReps: 10,
              targetWeightKg: 35,
              restSeconds: 90,
            ),
            PlannedExercise(
              id: 'pe_4',
              exerciseId: 89,
              exerciseName: 'Cable Triceps Pushdown',
              categoryName: 'Arms',
              targetSets: 3,
              targetReps: 12,
              targetWeightKg: 25,
              restSeconds: 60,
            ),
          ],
        ),
        WorkoutDay(
          id: 'day_tue',
          name: 'Pull Day (Back & Biceps)',
          weekday: 2,
          exercises: [
            PlannedExercise(
              id: 'pe_5',
              exerciseId: 107,
              exerciseName: 'Pull-Ups',
              categoryName: 'Back',
              targetSets: 4,
              targetReps: 8,
              targetWeightKg: 0,
              restSeconds: 90,
            ),
            PlannedExercise(
              id: 'pe_6',
              exerciseId: 109,
              exerciseName: 'Barbell Bent-Over Row',
              categoryName: 'Back',
              targetSets: 4,
              targetReps: 10,
              targetWeightKg: 55,
              restSeconds: 90,
            ),
            PlannedExercise(
              id: 'pe_7',
              exerciseId: 74,
              exerciseName: 'Barbell Bicep Curl',
              categoryName: 'Arms',
              targetSets: 3,
              targetReps: 12,
              targetWeightKg: 25,
              restSeconds: 60,
            ),
          ],
        ),
        WorkoutDay(
          id: 'day_wed',
          name: 'Active Recovery / Rest Day',
          weekday: 3,
          isRestDay: true,
        ),
        WorkoutDay(
          id: 'day_thu',
          name: 'Leg Day (Quads, Hamstrings, Abs)',
          weekday: 4,
          exercises: [
            PlannedExercise(
              id: 'pe_8',
              exerciseId: 111,
              exerciseName: 'Barbell Back Squat',
              categoryName: 'Legs',
              targetSets: 4,
              targetReps: 8,
              targetWeightKg: 80,
              restSeconds: 120,
            ),
            PlannedExercise(
              id: 'pe_9',
              exerciseId: 105,
              exerciseName: 'Romanian Deadlift (RDL)',
              categoryName: 'Legs',
              targetSets: 3,
              targetReps: 10,
              targetWeightKg: 65,
              restSeconds: 90,
            ),
            PlannedExercise(
              id: 'pe_10',
              exerciseId: 91,
              exerciseName: 'Hanging Leg Raises',
              categoryName: 'Abs',
              targetSets: 3,
              targetReps: 15,
              targetWeightKg: 0,
              restSeconds: 60,
            ),
          ],
        ),
        WorkoutDay(
          id: 'day_fri',
          name: 'Upper Body Power',
          weekday: 5,
          exercises: [
            PlannedExercise(
              id: 'pe_11',
              exerciseId: 192,
              exerciseName: 'Barbell Bench Press',
              categoryName: 'Chest',
              targetSets: 3,
              targetReps: 6,
              targetWeightKg: 65,
              restSeconds: 120,
            ),
            PlannedExercise(
              id: 'pe_12',
              exerciseId: 109,
              exerciseName: 'Barbell Bent-Over Row',
              categoryName: 'Back',
              targetSets: 3,
              targetReps: 8,
              targetWeightKg: 60,
              restSeconds: 90,
            ),
            PlannedExercise(
              id: 'pe_13',
              exerciseId: 148,
              exerciseName: 'Dumbbell Lateral Raises',
              categoryName: 'Shoulders',
              targetSets: 4,
              targetReps: 15,
              targetWeightKg: 10,
              restSeconds: 60,
            ),
          ],
        ),
        WorkoutDay(
          id: 'day_sat',
          name: 'Full Body Conditioning',
          weekday: 6,
          exercises: [
            PlannedExercise(
              id: 'pe_14',
              exerciseId: 111,
              exerciseName: 'Barbell Back Squat',
              categoryName: 'Legs',
              targetSets: 3,
              targetReps: 10,
              targetWeightKg: 70,
              restSeconds: 90,
            ),
            PlannedExercise(
              id: 'pe_15',
              exerciseId: 119,
              exerciseName: 'Overhead Shoulder Press',
              categoryName: 'Shoulders',
              targetSets: 3,
              targetReps: 10,
              targetWeightKg: 32.5,
              restSeconds: 90,
            ),
          ],
        ),
        WorkoutDay(
          id: 'day_sun',
          name: 'Rest & Mobility',
          weekday: 7,
          isRestDay: true,
        ),
      ],
    );
  }

  List<WorkoutSessionLog> _buildSeededLogs() {
    final now = DateTime.now();
    return [
      WorkoutSessionLog(
        id: 'log_seed_1',
        dayName: 'Push Day (Chest, Shoulders, Triceps)',
        date: now.subtract(const Duration(days: 14)),
        durationMinutes: 52,
        sets: const [
          LoggedSet(id: 's1', exerciseId: 192, exerciseName: 'Barbell Bench Press', setNumber: 1, weightKg: 52.5, reps: 8, isCompleted: true),
          LoggedSet(id: 's2', exerciseId: 192, exerciseName: 'Barbell Bench Press', setNumber: 2, weightKg: 55, reps: 8, isCompleted: true),
          LoggedSet(id: 's3', exerciseId: 192, exerciseName: 'Barbell Bench Press', setNumber: 3, weightKg: 55, reps: 8, isCompleted: true),
          LoggedSet(id: 's4', exerciseId: 119, exerciseName: 'Overhead Shoulder Press', setNumber: 1, weightKg: 30, reps: 10, isCompleted: true),
          LoggedSet(id: 's5', exerciseId: 119, exerciseName: 'Overhead Shoulder Press', setNumber: 2, weightKg: 30, reps: 10, isCompleted: true),
        ],
      ),
      WorkoutSessionLog(
        id: 'log_seed_2',
        dayName: 'Leg Day (Quads, Hamstrings, Abs)',
        date: now.subtract(const Duration(days: 10)),
        durationMinutes: 58,
        sets: const [
          LoggedSet(id: 's6', exerciseId: 111, exerciseName: 'Barbell Back Squat', setNumber: 1, weightKg: 70, reps: 8, isCompleted: true),
          LoggedSet(id: 's7', exerciseId: 111, exerciseName: 'Barbell Back Squat', setNumber: 2, weightKg: 75, reps: 8, isCompleted: true),
          LoggedSet(id: 's8', exerciseId: 111, exerciseName: 'Barbell Back Squat', setNumber: 3, weightKg: 75, reps: 8, isCompleted: true),
          LoggedSet(id: 's9', exerciseId: 105, exerciseName: 'Romanian Deadlift (RDL)', setNumber: 1, weightKg: 60, reps: 10, isCompleted: true),
          LoggedSet(id: 's10', exerciseId: 105, exerciseName: 'Romanian Deadlift (RDL)', setNumber: 2, weightKg: 60, reps: 10, isCompleted: true),
        ],
      ),
      WorkoutSessionLog(
        id: 'log_seed_3',
        dayName: 'Push Day (Chest, Shoulders, Triceps)',
        date: now.subtract(const Duration(days: 6)),
        durationMinutes: 55,
        sets: const [
          LoggedSet(id: 's11', exerciseId: 192, exerciseName: 'Barbell Bench Press', setNumber: 1, weightKg: 57.5, reps: 8, isCompleted: true),
          LoggedSet(id: 's12', exerciseId: 192, exerciseName: 'Barbell Bench Press', setNumber: 2, weightKg: 60, reps: 8, isCompleted: true),
          LoggedSet(id: 's13', exerciseId: 192, exerciseName: 'Barbell Bench Press', setNumber: 3, weightKg: 60, reps: 8, isCompleted: true),
          LoggedSet(id: 's14', exerciseId: 119, exerciseName: 'Overhead Shoulder Press', setNumber: 1, weightKg: 32.5, reps: 10, isCompleted: true),
          LoggedSet(id: 's15', exerciseId: 119, exerciseName: 'Overhead Shoulder Press', setNumber: 2, weightKg: 35, reps: 9, isCompleted: true),
        ],
      ),
      WorkoutSessionLog(
        id: 'log_seed_4',
        dayName: 'Leg Day (Quads, Hamstrings, Abs)',
        date: now.subtract(const Duration(days: 2)),
        durationMinutes: 61,
        sets: const [
          LoggedSet(id: 's16', exerciseId: 111, exerciseName: 'Barbell Back Squat', setNumber: 1, weightKg: 77.5, reps: 8, isCompleted: true),
          LoggedSet(id: 's17', exerciseId: 111, exerciseName: 'Barbell Back Squat', setNumber: 2, weightKg: 80, reps: 8, isCompleted: true),
          LoggedSet(id: 's18', exerciseId: 111, exerciseName: 'Barbell Back Squat', setNumber: 3, weightKg: 82.5, reps: 8, isCompleted: true),
          LoggedSet(id: 's19', exerciseId: 105, exerciseName: 'Romanian Deadlift (RDL)', setNumber: 1, weightKg: 65, reps: 10, isCompleted: true),
          LoggedSet(id: 's20', exerciseId: 105, exerciseName: 'Romanian Deadlift (RDL)', setNumber: 2, weightKg: 67.5, reps: 10, isCompleted: true),
        ],
      ),
    ];
  }
}
