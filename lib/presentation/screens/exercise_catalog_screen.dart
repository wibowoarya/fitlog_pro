import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/exercise_model.dart';
import '../../providers/exercise_provider.dart';
import '../../providers/workout_provider.dart';
import '../widgets/exercise_card.dart';

class ExerciseCatalogScreen extends StatefulWidget {
  const ExerciseCatalogScreen({super.key});

  @override
  State<ExerciseCatalogScreen> createState() => _ExerciseCatalogScreenState();
}

class _ExerciseCatalogScreenState extends State<ExerciseCatalogScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExerciseProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<ExerciseProvider>();
    final exercises = catalog.filteredExercises;
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= 1200
        ? 4
        : width >= 850
            ? 3
            : width >= 540
                ? 2
                : 1;

    return Column(
      children: [
        // Stitch White Search & Filter Bar Card
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: AppTheme.lightBorder),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: catalog.setSearchQuery,
                          decoration: InputDecoration(
                            hintText:
                                'Cari gerakan otot (Bench Press, Squat, Pull-Ups)...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: catalog.searchQuery.isNotEmpty
                                ? IconButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      catalog.setSearchQuery('');
                                    },
                                    icon: const Icon(Icons.clear_rounded),
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: catalog.isFromApi
                                    ? AppTheme.primaryBlue
                                    : AppTheme.warningAmber,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              catalog.isFromApi
                                  ? 'Wger Live API'
                                  : 'Offline Cache',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            selected: catalog.selectedCategoryId == null,
                            label: const Text('Semua Otot'),
                            onSelected: (_) => catalog.selectCategory(null),
                          ),
                        ),
                        for (final cat in catalog.categories)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              selected: catalog.selectedCategoryId == cat.id,
                              label: Text(cat.name),
                              onSelected: (_) => catalog.selectCategory(cat.id),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Grid
        Expanded(
          child: catalog.isLoading
              ? const Center(child: CircularProgressIndicator())
              : exercises.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Tidak ada gerakan ditemukan untuk "${catalog.searchQuery}".',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                          sliver: SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 14,
                              childAspectRatio:
                                  crossAxisCount == 1 ? 1.08 : 0.78,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final ex = exercises[index];
                                return ExerciseCard(
                                  exercise: ex,
                                  onTap: () => _showStitchExerciseModal(
                                    context,
                                    ex,
                                  ),
                                  onAddToPlan: () => _showStitchExerciseModal(
                                    context,
                                    ex,
                                  ),
                                );
                              },
                              childCount: exercises.length,
                            ),
                          ),
                        ),
                        if (catalog.hasMore)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                              child: Center(
                                child: OutlinedButton.icon(
                                  onPressed: catalog.isLoadingMore
                                      ? null
                                      : catalog.loadMore,
                                  icon: catalog.isLoadingMore
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.expand_more_rounded),
                                  label: Text(
                                    catalog.isLoadingMore
                                        ? 'Memuat gerakan Wger...'
                                        : 'Muat Lebih Banyak dari Wger',
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
        ),
      ],
    );
  }

  /// Stitch-style Blue Header Modal: shows exercise illustration/description AND direct Add to Split controls.
  Future<void> _showStitchExerciseModal(
    BuildContext context,
    ExerciseModel exercise,
  ) async {
    int selectedWeekday = DateTime.now().weekday;
    final setsCtrl = TextEditingController(text: '4');
    final repsCtrl = TextEditingController(text: '10');
    final weightCtrl = TextEditingController(text: '40');
    final restCtrl = TextEditingController(text: '90');
    final workout = context.read<WorkoutProvider>();

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Dialog(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Blue Gradient Modal Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.deepBlue, AppTheme.primaryBlue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  exercise.category.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                exercise.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                [
                                  if (exercise.muscles.isNotEmpty)
                                    exercise.muscles
                                        .map((m) => m.displayName)
                                        .join(', '),
                                  if (exercise.equipment.isNotEmpty)
                                    exercise.equipment.join(', '),
                                ].join(' • '),
                                style: const TextStyle(
                                  color: Color(0xFFDBEAFE),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (exercise.mainImageUrl != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              height: 160,
                              color: const Color(0xFFEFF6FF),
                              child: Image.network(
                                exercise.mainImageUrl!,
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) => const Center(
                                  child: Icon(
                                    Icons.fitness_center_rounded,
                                    size: 48,
                                    color: AppTheme.primaryBlue,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        Text(
                          exercise.description,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF475569),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Add to Split Box
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.lightBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Tambahkan ke Jadwal Mingguan',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<int>(
                                initialValue: selectedWeekday,
                                decoration: const InputDecoration(
                                  labelText: 'Pilih Hari',
                                ),
                                items: List.generate(
                                  7,
                                  (i) => DropdownMenuItem(
                                    value: i + 1,
                                    child: Text(ApiConstants.daysOfWeek[i]),
                                  ),
                                ),
                                onChanged: (v) {
                                  if (v != null) {
                                    setLocal(() => selectedWeekday = v);
                                  }
                                },
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: setsCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Set',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: repsCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Reps',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: weightCtrl,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                      decoration: const InputDecoration(
                                        labelText: 'Beban (kg)',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: restCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Rest (dtk)',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              FilledButton.icon(
                                onPressed: () async {
                                  await workout.addExerciseToDay(
                                    weekday: selectedWeekday,
                                    exercise: exercise,
                                    targetSets:
                                        int.tryParse(setsCtrl.text) ?? 4,
                                    targetReps:
                                        int.tryParse(repsCtrl.text) ?? 10,
                                    targetWeightKg: double.tryParse(
                                          weightCtrl.text.replaceAll(',', '.'),
                                        ) ??
                                        40,
                                    restSeconds:
                                        int.tryParse(restCtrl.text) ?? 90,
                                  );
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${exercise.name} ditambahkan ke hari ${ApiConstants.daysOfWeek[selectedWeekday - 1]}!',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: const Text('Simpan ke Jadwal Split'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
