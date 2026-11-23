import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/workout_log_model.dart';
import '../../data/models/workout_plan_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/rest_timer_provider.dart';
import '../../providers/workout_provider.dart';

class TodayWorkoutScreen extends StatelessWidget {
  const TodayWorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final workout = context.watch<WorkoutProvider>();
    final timer = context.read<RestTimerProvider>();
    final auth = context.read<AuthProvider>();
    final day = workout.selectedWorkoutDay;
    final theme = Theme.of(context);
    final todayWeekday = DateTime.now().weekday;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        // Day of week selector strip
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 7,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final weekday = index + 1;
              final isSelected = workout.selectedWeekday == weekday;
              final isToday = todayWeekday == weekday;
              return ChoiceChip(
                selected: isSelected,
                label: Text(
                  isToday
                      ? '${ApiConstants.daysOfWeek[index]} • Hari Ini'
                      : ApiConstants.daysOfWeek[index],
                ),
                onSelected: (_) => workout.selectWeekday(weekday),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Session summary header + quick rest timer presets
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryEmerald.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        day?.isRestDay == true
                            ? Icons.self_improvement_rounded
                            : Icons.local_fire_department_rounded,
                        color: AppTheme.primaryEmerald,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            day?.name ?? 'Jadwal Latihan',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            day?.isRestDay == true
                                ? 'Hari pemulihan otot & mobilitas'
                                : '${workout.completedActiveSetsCount}/${workout.totalActiveSetsCount} set selesai',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (day != null && !day.isRestDay) ...[
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: workout.activeSessionProgress,
                      minHeight: 8,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryEmerald,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Quick Rest Timer:',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      for (final sec in [60, 90, 120])
                        ActionChip(
                          avatar: const Icon(Icons.timer_outlined, size: 16),
                          label: Text('${sec}s'),
                          onPressed: () => timer.startRest(
                            seconds: sec,
                            exerciseName: 'Istirahat Manual (${sec}s)',
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        if (day == null || day.isRestDay || day.exercises.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    day?.isRestDay == true
                        ? Icons.spa_rounded
                        : Icons.playlist_add_rounded,
                    size: 56,
                    color: AppTheme.accentCyan.withValues(alpha: 0.7),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    day?.isRestDay == true
                        ? 'Hari Ini Rest Day!'
                        : 'Belum Ada Gerakan di Hari Ini',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    day?.isRestDay == true
                        ? 'Gunakan hari ini untuk pemulihan otot, tidur cukup, dan stretching ringan. Atau pilih hari lain di atas untuk mulai berlatih.'
                        : 'Tambahkan gerakan dari Katalog Wger atau atur jadwal di tab Jadwal Split.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else ...[
          for (final pe in day.exercises) ...[
            _ActiveExerciseCard(
              planned: pe,
              sets: workout.setsForPlannedExercise(pe),
              onToggleSet: (setIndex, checked) {
                workout.updateActiveSet(
                  plannedExerciseId: pe.id,
                  setIndex: setIndex,
                  isCompleted: checked,
                );
                if (checked) {
                  timer.startRest(
                    seconds: pe.restSeconds,
                    exerciseName: pe.exerciseName,
                  );
                }
              },
              onEditSet: (setIndex, current) async {
                final edited = await _showEditSetDialog(context, current);
                if (edited != null) {
                  workout.updateActiveSet(
                    plannedExerciseId: pe.id,
                    setIndex: setIndex,
                    weightKg: edited.weightKg,
                    reps: edited.reps,
                  );
                }
              },
              onAddSet: () => workout.addExtraSetToActiveExercise(pe),
            ),
            const SizedBox(height: 14),
          ],
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: workout.completedActiveSetsCount == 0 ||
                    workout.isSyncing
                ? null
                : () async {
                    final saved = await workout.finishAndSaveSession(
                      authSession: auth.session,
                    );
                    if (context.mounted && saved != null) {
                      timer.stop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Sesi "${saved.dayName}" tersimpan! Volume total: ${saved.totalVolume.toStringAsFixed(0)} kg${saved.isSyncedWithWger ? ' • Synced Wger' : ''}',
                          ),
                        ),
                      );
                    }
                  },
            icon: workout.isSyncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_circle_rounded),
            label: Text(
              workout.isSyncing
                  ? 'Menyimpan & Sync ke Wger...'
                  : 'Selesaikan & Simpan Sesi (${workout.completedActiveSetsCount} Set)',
            ),
          ),
        ],
      ],
    );
  }

  Future<({double weightKg, int reps})?> _showEditSetDialog(
    BuildContext context,
    LoggedSet current,
  ) async {
    final weightCtrl = TextEditingController(
      text: current.weightKg.toStringAsFixed(
        current.weightKg.truncateToDouble() == current.weightKg ? 0 : 1,
      ),
    );
    final repsCtrl = TextEditingController(text: current.reps.toString());

    return showDialog<({double weightKg, int reps})>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${current.exerciseName} • Set #${current.setNumber}'),
        content: Row(
          children: [
            Expanded(
              child: TextField(
                controller: weightCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Beban (kg)',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: repsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Repetisi',
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final w = double.tryParse(weightCtrl.text.replaceAll(',', '.')) ??
                  current.weightKg;
              final r = int.tryParse(repsCtrl.text) ?? current.reps;
              Navigator.pop(ctx, (weightKg: w, reps: r));
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

class _ActiveExerciseCard extends StatelessWidget {
  final PlannedExercise planned;
  final List<LoggedSet> sets;
  final void Function(int setIndex, bool checked) onToggleSet;
  final void Function(int setIndex, LoggedSet current) onEditSet;
  final VoidCallback onAddSet;

  const _ActiveExerciseCard({
    required this.planned,
    required this.sets,
    required this.onToggleSet,
    required this.onEditSet,
    required this.onAddSet,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final doneCount = sets.where((s) => s.isCompleted).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        planned.exerciseName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${planned.categoryName} • Rest ${planned.restSeconds}s • $doneCount/${sets.length} selesai',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Tambah Set',
                  onPressed: onAddSet,
                  icon: const Icon(Icons.add_circle_outline_rounded),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                SizedBox(
                  width: 44,
                  child: Text(
                    'SET',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'BEBAN (KG)',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'REPETISI',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                SizedBox(
                  width: 52,
                  child: Text(
                    'DONE',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            for (int i = 0; i < sets.length; i++)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: sets[i].isCompleted
                      ? AppTheme.primaryEmerald.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 38,
                      child: CircleAvatar(
                        radius: 13,
                        backgroundColor: sets[i].isCompleted
                            ? AppTheme.primaryEmerald
                            : theme.colorScheme.surfaceContainerHighest,
                        child: Text(
                          '${sets[i].setNumber}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: sets[i].isCompleted
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => onEditSet(i, sets[i]),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 4,
                          ),
                          child: Text(
                            '${sets[i].weightKg.toStringAsFixed(sets[i].weightKg.truncateToDouble() == sets[i].weightKg ? 0 : 1)} kg',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => onEditSet(i, sets[i]),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 4,
                          ),
                          child: Text(
                            '${sets[i].reps} reps',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 52,
                      child: Checkbox(
                        value: sets[i].isCompleted,
                        activeColor: AppTheme.primaryEmerald,
                        onChanged: (val) => onToggleSet(i, val ?? false),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
