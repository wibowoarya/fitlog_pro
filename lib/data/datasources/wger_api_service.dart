import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../models/exercise_model.dart';
import '../models/user_model.dart';

class WgerApiException implements Exception {
  final String message;
  final int? statusCode;

  const WgerApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class WgerApiService {
  final http.Client _client;

  WgerApiService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> _headers({String? authHeader}) {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (authHeader != null && authHeader.isNotEmpty)
        'Authorization': authHeader,
    };
  }

  /// Decode JWT payload without external packages.
  Map<String, dynamic>? _decodeJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final map = jsonDecode(decoded);
      if (map is Map<String, dynamic>) return map;
    } catch (_) {}
    return null;
  }

  /// Login using Wger username/email & password.
  /// Tries Allauth Headless first, then falls back to legacy /api/v2/token/.
  Future<AuthSession> loginWithCredentials({
    required String identifier,
    required String password,
  }) async {
    final trimmed = identifier.trim();
    final isEmail = trimmed.contains('@');

    // 0. Cek akun default aplikasi (admin@gmail.com / password123) -> langsung pakai JWT Wger
    if (trimmed.toLowerCase() == ApiConstants.defaultEmail &&
        password == ApiConstants.defaultPassword) {
      String accessToken = ApiConstants.wgerJwtToken;
      final exchanged = await _exchangeRefreshToken(ApiConstants.wgerJwtToken);
      if (exchanged != null && exchanged.isNotEmpty) {
        accessToken = exchanged;
      }

      return AuthSession(
        username: 'Admin FitLog',
        email: ApiConstants.defaultEmail,
        accessToken: accessToken,
        refreshToken: ApiConstants.wgerJwtToken,
        authScheme: 'Bearer',
        isDemo: false,
        loggedInAt: DateTime.now(),
      );
    }

    // 1. Try Wger Allauth Headless login
    try {
      final body = isEmail
          ? {'email': trimmed, 'password': password}
          : {'username': trimmed, 'password': password};

      final response = await _client
          .post(
            Uri.parse(ApiConstants.allauthLogin),
            headers: _headers(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final meta = data['meta'] as Map<String, dynamic>? ?? {};
        final userData =
            (data['data'] as Map<String, dynamic>?)?['user']
                as Map<String, dynamic>? ??
            {};
        final accessToken =
            (meta['access_token'] ?? meta['session_token'] ?? '').toString();
        final refreshToken = (meta['refresh_token'] ?? '').toString();

        return AuthSession(
          username: (userData['username'] ?? trimmed).toString(),
          email: userData['email']?.toString(),
          accessToken: accessToken.isNotEmpty ? accessToken : null,
          refreshToken: refreshToken.isNotEmpty ? refreshToken : null,
          authScheme: 'Bearer',
          isDemo: false,
          loggedInAt: DateTime.now(),
        );
      }
    } catch (_) {
      // Fallback to legacy endpoint below
    }

    // 2. Fallback: Legacy JWT /api/v2/token/
    try {
      final response = await _client
          .post(
            Uri.parse(ApiConstants.legacyTokenLogin),
            headers: _headers(),
            body: jsonEncode({'username': trimmed, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return AuthSession(
          username: trimmed,
          email: isEmail ? trimmed : null,
          accessToken: data['access']?.toString(),
          refreshToken: data['refresh']?.toString(),
          authScheme: 'Bearer',
          isDemo: false,
          loggedInAt: DateTime.now(),
        );
      }
    } catch (_) {
      // Fallback to configured Wger JWT token below
    }

    throw const WgerApiException(
      'Email atau password salah. Gunakan admin@gmail.com / password123 atau akun Wger asli Anda.',
    );
  }

  /// Login using a Wger JWT Refresh Token, JWT Access Token, or Wger API Key.
  Future<AuthSession> loginWithToken(String rawToken) async {
    final token = rawToken.trim();
    if (token.isEmpty) {
      throw const WgerApiException('Token tidak boleh kosong.');
    }

    final jwtPayload = _decodeJwtPayload(token);

    // Case A: JWT Token (Allauth / SimpleJWT)
    if (jwtPayload != null) {
      final tokenUse = (jwtPayload['token_use'] ?? '').toString();
      final sub = (jwtPayload['sub'] ?? 'WgerUser').toString();
      String accessToken = token;
      String? refreshToken;

      if (tokenUse == 'refresh') {
        refreshToken = token;
        final exchanged = await _exchangeRefreshToken(token);
        if (exchanged != null && exchanged.isNotEmpty) {
          accessToken = exchanged;
        }
      }

      final profileName = await _tryFetchUsername('Bearer $accessToken');
      return AuthSession(
        username: profileName ?? 'Wger Athlete #$sub',
        accessToken: accessToken,
        refreshToken: refreshToken,
        authScheme: 'Bearer',
        isDemo: false,
        loggedInAt: DateTime.now(),
      );
    }

    // Case B: Wger Standard API Key (Token <key>)
    final profileName = await _tryFetchUsername('Token $token');
    return AuthSession(
      username: profileName ?? 'Wger Athlete',
      accessToken: token,
      authScheme: 'Token',
      isDemo: false,
      loggedInAt: DateTime.now(),
    );
  }

  Future<String?> _exchangeRefreshToken(String refreshToken) async {
    final endpoints = [
      ApiConstants.allauthTokenRefresh,
      ApiConstants.legacyTokenRefresh,
    ];

    for (final url in endpoints) {
      try {
        final res = await _client
            .post(
              Uri.parse(url),
              headers: _headers(),
              body: jsonEncode({'refresh': refreshToken}),
            )
            .timeout(const Duration(seconds: 10));

        if (res.statusCode >= 200 && res.statusCode < 300) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          final direct = data['access'] ?? data['access_token'];
          if (direct != null && direct.toString().isNotEmpty) {
            return direct.toString();
          }
          final meta = data['meta'] as Map<String, dynamic>?;
          if (meta != null && meta['access_token'] != null) {
            return meta['access_token'].toString();
          }
        }
      } catch (_) {
        // Try next endpoint
      }
    }
    return null;
  }

  Future<String?> _tryFetchUsername(String authHeader) async {
    try {
      final res = await _client
          .get(
            Uri.parse(ApiConstants.userProfile),
            headers: _headers(authHeader: authHeader),
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body);
        if (data is Map<String, dynamic>) {
          final results = data['results'];
          if (results is List && results.isNotEmpty) {
            final first = results.first as Map<String, dynamic>;
            final name = first['username'] ?? first['email'];
            if (name != null && name.toString().isNotEmpty) {
              return name.toString();
            }
          }
          final name = data['username'] ?? data['email'];
          if (name != null && name.toString().isNotEmpty) {
            return name.toString();
          }
        }
      }
    } catch (_) {}
    return null;
  }

  /// Fetch exercise categories from Wger public API.
  Future<List<ExerciseCategory>> fetchCategories() async {
    final res = await _client
        .get(Uri.parse(ApiConstants.exerciseCategory), headers: _headers())
        .timeout(const Duration(seconds: 12));

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final results = data['results'] as List? ?? [];
      return results
          .whereType<Map<String, dynamic>>()
          .map(ExerciseCategory.fromJson)
          .toList();
    }
    throw WgerApiException(
      'Gagal memuat kategori latihan (${res.statusCode})',
      statusCode: res.statusCode,
    );
  }

  /// Fetch exercises with illustrations, muscles, and descriptions from /api/v2/exerciseinfo/.
  Future<List<ExerciseModel>> fetchExercises({
    int limit = 40,
    int offset = 0,
    int? categoryId,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
      if (categoryId != null && categoryId > 0)
        'category': categoryId.toString(),
    };

    final uri = Uri.parse(ApiConstants.exerciseInfo)
        .replace(queryParameters: queryParams);

    final res = await _client
        .get(uri, headers: _headers())
        .timeout(const Duration(seconds: 15));

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final results = data['results'] as List? ?? [];
      return results
          .whereType<Map<String, dynamic>>()
          .map(ExerciseModel.fromWgerJson)
          .toList();
    }

    throw WgerApiException(
      'Gagal memuat katalog gerakan Wger (${res.statusCode})',
      statusCode: res.statusCode,
    );
  }

  /// Sync a routine to the user's Wger account via POST /api/v2/routine/.
  Future<int?> createWgerRoutine({
    required AuthSession session,
    required String name,
    required String description,
  }) async {
    if (session.isDemo || !session.hasToken) return null;

    final now = DateTime.now();
    final startStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final end = now.add(const Duration(days: 90));
    final endStr =
        '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';

    try {
      final res = await _client
          .post(
            Uri.parse(ApiConstants.routine),
            headers: _headers(authHeader: session.authorizationHeader),
            body: jsonEncode({
              'name': name,
              'description': description,
              'start': startStr,
              'end': endStr,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return (data['id'] as num?)?.toInt();
      }
    } catch (_) {}
    return null;
  }

  /// Sync a completed set to Wger /api/v2/workoutlog/.
  Future<bool> syncWorkoutLog({
    required AuthSession session,
    required int exerciseId,
    required double weightKg,
    required int reps,
    required DateTime date,
  }) async {
    if (session.isDemo || !session.hasToken) return false;
    try {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final res = await _client
          .post(
            Uri.parse(ApiConstants.workoutLog),
            headers: _headers(authHeader: session.authorizationHeader),
            body: jsonEncode({
              'exercise': exerciseId,
              'weight': weightKg.toStringAsFixed(1),
              'reps': reps,
              'date': dateStr,
            }),
          )
          .timeout(const Duration(seconds: 8));

      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }
}
