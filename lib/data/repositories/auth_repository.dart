import '../../core/constants/api_constants.dart';
import '../datasources/local_storage_service.dart';
import '../datasources/supabase_service.dart';
import '../datasources/wger_api_service.dart';
import '../models/user_model.dart';

class AuthRepository {
  final WgerApiService _apiService;
  final SupabaseService _supabaseService;
  final LocalStorageService _storage;

  AuthRepository({
    required WgerApiService apiService,
    required SupabaseService supabaseService,
    required LocalStorageService storage,
  })  : _apiService = apiService,
        _supabaseService = supabaseService,
        _storage = storage;

  AuthSession? restoreSession() => _storage.loadAuthSession();

  Future<AuthSession> registerWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    final session = await _supabaseService.signUp(
      email: email,
      password: password,
      username: username,
    );
    await _storage.saveAuthSession(session);
    return session;
  }

  Future<AuthSession> loginWithCredentials({
    required String identifier,
    required String password,
  }) async {
    final trimmed = identifier.trim();

    // 1. Coba login ke Supabase Auth terlebih dahulu
    try {
      final session = await _supabaseService.signIn(
        email: trimmed,
        password: password,
      );
      await _storage.saveAuthSession(session);
      return session;
    } catch (supabaseErr) {
      // 2. Jika akun default admin@gmail.com / password123, fallback ke Wger JWT
      if (trimmed.toLowerCase() == ApiConstants.defaultEmail &&
          password == ApiConstants.defaultPassword) {
        final session = await _apiService.loginWithCredentials(
          identifier: trimmed,
          password: password,
        );
        await _storage.saveAuthSession(session);
        return session;
      }

      // 3. Jika bukan akun default, lempar error dari Supabase
      throw Exception(supabaseErr.toString());
    }
  }

  Future<AuthSession> loginWithToken(String rawToken) async {
    final session = await _apiService.loginWithToken(rawToken);
    await _storage.saveAuthSession(session);
    return session;
  }

  Future<AuthSession> loginDemo({String username = 'FitLog Athlete'}) async {
    final session = AuthSession(
      username: username,
      email: 'athlete@fitlog.pro',
      isDemo: true,
      loggedInAt: DateTime.now(),
    );
    await _storage.saveAuthSession(session);
    return session;
  }

  Future<void> logout() async {
    await _storage.clearAuthSession();
  }
}
