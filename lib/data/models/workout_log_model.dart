class LoggedSet {
  final String id;
  final int exerciseId;
  final String exerciseName;
  final int setNumber;
  final double weightKg;
  final int reps;
  final bool isCompleted;

  const LoggedSet({
    required this.id,
    required this.exerciseId,
    required this.exerciseName,
    required this.setNumber,
    required this.weightKg,
    required this.reps,
    this.isCompleted = false,
  });

  double get volume => weightKg * reps;

  /// Epley formula for estimated 1RM
  double get estimatedOneRm => reps <= 1 ? weightKg : weightKg * (1 + reps / 30);

  LoggedSet copyWith({
    double? weightKg,
    int? reps,
    bool? isCompleted,
  }) {
    return LoggedSet(
      id: id,
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      setNumber: setNumber,
      weightKg: weightKg ?? this.weightKg,
      reps: reps ?? this.reps,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
        'setNumber': setNumber,
        'weightKg': weightKg,
        'reps': reps,
        'isCompleted': isCompleted,
      };

  factory LoggedSet.fromJson(Map<String, dynamic> json) {
    return LoggedSet(
      id: json['id'].toString(),
      exerciseId: (json['exerciseId'] as num?)?.toInt() ?? 0,
      exerciseName: (json['exerciseName'] ?? 'Latihan').toString(),
      setNumber: (json['setNumber'] as num?)?.toInt() ?? 1,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0,
      reps: (json['reps'] as num?)?.toInt() ?? 0,
      isCompleted: (json['isCompleted'] ?? false) as bool,
    );
  }
}

class WorkoutSessionLog {
  final String id;
  final String dayName;
  final DateTime date;
  final int durationMinutes;
  final List<LoggedSet> sets;
  final bool isSyncedWithWger;

  const WorkoutSessionLog({
    required this.id,
    required this.dayName,
    required this.date,
    required this.durationMinutes,
    required this.sets,
    this.isSyncedWithWger = false,
  });

  double get totalVolume => sets
      .where((s) => s.isCompleted)
      .fold(0.0, (sum, s) => sum + s.volume);

  int get completedSetsCount => sets.where((s) => s.isCompleted).length;

  double maxWeightForExercise(String exerciseName) {
    double maxW = 0;
    for (final s in sets) {
      if (s.isCompleted &&
          s.exerciseName.toLowerCase() == exerciseName.toLowerCase() &&
          s.weightKg > maxW) {
        maxW = s.weightKg;
      }
    }
    return maxW;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'dayName': dayName,
        'date': date.toIso8601String(),
        'durationMinutes': durationMinutes,
        'sets': sets.map((s) => s.toJson()).toList(),
        'isSyncedWithWger': isSyncedWithWger,
      };

  factory WorkoutSessionLog.fromJson(Map<String, dynamic> json) {
    return WorkoutSessionLog(
      id: json['id'].toString(),
      dayName: (json['dayName'] ?? 'Workout Session').toString(),
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 45,
      sets: (json['sets'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(LoggedSet.fromJson)
          .toList(),
      isSyncedWithWger: (json['isSyncedWithWger'] ?? false) as bool,
    );
  }
}
