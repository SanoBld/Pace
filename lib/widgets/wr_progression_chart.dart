import 'package:flutter/material.dart';
import '../core/utils.dart';

class WrPoint {
  final DateTime date;
  final double time;
  final String playerName;

  const WrPoint({
    required this.date,
    required this.time,
    required this.playerName,
  });
}

class WrProgressionChart extends StatelessWidget {
  final List<WrPoint> points;

  const WrProgressionChart({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (points.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.show_chart_rounded,
                size: 48, color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 12),
            Text('No WR history available',
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text(
            'WR Progression',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Text(
            '${points.length} world records',
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(64, 8, 16, 28),
            child: CustomPaint(
              painter: _ChartPainter(points, theme),
              size: Size.infinite,
            ),
          ),
        ),
        const Divider(height: 24, indent: 16, endIndent: 16),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text('Record history',
              style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold)),
        ),
        ...List.generate(points.length, (i) {
          final idx = points.length - 1 - i;
          final p = points[idx];
          final prev = idx > 0 ? points[idx - 1] : null;
          final improvement = prev != null ? prev.time - p.time : null;
          final isFirst = idx == 0;

          return _WrHistoryTile(
            point: p,
            improvement: improvement,
            rank: points.length - idx,
            isFirst: isFirst,
          );
        }),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _WrHistoryTile extends StatelessWidget {
  final WrPoint point;
  final double? improvement;
  final int rank;
  final bool isFirst;

  const _WrHistoryTile({
    required this.point,
    required this.rank,
    this.improvement,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isFirst
                  ? const Color(0xFFFFD700).withValues(alpha: 0.2)
                  : theme.colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
              border: isFirst
                  ? Border.all(color: const Color(0xFFFFD700), width: 1.5)
                  : null,
            ),
            child: Center(
              child: Text(
                isFirst ? '🥇' : '#$rank',
                style: TextStyle(
                  fontSize: isFirst ? 14 : 10,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(point.playerName,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(
                  '${point.date.year}-${point.date.month.toString().padLeft(2, '0')}-${point.date.day.toString().padLeft(2, '0')}',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                AppUtils.formatTime(point.time),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: isFirst
                      ? const Color(0xFFFFD700)
                      : theme.colorScheme.primary,
                ),
              ),
              if (improvement != null)
                Text(
                  '−${AppUtils.formatTime(improvement)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<WrPoint> points;
  final ThemeData theme;

  _ChartPainter(this.points, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final primary = theme.colorScheme.primary;
    final outline = theme.colorScheme.outlineVariant;
    final textColor = theme.colorScheme.onSurfaceVariant;

    final minMs = points.first.date.millisecondsSinceEpoch.toDouble();
    final maxMs = points.last.date.millisecondsSinceEpoch.toDouble();
    final dateRange = maxMs == minMs ? 1.0 : maxMs - minMs;

    final maxT = points.first.time;
    final minT = points.last.time;
    final pad = (maxT - minT) * 0.15;
    final tMin = minT - pad;
    final tMax = maxT + pad;
    final tRange = tMax == tMin ? 1.0 : tMax - tMin;

    double px(DateTime d) =>
        (d.millisecondsSinceEpoch - minMs) / dateRange * size.width;

    double py(double t) =>
        size.height - (t - tMin) / tRange * size.height;

    // Grid
    final gridPaint = Paint()
      ..color = outline.withValues(alpha: 0.4)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final yp = size.height * i / 4;
      canvas.drawLine(Offset(0, yp), Offset(size.width, yp), gridPaint);

      // Y-axis time label
      final t = tMax - (tMax - tMin) * i / 4;
      _drawText(
        canvas,
        AppUtils.formatTime(t),
        Offset(-4, yp),
        textColor,
        9,
        align: TextAlign.right,
        width: 60,
      );
    }

    // X-axis year labels
    final years = <int>{};
    for (final p in points) years.add(p.date.year);
    for (final y in years) {
      final d = DateTime(y);
      if (d.millisecondsSinceEpoch < minMs || d.millisecondsSinceEpoch > maxMs) continue;
      final xp = px(d);
      _drawText(
        canvas,
        y.toString(),
        Offset(xp - 16, size.height + 4),
        textColor,
        9,
        width: 32,
        align: TextAlign.center,
      );
    }

    // Fill under step line
    final fillPaint = Paint()
      ..color = primary.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final fill = Path();
    fill.moveTo(0, size.height);
    fill.lineTo(px(points.first.date), py(points.first.time));

    for (int i = 1; i < points.length; i++) {
      fill.lineTo(px(points[i].date), py(points[i - 1].time));
      fill.lineTo(px(points[i].date), py(points[i].time));
    }
    fill.lineTo(size.width, py(points.last.time));
    fill.lineTo(size.width, size.height);
    fill.close();
    canvas.drawPath(fill, fillPaint);

    // Step line
    final linePaint = Paint()
      ..color = primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final line = Path();
    line.moveTo(px(points.first.date), py(points.first.time));

    for (int i = 1; i < points.length; i++) {
      line.lineTo(px(points[i].date), py(points[i - 1].time));
      line.lineTo(px(points[i].date), py(points[i].time));
    }
    line.lineTo(size.width, py(points.last.time));
    canvas.drawPath(line, linePaint);

    // Points
    final dotFill = Paint()..color = primary..style = PaintingStyle.fill;
    final dotBorder = Paint()
      ..color = theme.colorScheme.surface
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final p in points) {
      final cx = px(p.date);
      final cy = py(p.time);
      canvas.drawCircle(Offset(cx, cy), 5, dotFill);
      canvas.drawCircle(Offset(cx, cy), 5, dotBorder);
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    Color color,
    double fontSize, {
    TextAlign align = TextAlign.left,
    double width = 100,
  }) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontFamily: 'monospace',
          )),
      textAlign: align,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width);

    final dx = align == TextAlign.right
        ? offset.dx - tp.width
        : align == TextAlign.center
            ? offset.dx - tp.width / 2
            : offset.dx;
    tp.paint(canvas, Offset(dx, offset.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_ChartPainter old) => old.points != points;
}
