import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../../core/theme/app_theme.dart';

class ProgressChartWidget extends StatefulWidget {
  final String title;
  final String subtitle;
  final String unitLabel;
  final List<({DateTime date, double value})> points;
  final Color lineColor;
  final Widget? trailing;

  const ProgressChartWidget({
    super.key,
    required this.title,
    this.subtitle = 'Ketuk titik grafik untuk melihat detail sesi',
    required this.unitLabel,
    required this.points,
    this.lineColor = AppTheme.primaryBlue,
    this.trailing,
  });

  @override
  State<ProgressChartWidget> createState() => _ProgressChartWidgetState();
}

class _ProgressChartWidgetState extends State<ProgressChartWidget> {
  int? _selectedIndex;

  int get _effectiveIndex {
    if (widget.points.isEmpty) return 0;
    if (_selectedIndex != null &&
        _selectedIndex! >= 0 &&
        _selectedIndex! < widget.points.length) {
      return _selectedIndex!;
    }
    return widget.points.length - 1;
  }

  void _selectByPosition(double localX, double totalWidth) {
    if (widget.points.length <= 1) return;
    const double leftPad = 46;
    const double rightPad = 16;
    final chartWidth = (totalWidth - leftPad - rightPad).clamp(1.0, 10000.0);
    final ratio = ((localX - leftPad) / chartWidth).clamp(0.0, 1.0);
    final idx = (ratio * (widget.points.length - 1)).round();
    if (idx != _selectedIndex) {
      setState(() => _selectedIndex = idx);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('d MMM yyyy');
    final shortDateFmt = DateFormat('d MMM');
    final activePoint =
        widget.points.isNotEmpty ? widget.points[_effectiveIndex] : null;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.lightBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                      widget.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                if (widget.trailing != null)
                  widget.trailing!
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: widget.lineColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.unitLabel,
                      style: TextStyle(
                        color: widget.lineColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Stitch Interactive Readout Banner
            if (activePoint != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Titik Terpilih: ${dateFmt.format(activePoint.date)}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${activePoint.value.toStringAsFixed(activePoint.value.truncateToDouble() == activePoint.value ? 0 : 1)} ${widget.unitLabel}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: widget.lineColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            if (widget.points.isEmpty)
              SizedBox(
                height: 180,
                child: Center(
                  child: Text(
                    'Belum ada data latihan tercatat.\nSelesaikan sesi gym untuk melihat grafik progres.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              Column(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        onTapDown: (d) => _selectByPosition(
                          d.localPosition.dx,
                          constraints.maxWidth,
                        ),
                        onHorizontalDragUpdate: (d) => _selectByPosition(
                          d.localPosition.dx,
                          constraints.maxWidth,
                        ),
                        child: SizedBox(
                          height: 210,
                          width: double.infinity,
                          child: CustomPaint(
                            painter: _LineChartPainter(
                              points: widget.points,
                              selectedIndex: _effectiveIndex,
                              lineColor: widget.lineColor,
                              textColor: theme.colorScheme.onSurfaceVariant,
                              gridColor:
                                  theme.dividerColor.withValues(alpha: 0.35),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        shortDateFmt.format(widget.points.first.date),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (widget.points.length > 2)
                        Text(
                          shortDateFmt.format(
                            widget.points[widget.points.length ~/ 2].date,
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      Text(
                        shortDateFmt.format(widget.points.last.date),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<({DateTime date, double value})> points;
  final int selectedIndex;
  final Color lineColor;
  final Color textColor;
  final Color gridColor;

  _LineChartPainter({
    required this.points,
    required this.selectedIndex,
    required this.lineColor,
    required this.textColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    const double leftPad = 46;
    const double rightPad = 16;
    const double topPad = 16;
    const double bottomPad = 12;

    final chartWidth = size.width - leftPad - rightPad;
    final chartHeight = size.height - topPad - bottomPad;

    final rawMax = points.map((p) => p.value).reduce(math.max);
    final rawMin = points.map((p) => p.value).reduce(math.min);
    final maxVal = rawMax <= 0 ? 100.0 : rawMax * 1.15;
    final minVal = math.max(0.0, rawMin * 0.8);
    final range = (maxVal - minVal) <= 0 ? 1.0 : (maxVal - minVal);

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    const steps = 3;
    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final y = topPad + chartHeight * (1 - t);
      canvas.drawLine(
        Offset(leftPad, y),
        Offset(size.width - rightPad, y),
        gridPaint,
      );

      final labelVal = minVal + range * t;
      final tp = TextPainter(
        text: TextSpan(
          text: labelVal >= 1000
              ? '${(labelVal / 1000).toStringAsFixed(1)}k'
              : labelVal.toStringAsFixed(0),
          style: TextStyle(color: textColor, fontSize: 11),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    final offsets = <Offset>[];
    for (int i = 0; i < points.length; i++) {
      final x = points.length == 1
          ? leftPad + chartWidth / 2
          : leftPad + (chartWidth * i / (points.length - 1));
      final normalized = (points[i].value - minVal) / range;
      final y = topPad + chartHeight * (1 - normalized);
      offsets.add(Offset(x, y));
    }

    if (offsets.length > 1) {
      final fillPath = Path()..moveTo(offsets.first.dx, topPad + chartHeight);
      for (final o in offsets) {
        fillPath.lineTo(o.dx, o.dy);
      }
      fillPath
        ..lineTo(offsets.last.dx, topPad + chartHeight)
        ..close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            lineColor.withValues(alpha: 0.30),
            lineColor.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, topPad, size.width, chartHeight));
      canvas.drawPath(fillPath, fillPaint);

      final linePath = Path()..moveTo(offsets.first.dx, offsets.first.dy);
      for (int i = 1; i < offsets.length; i++) {
        linePath.lineTo(offsets[i].dx, offsets[i].dy);
      }
      final linePaint = Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(linePath, linePaint);
    }

    // Vertical guide line for selected point
    if (selectedIndex >= 0 && selectedIndex < offsets.length) {
      final sel = offsets[selectedIndex];
      final guidePaint = Paint()
        ..color = lineColor.withValues(alpha: 0.35)
        ..strokeWidth = 1.5;
      canvas.drawLine(
        Offset(sel.dx, topPad),
        Offset(sel.dx, topPad + chartHeight),
        guidePaint,
      );
    }

    final dotFill = Paint()..color = lineColor;
    final dotStroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    for (int i = 0; i < offsets.length; i++) {
      final o = offsets[i];
      final isSel = i == selectedIndex;
      if (isSel) {
        canvas.drawCircle(
          o,
          10,
          Paint()..color = lineColor.withValues(alpha: 0.18),
        );
      }
      canvas.drawCircle(o, isSel ? 6.5 : 4.8, dotFill);
      canvas.drawCircle(o, isSel ? 6.5 : 4.8, dotStroke);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}
