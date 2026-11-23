import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_constants.dart';
import '../models/user_model.dart';
import '../models/workout_log_model.dart';
import '../models/workout_plan_model.dart';

class LocalStorageService {
  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  // --- Auth Session ---
  Future<void> saveAuthSession(AuthSession session) async {
    await _prefs.setString(
      ApiConstants.keyAuthSession,
      jsonEncode(session.toJson()),
    );
  }

  AuthSession? loadAuthSession() {
    final raw = _prefs.getString(ApiConstants.keyAuthSession);
    if (raw == null || raw.isEmpty) return null;
    try {
      return AuthSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearAuthSession() async {
    await _prefs.remove(ApiConstants.keyAuthSession);
  }

  // --- Workout Plans ---
  Future<void> saveWorkoutPlans(List<WorkoutPlan> plans) async {
    final encoded = jsonEncode(plans.map((p) => p.toJson()).toList());
    await _prefs.setString(ApiConstants.keyWorkoutPlans, encoded);
  }

  List<WorkoutPlan> loadWorkoutPlans() {
    final raw = _prefs.getString(ApiConstants.keyWorkoutPlans);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .whereType<Map<String, dynamic>>()
          .map(WorkoutPlan.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveActivePlanId(String planId) async {
    await _prefs.setString(ApiConstants.keyActivePlanId, planId);
  }

  String? loadActivePlanId() {
    return _prefs.getString(ApiConstants.keyActivePlanId);
  }

  // --- Workout Logs ---
  Future<void> saveWorkoutLogs(List<WorkoutSessionLog> logs) async {
    final encoded = jsonEncode(logs.map((l) => l.toJson()).toList());
    await _prefs.setString(ApiConstants.keyWorkoutLogs, encoded);
  }

  List<WorkoutSessionLog> loadWorkoutLogs() {
    final raw = _prefs.getString(ApiConstants.keyWorkoutLogs);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .whereType<Map<String, dynamic>>()
          .map(WorkoutSessionLog.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  // --- Theme Mode ---
  Future<void> saveIsDarkMode(bool isDark) async {
    await _prefs.setBool(ApiConstants.keyThemeMode, isDark);
  }

  bool loadIsDarkMode() {
    return _prefs.getBool(ApiConstants.keyThemeMode) ?? false;
  }
}
