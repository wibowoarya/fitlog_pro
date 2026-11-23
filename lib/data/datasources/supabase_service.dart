import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../models/user_model.dart';
import '../models/workout_log_model.dart';
import '../models/workout_plan_model.dart';

class SupabaseException implements Exception {
  final String message;
  const SupabaseException(this.message);

  @override
  String toString() => message;
}

class SupabaseService {
  final http.Client _client;

  SupabaseService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> _headers({String? accessToken, bool upsert = false}) {
    return {
      'apikey': ApiConstants.supabasePublishableKey,
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken'
      else
        'Authorization': 'Bearer ${ApiConstants.supabasePublishableKey}',
      if (upsert) 'Prefer': 'resolution=merge-duplicates,return=representation',
    };
  }

  /// Register a new user via Supabase Auth (/auth/v1/signup)
  Future<AuthSession> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    final res = await _client
        .post(
          Uri.parse('${ApiConstants.supabaseAuthBase}/signup'),
          headers: _headers(),
          body: jsonEncode({
            'email': email.trim(),
            'password': password,
            'data': {'username': username.trim()},
          }),
        )
        .timeout(const Duration(seconds: 12));

    final body = _safeDecode(res.body);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final accessToken = body['access_token']?.toString();
      final refreshToken = body['refresh_token']?.toString();
      final userMap = (body['user'] as Map<String, dynamic>?) ?? body;
      final userId = userMap['id']?.toString();

      if (accessToken == null || accessToken.isEmpty) {
        throw const SupabaseException(
          'Akun berhasil dibuat! Silakan cek email untuk konfirmasi, atau matikan "Confirm email" di Supabase Authentication → Providers → Email agar bisa langsung login.',
        );
      }

      final session = AuthSession(
        userId: userId,
        username: username.trim().isEmpty
            ? email.trim().split('@').first
            : username.trim(),
        email: email.trim(),
        accessToken: accessToken,
        refreshToken: refreshToken,
        authScheme: 'Bearer',
        isDemo: false,
        isSupabaseConnected: true,
        loggedInAt: DateTime.now(),
      );

      await _upsertProfile(session);
      return session;
    }

    final errMsg =
        (body['msg'] ?? body['error_description'] ?? body['message'] ?? '')
            .toString();
    throw SupabaseException(
      errMsg.isNotEmpty
          ? 'Gagal daftar akun: $errMsg'
          : 'Gagal mendaftar ke Supabase (${res.statusCode}).',
    );
  }

  /// Sign in via Supabase Auth (/auth/v1/token?grant_type=password)
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    final res = await _client
        .post(
          Uri.parse(
            '${ApiConstants.supabaseAuthBase}/token?grant_type=password',
          ),
          headers: _headers(),
          body: jsonEncode({
            'email': email.trim(),
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 12));

    final body = _safeDecode(res.body);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final accessToken = body['access_token']?.toString();
      final refreshToken = body['refresh_token']?.toString();
      final userMap = body['user'] as Map<String, dynamic>? ?? {};
      final userId = userMap['id']?.toString();
      final meta = userMap['user_metadata'] as Map<String, dynamic>? ?? {};
      final username =
          (meta['username'] ?? email.trim().split('@').first).toString();

      final session = AuthSession(
        userId: userId,
        username: username,
        email: email.trim(),
        accessToken: accessToken,
        refreshToken: refreshToken,
        authScheme: 'Bearer',
        isDemo: false,
        isSupabaseConnected: true,
        loggedInAt: DateTime.now(),
      );

      await _upsertProfile(session);
      return session;
    }

    final errMsg =
        (body['error_description'] ?? body['msg'] ?? body['message'] ?? '')
            .toString();
    throw SupabaseException(
      errMsg.isNotEmpty
          ? errMsg
          : 'Email atau password tidak ditemukan di Supabase.',
    );
  }

  Future<void> _upsertProfile(AuthSession session) async {
    if (session.userId == null || !session.hasToken) return;
    try {
      await _client
          .post(
            Uri.parse('${ApiConstants.supabaseRestBase}/profiles'),
            headers: _headers(accessToken: session.accessToken, upsert: true),
            body: jsonEncode({
              'id': session.userId,
              'username': session.username,
              'email': session.email ?? '',
            }),
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {}
  }

  /// Load user's workout plans from Supabase PostgreSQL
  Future<List<WorkoutPlan>> fetchWorkoutPlans(AuthSession session) async {
    if (!session.isSupabaseConnected ||
        session.userId == null ||
        !session.hasToken) {
      return [];
    }

    final uri = Uri.parse('${ApiConstants.supabaseRestBase}/workout_plans')
        .replace(
      queryParameters: {
        'user_id': 'eq.${session.userId}',
        'order': 'updated_at.desc',
      },
    );

    final res = await _client
        .get(uri, headers: _headers(accessToken: session.accessToken))
        .timeout(const Duration(seconds: 10));

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final list = jsonDecode(res.body) as List;
      return list.whereType<Map<String, dynamic>>().map((row) {
        final daysRaw = row['days'] as List? ?? [];
        return WorkoutPlan(
          id: row['id'].toString(),
          name: (row['name'] ?? 'My Workout Split').toString(),
          description: (row['description'] ?? '').toString(),
          days: daysRaw
              .whereType<Map<String, dynamic>>()
              .map(WorkoutDay.fromJson)
              .toList(),
          updatedAt:
              DateTime.tryParse(row['updated_at']?.toString() ?? '') ??
                  DateTime.now(),
          isSyncedWithWger: true,
        );
      }).toList();
    }
    return [];
  }

  /// Upsert a workout plan to Supabase PostgreSQL
  Future<bool> upsertWorkoutPlan({
    required AuthSession session,
    required WorkoutPlan plan,
    required bool isActive,
  }) async {
    if (!session.isSupabaseConnected ||
        session.userId == null ||
        !session.hasToken) {
      return false;
    }

    try {
      final res = await _client
          .post(
            Uri.parse('${ApiConstants.supabaseRestBase}/workout_plans'),
            headers: _headers(accessToken: session.accessToken, upsert: true),
            body: jsonEncode({
              'id': '${session.userId}_${plan.id}',
              'user_id': session.userId,
              'name': plan.name,
              'description': plan.description,
              'days': plan.days.map((d) => d.toJson()).toList(),
              'is_active': isActive,
              'updated_at': plan.updatedAt.toUtc().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 10));
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  /// Load user's workout sessions from Supabase PostgreSQL
  Future<List<WorkoutSessionLog>> fetchWorkoutSessions(
    AuthSession session,
  ) async {
    if (!session.isSupabaseConnected ||
        session.userId == null ||
        !session.hasToken) {
      return [];
    }

    final uri = Uri.parse('${ApiConstants.supabaseRestBase}/workout_sessions')
        .replace(
      queryParameters: {
        'user_id': 'eq.${session.userId}',
        'order': 'session_date.desc',
      },
    );

    final res = await _client
        .get(uri, headers: _headers(accessToken: session.accessToken))
        .timeout(const Duration(seconds: 10));

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final list = jsonDecode(res.body) as List;
      return list.whereType<Map<String, dynamic>>().map((row) {
        final setsRaw = row['sets'] as List? ?? [];
        return WorkoutSessionLog(
          id: row['id'].toString(),
          dayName: (row['day_name'] ?? 'Workout Session').toString(),
          date: DateTime.tryParse(row['session_date']?.toString() ?? '') ??
              DateTime.now(),
          durationMinutes: (row['duration_minutes'] as num?)?.toInt() ?? 45,
          sets: setsRaw
              .whereType<Map<String, dynamic>>()
              .map(LoggedSet.fromJson)
              .toList(),
          isSyncedWithWger: true,
        );
      }).toList();
    }
    return [];
  }

  /// Save a completed workout session to Supabase PostgreSQL
  Future<bool> saveWorkoutSession({
    required AuthSession session,
    required WorkoutSessionLog log,
  }) async {
    if (!session.isSupabaseConnected ||
        session.userId == null ||
        !session.hasToken) {
      return false;
    }

    try {
      final res = await _client
          .post(
            Uri.parse('${ApiConstants.supabaseRestBase}/workout_sessions'),
            headers: _headers(accessToken: session.accessToken, upsert: true),
            body: jsonEncode({
              'id': '${session.userId}_${log.id}',
              'user_id': session.userId,
              'day_name': log.dayName,
              'session_date': log.date.toUtc().toIso8601String(),
              'duration_minutes': log.durationMinutes,
              'total_volume': log.totalVolume,
              'sets': log.sets.map((s) => s.toJson()).toList(),
            }),
          )
          .timeout(const Duration(seconds: 10));
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic> _safeDecode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return {};
  }
}
