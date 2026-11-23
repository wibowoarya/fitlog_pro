import 'dart:async';
import 'package:flutter/foundation.dart';

class RestTimerProvider extends ChangeNotifier {
  Timer? _timer;
  int _totalSeconds = 90;
  int _remainingSeconds = 0;
  bool _isRunning = false;
  String? _activeExerciseName;

  int get totalSeconds => _totalSeconds;
  int get remainingSeconds => _remainingSeconds;
  bool get isRunning => _isRunning;
  bool get isActive => _remainingSeconds > 0;
  String? get activeExerciseName => _activeExerciseName;

  double get progress {
    if (_totalSeconds <= 0) return 0;
    return (_remainingSeconds / _totalSeconds).clamp(0.0, 1.0);
  }

  String get formattedRemaining {
    final mins = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  void startRest({int seconds = 90, String? exerciseName}) {
    _timer?.cancel();
    _totalSeconds = seconds > 0 ? seconds : 60;
    _remainingSeconds = _totalSeconds;
    _activeExerciseName = exerciseName;
    _isRunning = true;
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        _remainingSeconds = 0;
        _isRunning = false;
        timer.cancel();
        notifyListeners();
      } else {
        _remainingSeconds--;
        notifyListeners();
      }
    });
  }

  void togglePause() {
    if (_remainingSeconds <= 0) return;
    if (_isRunning) {
      _timer?.cancel();
      _isRunning = false;
      notifyListeners();
    } else {
      _isRunning = true;
      notifyListeners();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds <= 1) {
          _remainingSeconds = 0;
          _isRunning = false;
          timer.cancel();
          notifyListeners();
        } else {
          _remainingSeconds--;
          notifyListeners();
        }
      });
    }
  }

  void adjustSeconds(int delta) {
    final updated = (_remainingSeconds + delta).clamp(0, 600);
    _remainingSeconds = updated;
    if (updated > _totalSeconds) {
      _totalSeconds = updated;
    }
    if (updated == 0) {
      _timer?.cancel();
      _isRunning = false;
    }
    notifyListeners();
  }

  void stop() {
    _timer?.cancel();
    _remainingSeconds = 0;
    _isRunning = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
