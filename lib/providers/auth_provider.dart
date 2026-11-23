import 'package:flutter/foundation.dart';
import '../data/datasources/local_storage_service.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  final LocalStorageService _storage;

  AuthSession? _session;
  bool _isLoading = false;
  String? _error;
  bool _isDarkMode = false;

  AuthProvider({
    required AuthRepository authRepository,
    required LocalStorageService storage,
  })  : _authRepository = authRepository,
        _storage = storage {
    _session = _authRepository.restoreSession();
    _isDarkMode = _storage.loadIsDarkMode();
  }

  AuthSession? get session => _session;
  bool get isAuthenticated => _session != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isDarkMode => _isDarkMode;

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _storage.saveIsDarkMode(_isDarkMode);
    notifyListeners();
  }

  Future<bool> registerWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _session = await _authRepository.registerWithEmail(
        email: email,
        password: password,
        username: username,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithCredentials({
    required String identifier,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _session = await _authRepository.loginWithCredentials(
        identifier: identifier,
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithToken(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _session = await _authRepository.loginWithToken(token);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loginDemo({String username = 'FitLog Athlete'}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _session = await _authRepository.loginDemo(username: username);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _session = null;
    _error = null;
    notifyListeners();
  }
}
