import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/workout_plan_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/workout_provider.dart';

class WorkoutPlannerScreen extends StatefulWidget {
  final VoidCallback onOpenCatalog;

  const WorkoutPlannerScreen({super.key, required this.onOpenCatalog});

  @override
  State<WorkoutPlannerScreen> createState() => _WorkoutPlannerScreenState();
}

class _WorkoutPlannerScreenState extends State<WorkoutPlannerScreen> {
  int _editingWeekday = DateTime.now().weekday;

  @override
  Widget build(BuildContext context) {
    final workout = context.watch<WorkoutProvider>();
    final auth = context.read<AuthProvider>();
    final plan = workout.activePlan;
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    final selectedDay = plan.days.firstWhere(
      (d) => d.weekday == _editingWeekday,
      orElse: () => plan.days.first,
    );

    final activeDaysCount = plan.days.where((d) => !d.isRestDay).length;
    final restDaysCount = plan.days.length - activeDaysCount;
    final totalWeeklySets = plan.days.fold<int>(
      0,
      (sum, d) =>
          sum +
          (d.isRestDay
              ? 0
              : d.exercises.fold<int>(0, (s, e) => s + e.targetSets)),
    );

    return Column(
      children: [
        // Stitch Blue Hero Summary Card
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.deepBlue, AppTheme.primaryBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.deepBlue.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 14,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'ACTIVE WORKOUT SPLIT',
                        style: TextStyle(
                          color: Color(0xFFDBEAFE),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: plan.id,
                        dropdownColor: AppTheme.deepBlue,
                        iconEnabledColor: Colors.white,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                        items: workout.plans
                            .map(
                              (p) => DropdownMenuItem(
                                value: p.id,
                                child: Text(p.name),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) workout.setActivePlan(val);
                        },
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$activeDaysCount Hari Latihan • $restDaysCount Rest Day • Total $totalWeeklySets Set / Minggu',
                      style: const TextStyle(
                        color: Color(0xFFDBEAFE),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _showCreatePlanDialog(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.white.withValues(alpha: 0.14),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 17),
                      label: const Text(
                        'Split Baru',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: workout.isSyncing || auth.session == null
                          ? null
                          : () async {
                              await workout.syncActivePlanToWger(auth.session!);
                              if (context.mounted &&
                                  workout.syncMessage != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(workout.syncMessage!)),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primaryBlue,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 11,
                        ),
                      ),
                      icon: workout.isSyncing
                          ? const SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primaryBlue,
                              ),
                            )
                          : Icon(
                              plan.isSyncedWithWger
                                  ? Icons.cloud_done_rounded
                                  : Icons.cloud_upload_rounded,
                              size: 17,
                            ),
                      label: Text(
                        plan.isSyncedWithWger ? 'Synced Wger' : 'Sync ke Wger',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Main Split Workspace
        Expanded(
          child: isWide
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 310, child: _buildDaysList(plan)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          child: _buildDayDetailEditor(context, selectedDay),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                  children: [
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: plan.days.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final d = plan.days[index];
                          return ChoiceChip(
                            selected: d.weekday == _editingWeekday,
                            label: Text(ApiConstants.daysOfWeek[d.weekday - 1]),
                            onSelected: (_) =>
                                setState(() => _editingWeekday = d.weekday),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDayDetailEditor(context, selectedDay),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildDaysList(WorkoutPlan plan) {
    return ListView.separated(
      itemCount: plan.days.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final day = plan.days[index];
        final isSelected = day.weekday == _editingWeekday;
        final dayLabel = ApiConstants.daysOfWeek[day.weekday - 1];

        return InkWell(
          onTap: () => setState(() => _editingWeekday = day.weekday),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppTheme.primaryBlue : AppTheme.lightBorder,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dayLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: day.isRestDay
                            ? AppTheme.accentCyan
                            : AppTheme.primaryBlue,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: day.isRestDay
                            ? const Color(0xFFE0F2FE)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        day.isRestDay
                            ? 'Rest Day'
                            : '${day.exercises.length} gerakan',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: day.isRestDay
                              ? const Color(0xFF0284C7)
                              : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  day.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDayDetailEditor(BuildContext context, WorkoutDay day) {
    final workout = context.read<WorkoutProvider>();
    final theme = Theme.of(context);
    final dayLabel = ApiConstants.daysOfWeek[day.weekday - 1];

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.lightBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dayLabel.toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            day.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Ubah Nama Hari',
                          onPressed: () => _showEditDayDialog(context, day),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                        ),
                      ],
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () => workout.updateDayInfo(
                        weekday: day.weekday,
                        name: day.name,
                        isRestDay: !day.isRestDay,
                      ),
                      child: Text(
                        day.isRestDay
                            ? 'Jadikan Hari Latihan'
                            : 'Set Rest Day',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: widget.onOpenCatalog,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text(
                        'Tambah Gerakan',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            if (day.isRestDay)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 36),
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.self_improvement_rounded,
                          size: 40,
                          color: AppTheme.accentCyan,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Hari Istirahat & Pemulihan',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Otot bertumbuh saat istirahat. Klik "Tambah Gerakan" jika ingin menjadwalkan latihan.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (day.exercises.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'Belum ada gerakan. Klik "Tambah Gerakan" untuk memilih dari Katalog Wger.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: day.exercises.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final ex = day.exercises[index];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.lightBorder),
                    ),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: const Color(0xFFDBEAFE),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 260),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ex.exerciseName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${ex.categoryName} • ${ex.targetSets} set × ${ex.targetReps} reps • Rest ${ex.restSeconds}s',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        // Stitch Inline Weight Stepper + Edit + Delete
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _StepperBtn(
                              icon: Icons.remove_rounded,
                              onTap: () => workout.updatePlannedExercise(
                                weekday: day.weekday,
                                updated: ex.copyWith(
                                  targetWeightKg: (ex.targetWeightKg - 2.5)
                                      .clamp(0, 500),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Text(
                                '${ex.targetWeightKg.toStringAsFixed(ex.targetWeightKg.truncateToDouble() == ex.targetWeightKg ? 0 : 1)} kg',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryBlue,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            _StepperBtn(
                              icon: Icons.add_rounded,
                              onTap: () => workout.updatePlannedExercise(
                                weekday: day.weekday,
                                updated: ex.copyWith(
                                  targetWeightKg: ex.targetWeightKg + 2.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            IconButton(
                              tooltip: 'Edit Target',
                              onPressed: () => _showEditExerciseDialog(
                                context,
                                day.weekday,
                                ex,
                              ),
                              icon: const Icon(Icons.tune_rounded, size: 19),
                            ),
                            IconButton(
                              tooltip: 'Hapus',
                              onPressed: () => workout.removeExerciseFromDay(
                                weekday: day.weekday,
                                plannedExerciseId: ex.id,
                              ),
                              icon: const Icon(
                                Icons.close_rounded,
                                color: AppTheme.dangerRose,
                                size: 19,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreatePlanDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final workout = context.read<WorkoutProvider>();
    final auth = context.read<AuthProvider>();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buat Workout Split Baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nama Split (mis. Upper / Lower)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Deskripsi Singkat'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              await workout.createNewPlan(
                name: nameCtrl.text,
                description: descCtrl.text,
                authSession: auth.session,
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Buat'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDayDialog(BuildContext context, WorkoutDay day) async {
    final nameCtrl = TextEditingController(text: day.name);
    bool isRest = day.isRestDay;
    final workout = context.read<WorkoutProvider>();

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('Edit ${ApiConstants.daysOfWeek[day.weekday - 1]}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama Sesi (mis. Push Day)',
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Tandai sebagai Rest Day'),
                value: isRest,
                onChanged: (v) => setLocal(() => isRest = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () async {
                await workout.updateDayInfo(
                  weekday: day.weekday,
                  name: nameCtrl.text.trim().isEmpty
                      ? day.name
                      : nameCtrl.text.trim(),
                  isRestDay: isRest,
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditExerciseDialog(
    BuildContext context,
    int weekday,
    PlannedExercise ex,
  ) async {
    final setsCtrl = TextEditingController(text: ex.targetSets.toString());
    final repsCtrl = TextEditingController(text: ex.targetReps.toString());
    final weightCtrl = TextEditingController(text: ex.targetWeightKg.toString());
    final restCtrl = TextEditingController(text: ex.restSeconds.toString());
    final workout = context.read<WorkoutProvider>();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ex.exerciseName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: setsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Set'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: repsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Repetisi'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: weightCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Beban (kg)'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: restCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Rest (dtk)'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              await workout.updatePlannedExercise(
                weekday: weekday,
                updated: ex.copyWith(
                  targetSets: int.tryParse(setsCtrl.text) ?? ex.targetSets,
                  targetReps: int.tryParse(repsCtrl.text) ?? ex.targetReps,
                  targetWeightKg:
                      double.tryParse(weightCtrl.text.replaceAll(',', '.')) ??
                          ex.targetWeightKg,
                  restSeconds: int.tryParse(restCtrl.text) ?? ex.restSeconds,
                ),
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

class _StepperBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepperBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.lightBorder),
        ),
        child: Icon(icon, size: 16, color: const Color(0xFF334155)),
      ),
    );
  }
}
