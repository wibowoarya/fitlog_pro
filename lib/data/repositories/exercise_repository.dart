import '../datasources/wger_api_service.dart';
import '../models/exercise_model.dart';

class ExerciseRepository {
  final WgerApiService _apiService;

  ExerciseRepository({required WgerApiService apiService})
      : _apiService = apiService;

  Future<List<ExerciseCategory>> getCategories() async {
    try {
      final remote = await _apiService.fetchCategories();
      if (remote.isNotEmpty) return remote;
    } catch (_) {}
    return _fallbackCategories;
  }

  Future<({List<ExerciseModel> items, bool isFromApi})> getExercises({
    int limit = 40,
    int offset = 0,
    int? categoryId,
  }) async {
    try {
      final remote = await _apiService.fetchExercises(
        limit: limit,
        offset: offset,
        categoryId: categoryId,
      );
      if (remote.isNotEmpty) {
        return (items: remote, isFromApi: true);
      }
    } catch (_) {}

    final filtered = categoryId == null || categoryId == 0
        ? _fallbackExercises
        : _fallbackExercises
            .where((e) => e.category.id == categoryId)
            .toList();
    return (items: filtered, isFromApi: false);
  }

  static const List<ExerciseCategory> _fallbackCategories = [
    ExerciseCategory(id: 11, name: 'Chest'),
    ExerciseCategory(id: 12, name: 'Back'),
    ExerciseCategory(id: 9, name: 'Legs'),
    ExerciseCategory(id: 13, name: 'Shoulders'),
    ExerciseCategory(id: 8, name: 'Arms'),
    ExerciseCategory(id: 10, name: 'Abs'),
  ];

  static const List<ExerciseModel> _fallbackExercises = [
    ExerciseModel(
      id: 192,
      name: 'Barbell Bench Press',
      description:
          'Berbaring di bench datar, genggam barbel sedikit lebih lebar dari bahu. Turunkan barbel secara terkontrol hingga menyentuh dada tengah, lalu dorong kembali ke atas hingga lengan lurus.',
      category: ExerciseCategory(id: 11, name: 'Chest'),
      muscles: [
        MuscleModel(
          id: 4,
          name: 'Pectoralis major',
          nameEn: 'Chest',
        ),
      ],
      musclesSecondary: [
        MuscleModel(
          id: 5,
          name: 'Triceps brachii',
          nameEn: 'Triceps',
        ),
      ],
      equipment: ['Barbell', 'Bench'],
    ),
    ExerciseModel(
      id: 163,
      name: 'Incline Dumbbell Press',
      description:
          'Atur bench pada sudut 30-45 derajat. Dorong sepasang dumbbell dari samping dada ke atas secara bersamaan sambil mengencangkan otot dada atas.',
      category: ExerciseCategory(id: 11, name: 'Chest'),
      muscles: [
        MuscleModel(
          id: 4,
          name: 'Pectoralis major',
          nameEn: 'Upper Chest',
        ),
      ],
      equipment: ['Dumbbell', 'Incline Bench'],
    ),
    ExerciseModel(
      id: 107,
      name: 'Pull-Ups',
      description:
          'Gantung pada pull-up bar dengan grip overhand lebih lebar dari bahu. Tarik tubuh ke atas hingga dagu melewati palang, lalu turunkan perlahan.',
      category: ExerciseCategory(id: 12, name: 'Back'),
      muscles: [
        MuscleModel(
          id: 12,
          name: 'Latissimus dorsi',
          nameEn: 'Lats',
          isFront: false,
        ),
      ],
      musclesSecondary: [
        MuscleModel(
          id: 1,
          name: 'Biceps brachii',
          nameEn: 'Biceps',
        ),
      ],
      equipment: ['Pull-up Bar'],
    ),
    ExerciseModel(
      id: 109,
      name: 'Barbell Bent-Over Row',
      description:
          'Condongkan tubuh sekitar 45 derajat dengan punggung lurus. Tarik barbel ke arah perut bagian bawah dengan meremas tulang belikat, lalu turunkan terkontrol.',
      category: ExerciseCategory(id: 12, name: 'Back'),
      muscles: [
        MuscleModel(
          id: 12,
          name: 'Latissimus dorsi',
          nameEn: 'Mid Back & Lats',
          isFront: false,
        ),
      ],
      equipment: ['Barbell'],
    ),
    ExerciseModel(
      id: 111,
      name: 'Barbell Back Squat',
      description:
          'Letakkan barbel di punggung atas, buka kaki selebar bahu. Turunkan pinggul ke bawah hingga paha sejajar lantai sambil menjaga dada tegak, lalu dorong naik melalui tumit.',
      category: ExerciseCategory(id: 9, name: 'Legs'),
      muscles: [
        MuscleModel(
          id: 10,
          name: 'Quadriceps femoris',
          nameEn: 'Quadriceps',
        ),
      ],
      musclesSecondary: [
        MuscleModel(
          id: 8,
          name: 'Gluteus maximus',
          nameEn: 'Glutes',
          isFront: false,
        ),
      ],
      equipment: ['Barbell', 'Squat Rack'],
    ),
    ExerciseModel(
      id: 105,
      name: 'Romanian Deadlift (RDL)',
      description:
          'Pegang barbel di depan paha dengan lutut sedikit ditekuk. Dorong pinggul ke belakang sambil menurunkan barbel menyusuri tulang kering hingga terasa regangan pada hamstring.',
      category: ExerciseCategory(id: 9, name: 'Legs'),
      muscles: [
        MuscleModel(
          id: 11,
          name: 'Biceps femoris',
          nameEn: 'Hamstrings',
          isFront: false,
        ),
      ],
      equipment: ['Barbell'],
    ),
    ExerciseModel(
      id: 119,
      name: 'Overhead Shoulder Press',
      description:
          'Berdiri tegak dengan barbel di depan bahu. Dorong barbel lurus ke atas kepala sambil mengencangkan core, lalu turunkan kembali secara terkontrol.',
      category: ExerciseCategory(id: 13, name: 'Shoulders'),
      muscles: [
        MuscleModel(
          id: 2,
          name: 'Anterior deltoid',
          nameEn: 'Shoulders',
        ),
      ],
      equipment: ['Barbell'],
    ),
    ExerciseModel(
      id: 148,
      name: 'Dumbbell Lateral Raises',
      description:
          'Berdiri dengan dumbbell di samping paha. Angkat kedua lengan ke samping hingga sejajar bahu dengan siku sedikit menekuk, lalu turunkan perlahan.',
      category: ExerciseCategory(id: 13, name: 'Shoulders'),
      muscles: [
        MuscleModel(
          id: 2,
          name: 'Lateral deltoid',
          nameEn: 'Side Delts',
        ),
      ],
      equipment: ['Dumbbell'],
    ),
    ExerciseModel(
      id: 74,
      name: 'Barbell Bicep Curl',
      description:
          'Pegang barbel dengan grip underhand selebar bahu. Jaga siku tetap menempel di sisi tubuh, angkat barbel menuju bahu, lalu turunkan perlahan.',
      category: ExerciseCategory(id: 8, name: 'Arms'),
      muscles: [
        MuscleModel(
          id: 1,
          name: 'Biceps brachii',
          nameEn: 'Biceps',
        ),
      ],
      equipment: ['Barbell'],
    ),
    ExerciseModel(
      id: 89,
      name: 'Cable Triceps Pushdown',
      description:
          'Pegang tali/bar kabel dengan siku rapat di sisi tubuh. Dorong ke bawah hingga lengan lurus sempurna, rasakan kontraksi triceps, lalu kembali perlahan.',
      category: ExerciseCategory(id: 8, name: 'Arms'),
      muscles: [
        MuscleModel(
          id: 5,
          name: 'Triceps brachii',
          nameEn: 'Triceps',
          isFront: false,
        ),
      ],
      equipment: ['Cable Machine'],
    ),
    ExerciseModel(
      id: 91,
      name: 'Hanging Leg Raises',
      description:
          'Gantung di pull-up bar, kencangkan perut dan angkat kedua kaki lurus ke depan hingga sejajar pinggul atau lebih tinggi tanpa mengayun.',
      category: ExerciseCategory(id: 10, name: 'Abs'),
      muscles: [
        MuscleModel(
          id: 6,
          name: 'Rectus abdominis',
          nameEn: 'Abs',
        ),
      ],
      equipment: ['Pull-up Bar'],
    ),
  ];
}
