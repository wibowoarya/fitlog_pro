import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/workout_provider.dart';
import '../widgets/progress_chart_widget.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  static const String _metricVolume = '__total_volume__';
  String _selectedMetric = _metricVolume;

  @override
  Widget build(BuildContext context) {
    final workout = context.watch<WorkoutProvider>();
    final theme = Theme.of(context);
    final trackedNames = workout.trackedExerciseNames;

    final effectiveMetric = (_selectedMetric == _metricVolume ||
            trackedNames.contains(_selectedMetric))
        ? _selectedMetric
        : _metricVolume;

    final isVolume = effectiveMetric == _metricVolume;
    final chartPoints = isVolume
        ? workout.volumeSeries()
        : workout.exerciseMaxWeightSeries(effectiveMetric);

    final isWide = MediaQuery.sizeOf(context).width >= 900;
    final dateFmt = DateFormat('EEE, d MMM yyyy • HH:mm');

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        // 4 Stitch KPI Cards with Trend Pills
        GridView.count(
          crossAxisCount: isWide ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: isWide ? 2.0 : 1.48,
          children: [
            _StatCard(
              label: 'Total Sesi',
              value: '${workout.logs.length} Sesi',
              badge: 'Aktif',
              badgeBg: const Color(0xFFEFF6FF),
              badgeFg: AppTheme.primaryBlue,
              valueColor: const Color(0xFF0F172A),
            ),
            _StatCard(
              label: 'Total Volume',
              value:
                  '${(workout.totalLifetimeVolume / 1000).toStringAsFixed(1)} ton',
              badge: '▲ Progres',
              badgeBg: const Color(0xFFE0F2FE),
              badgeFg: const Color(0xFF0284C7),
              valueColor: AppTheme.primaryBlue,
            ),
            _StatCard(
              label: 'Set Selesai',
              value: '${workout.totalCompletedSets} Set',
              badge: 'Konsisten',
              badgeBg: const Color(0xFFEFF6FF),
              badgeFg: AppTheme.primaryBlue,
              valueColor: const Color(0xFF0F172A),
            ),
            _StatCard(
              label: 'Rekor Beban (PR)',
              value: '${workout.highestWeightLifted.toStringAsFixed(1)} kg',
              badge: '🏆 PR',
              badgeBg: const Color(0xFFFEF3C7),
              badgeFg: const Color(0xFFD97706),
              valueColor: const Color(0xFF0F172A),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Unified Interactive Stitch Chart with Metric Switcher
        ProgressChartWidget(
          title: isVolume
              ? 'Perkembangan Total Volume Latihan'
              : 'Beban Maksimal: $effectiveMetric',
          unitLabel: isVolume ? 'kg / sesi' : 'kg',
          points: chartPoints,
          lineColor: isVolume ? AppTheme.primaryBlue : AppTheme.accentCyan,
          trailing: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: DropdownButtonFormField<String>(
              initialValue: effectiveMetric,
              isExpanded: true,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              items: [
                const DropdownMenuItem(
                  value: _metricVolume,
                  child: Text(
                    'Total Volume (kg / sesi)',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                for (final name in trackedNames)
                  DropdownMenuItem(
                    value: name,
                    child: Text(
                      'Beban Maks: $name',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _selectedMetric = v);
              },
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Stitch Recent Session History Card
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppTheme.lightBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Riwayat Sesi Terbaru',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                if (workout.logs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('Belum ada riwayat latihan tersimpan.'),
                  )
                else
                  for (final log in workout.logs)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.lightBorder),
                      ),
                      child: ExpansionTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDBEAFE),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.fitness_center_rounded,
                            color: AppTheme.primaryBlue,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          log.dayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          '${dateFmt.format(log.date)} • ${log.durationMinutes} mnt • ${log.completedSetsCount} set',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${log.totalVolume.toStringAsFixed(0)} kg',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primaryBlue,
                                fontSize: 13,
                              ),
                            ),
                            if (log.isSyncedWithWger) ...[
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.cloud_done_rounded,
                                color: AppTheme.primaryBlue,
                                size: 17,
                              ),
                            ],
                          ],
                        ),
                        children: [
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              children: [
                                for (final s in log.sets)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${s.exerciseName} (Set #${s.setNumber})',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '${s.weightKg} kg × ${s.reps} reps',
                                          style: const TextStyle(
                                            color: AppTheme.primaryBlue,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
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
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String badge;
  final Color badgeBg;
  final Color badgeFg;
  final Color valueColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.badge,
    required this.badgeBg,
    required this.badgeFg,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppTheme.lightBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: badgeFg,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: valueColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
