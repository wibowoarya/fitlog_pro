import '../../core/constants/api_constants.dart';

class ExerciseCategory {
  final int id;
  final String name;

  const ExerciseCategory({required this.id, required this.name});

  factory ExerciseCategory.fromJson(Map<String, dynamic> json) {
    return ExerciseCategory(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? 'Lainnya').toString(),
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class MuscleModel {
  final int id;
  final String name;
  final String nameEn;
  final bool isFront;

  const MuscleModel({
    required this.id,
    required this.name,
    required this.nameEn,
    this.isFront = true,
  });

  String get displayName => nameEn.isNotEmpty ? nameEn : name;

  factory MuscleModel.fromJson(Map<String, dynamic> json) {
    return MuscleModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      nameEn: (json['name_en'] ?? '').toString(),
      isFront: (json['is_front'] ?? true) as bool,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'name_en': nameEn,
        'is_front': isFront,
      };
}

class ExerciseModel {
  final int id;
  final String name;
  final String description;
  final ExerciseCategory category;
  final List<MuscleModel> muscles;
  final List<MuscleModel> musclesSecondary;
  final List<String> equipment;
  final List<String> imageUrls;

  const ExerciseModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.muscles = const [],
    this.musclesSecondary = const [],
    this.equipment = const [],
    this.imageUrls = const [],
  });

  String? get mainImageUrl => imageUrls.isNotEmpty ? imageUrls.first : null;

  static String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  static String _resolveImageUrl(String rawUrl) {
    if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
      return rawUrl;
    }
    if (rawUrl.startsWith('/')) {
      return '${ApiConstants.baseUrl}$rawUrl';
    }
    return '${ApiConstants.baseUrl}/$rawUrl';
  }

  factory ExerciseModel.fromWgerJson(Map<String, dynamic> json) {
    // Extract best translation (prefer English lang=2, fallback to first non-empty)
    String name = '';
    String description = '';

    final translations = json['translations'];
    if (translations is List && translations.isNotEmpty) {
      Map<String, dynamic>? selected;
      for (final item in translations) {
        if (item is Map<String, dynamic>) {
          final lang = (item['language'] as num?)?.toInt();
          final candidateName = (item['name'] ?? '').toString().trim();
          if (lang == ApiConstants.wgerEnglishLangId &&
              candidateName.isNotEmpty) {
            selected = item;
            break;
          }
        }
      }
      selected ??= translations.cast<Map<String, dynamic>>().firstWhere(
            (t) => (t['name'] ?? '').toString().trim().isNotEmpty,
            orElse: () => translations.first as Map<String, dynamic>,
          );

      name = (selected['name'] ?? '').toString().trim();
      description = _stripHtml((selected['description'] ?? '').toString());
    } else {
      name = (json['name'] ?? 'Exercise #${json['id']}').toString().trim();
      description = _stripHtml((json['description'] ?? '').toString());
    }

    if (name.isEmpty) {
      name = 'Exercise #${json['id']}';
    }

    // Category
    final rawCategory = json['category'];
    final category = rawCategory is Map<String, dynamic>
        ? ExerciseCategory.fromJson(rawCategory)
        : const ExerciseCategory(id: 0, name: 'General');

    // Muscles
    final rawMuscles = json['muscles'] as List? ?? [];
    final muscles = rawMuscles
        .whereType<Map<String, dynamic>>()
        .map(MuscleModel.fromJson)
        .toList();

    final rawSecondary = json['muscles_secondary'] as List? ?? [];
    final musclesSecondary = rawSecondary
        .whereType<Map<String, dynamic>>()
        .map(MuscleModel.fromJson)
        .toList();

    // Equipment
    final rawEquipment = json['equipment'] as List? ?? [];
    final equipment = rawEquipment
        .whereType<Map<String, dynamic>>()
        .map((e) => (e['name'] ?? '').toString())
        .where((e) => e.isNotEmpty)
        .toList();

    // Images (put is_main=true first)
    final rawImages = (json['images'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    rawImages.sort((a, b) {
      final aMain = (a['is_main'] == true) ? 0 : 1;
      final bMain = (b['is_main'] == true) ? 0 : 1;
      return aMain.compareTo(bMain);
    });
    final imageUrls = rawImages
        .map((img) => (img['image'] ?? '').toString().trim())
        .where((url) => url.isNotEmpty)
        .map(_resolveImageUrl)
        .toList();

    return ExerciseModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: name,
      description: description.isEmpty
          ? 'Lakukan gerakan dengan kontrol penuh, jaga postur tubuh, dan atur pernapasan di setiap repetisi.'
          : description,
      category: category,
      muscles: muscles,
      musclesSecondary: musclesSecondary,
      equipment: equipment,
      imageUrls: imageUrls,
    );
  }
}
