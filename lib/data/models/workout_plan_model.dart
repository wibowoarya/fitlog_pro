class PlannedExercise {
  final String id;
  final int exerciseId;
  final String exerciseName;
  final String categoryName;
  final String? imageUrl;
  final int targetSets;
  final int targetReps;
  final double targetWeightKg;
  final int restSeconds;

  const PlannedExercise({
    required this.id,
    required this.exerciseId,
    required this.exerciseName,
    required this.categoryName,
    this.imageUrl,
    this.targetSets = 3,
    this.targetReps = 10,
    this.targetWeightKg = 20.0,
    this.restSeconds = 90,
  });

  PlannedExercise copyWith({
    int? targetSets,
    int? targetReps,
    double? targetWeightKg,
    int? restSeconds,
  }) {
    return PlannedExercise(
      id: id,
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      categoryName: categoryName,
      imageUrl: imageUrl,
      targetSets: targetSets ?? this.targetSets,
      targetReps: targetReps ?? this.targetReps,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      restSeconds: restSeconds ?? this.restSeconds,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
        'categoryName': categoryName,
        'imageUrl': imageUrl,
        'targetSets': targetSets,
        'targetReps': targetReps,
        'targetWeightKg': targetWeightKg,
        'restSeconds': restSeconds,
      };

  factory PlannedExercise.fromJson(Map<String, dynamic> json) {
    return PlannedExercise(
      id: json['id'].toString(),
      exerciseId: (json['exerciseId'] as num?)?.toInt() ?? 0,
      exerciseName: (json['exerciseName'] ?? 'Latihan').toString(),
      categoryName: (json['categoryName'] ?? 'General').toString(),
      imageUrl: json['imageUrl'] as String?,
      targetSets: (json['targetSets'] as num?)?.toInt() ?? 3,
      targetReps: (json['targetReps'] as num?)?.toInt() ?? 10,
      targetWeightKg: (json['targetWeightKg'] as num?)?.toDouble() ?? 20.0,
      restSeconds: (json['restSeconds'] as num?)?.toInt() ?? 90,
    );
  }
}

class WorkoutDay {
  final String id;
  final int? wgerDayId;
  final String name; // e.g., "Push Day (Chest & Triceps)"
  final int weekday; // 1 = Senin ... 7 = Minggu
  final bool isRestDay;
  final List<PlannedExercise> exercises;

  const WorkoutDay({
    required this.id,
    this.wgerDayId,
    required this.name,
    required this.weekday,
    this.isRestDay = false,
    this.exercises = const [],
  });

  WorkoutDay copyWith({
    int? wgerDayId,
    String? name,
    int? weekday,
    bool? isRestDay,
    List<PlannedExercise>? exercises,
  }) {
    return WorkoutDay(
      id: id,
      wgerDayId: wgerDayId ?? this.wgerDayId,
      name: name ?? this.name,
      weekday: weekday ?? this.weekday,
      isRestDay: isRestDay ?? this.isRestDay,
      exercises: exercises ?? this.exercises,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'wgerDayId': wgerDayId,
        'name': name,
        'weekday': weekday,
        'isRestDay': isRestDay,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };

  factory WorkoutDay.fromJson(Map<String, dynamic> json) {
    return WorkoutDay(
      id: json['id'].toString(),
      wgerDayId: (json['wgerDayId'] as num?)?.toInt(),
      name: (json['name'] ?? 'Workout Day').toString(),
      weekday: (json['weekday'] as num?)?.toInt() ?? 1,
      isRestDay: (json['isRestDay'] ?? false) as bool,
      exercises: (json['exercises'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(PlannedExercise.fromJson)
          .toList(),
    );
  }
}

class WorkoutPlan {
  final String id;
  final int? wgerRoutineId;
  final String name;
  final String description;
  final List<WorkoutDay> days;
  final DateTime updatedAt;
  final bool isSyncedWithWger;

  const WorkoutPlan({
    required this.id,
    this.wgerRoutineId,
    required this.name,
    this.description = '',
    this.days = const [],
    required this.updatedAt,
    this.isSyncedWithWger = false,
  });

  WorkoutPlan copyWith({
    int? wgerRoutineId,
    String? name,
    String? description,
    List<WorkoutDay>? days,
    DateTime? updatedAt,
    bool? isSyncedWithWger,
  }) {
    return WorkoutPlan(
      id: id,
      wgerRoutineId: wgerRoutineId ?? this.wgerRoutineId,
      name: name ?? this.name,
      description: description ?? this.description,
      days: days ?? this.days,
      updatedAt: updatedAt ?? this.updatedAt,
      isSyncedWithWger: isSyncedWithWger ?? this.isSyncedWithWger,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'wgerRoutineId': wgerRoutineId,
        'name': name,
        'description': description,
        'days': days.map((d) => d.toJson()).toList(),
        'updatedAt': updatedAt.toIso8601String(),
        'isSyncedWithWger': isSyncedWithWger,
      };

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) {
    return WorkoutPlan(
      id: json['id'].toString(),
      wgerRoutineId: (json['wgerRoutineId'] as num?)?.toInt(),
      name: (json['name'] ?? 'My Workout Split').toString(),
      description: (json['description'] ?? '').toString(),
      days: (json['days'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(WorkoutDay.fromJson)
          .toList(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
      isSyncedWithWger: (json['isSyncedWithWger'] ?? false) as bool,
    );
  }
}
