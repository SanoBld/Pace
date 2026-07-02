import 'package:flutter/material.dart';
import '../core/utils.dart';

class WrPoint {
  final DateTime date;
  final double time;
  final String playerName;
  const WrPoint({required this.date, required this.time, required this.playerName});
}

class WrProgressionChart extends StatefulWidget {
  final List<WrPoint> points;
  const WrProgressionChart({super.key, required this.points});
  @override
  State<WrProgressionChart> createState() => _WrProgressionChartState();
}

class _WrProgressionChartState extends State<WrProgressionChart> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final points = widget.points;

    if (points.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.show_chart_rounded, size: 48, color: theme.colorScheme.outlineVariant),
        const SizedBox(height: 12),
        Text('No WR history', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ]));
    }

    final sel = _selectedIndex != null ? points[_selectedIndex!] : null;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('WR Progression', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            Text('${points.length} records • tap a point for details',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ])),
          if (sel != null)
            GestureDetector(
              onTap: () => setState(() => _selectedIndex = null),
              child: Icon(Icons.close_rounded, size: 18, color: theme.colorScheme.onSurfaceVariant),
            ),
        ]),
      ),

      // Selected point detail card
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: sel != null
            ? Padding(
                key: ValueKey(_selectedIndex),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(sel.playerName, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      Text(
                        '${sel.date.day.toString().padLeft(2,'0')}/${sel.date.month.toString().padLeft(2,'0')}/${sel.date.year}',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      if (_selectedIndex! > 0)
                        Text(
                          '−${AppUtils.formatTime(points[_selectedIndex! - 1].time - sel.time)} improvement',
                          style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                    ])),
                    Text(AppUtils.formatTime(sel.time),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold, fontFamily: 'monospace',
                          color: theme.colorScheme.primary,
                        )),
                  ]),
                ),
              )
            : const SizedBox.shrink(),
      ),

      // Chart
      SizedBox(
        height: 200,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(64, 8, 16, 28),
          child: LayoutBuilder(builder: (_, box) {
            return GestureDetector(
              onTapUp: (d) => _onTap(d.localPosition, box.maxWidth, box.maxHeight, points),
              onPanUpdate: (d) => _onTap(d.localPosition, box.maxWidth, box.maxHeight, points),
              child: CustomPaint(
                painter: _ChartPainter(points, theme, _selectedIndex),
                size: Size(box.maxWidth, box.maxHeight),
              ),
            );
          }),
        ),
      ),

      const Divider(height: 24, indent: 16, endIndent: 16),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Text('Record history', style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
      ),

      // History list - reversed (newest first)
      ...List.generate(points.length, (i) {
        final idx = points.length - 1 - i;
        final p = points[idx];
        final prev = idx > 0 ? points[idx - 1] : null;
        final isSelected = _selectedIndex == idx;
        return _WrHistoryTile(
          point: p,
          improvement: prev != null ? prev.time - p.time : null,
          rank: points.length - idx,
          isFirst: idx == 0,
          isSelected: isSelected,
          onTap: () => setState(() => _selectedIndex = isSelected ? null : idx),
        );
      }),
      const SizedBox(height: 8),
    ]);
  }

  void _onTap(Offset pos, double w, double h, List<WrPoint> points) {
    if (points.isEmpty) return;
    final minMs = points.first.date.millisecondsSinceEpoch.toDouble();
    final maxMs = points.last.date.millisecondsSinceEpoch.toDouble();
    final dateRange = maxMs == minMs ? 1.0 : maxMs - minMs;

    double px(DateTime d) => (d.millisecondsSinceEpoch - minMs) / dateRange * w;

    int? closest;
    double minDist = double.infinity;
    for (int i = 0; i < points.length; i++) {
      final dist = (px(points[i].date) - pos.dx).abs();
      if (dist < minDist) { minDist = dist; closest = i; }
    }
    if (closest != null && minDist < 40) {
      setState(() => _selectedIndex = _selectedIndex == closest ? null : closest);
    }
  }
}

class _WrHistoryTile extends StatelessWidget {
  final WrPoint point;
  final double? improvement;
  final int rank;
  final bool isFirst;
  final bool isSelected;
  final VoidCallback onTap;

  const _WrHistoryTile({required this.point, required this.rank, this.improvement,
      this.isFirst = false, this.isSelected = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.08) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: isFirst ? const Color(0xFFFFD700).withValues(alpha: 0.2) : theme.colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
              border: isFirst ? Border.all(color: const Color(0xFFFFD700), width: 1.5) : null,
            ),
            child: Center(child: Text(isFirst ? '🥇' : '#$rank',
                style: TextStyle(fontSize: isFirst ? 14 : 10, fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(point.playerName, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('${point.date.day.toString().padLeft(2,'0')}/${point.date.month.toString().padLeft(2,'0')}/${point.date.year}',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(AppUtils.formatTime(point.time),
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: isFirst ? const Color(0xFFFFD700) : theme.colorScheme.primary)),
            if (improvement != null)
              Text('−${AppUtils.formatTime(improvement)}',
                  style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w500)),
          ]),
        ]),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<WrPoint> points;
  final ThemeData theme;
  final int? selectedIndex;
  _ChartPainter(this.points, this.theme, this.selectedIndex);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final primary = theme.colorScheme.primary;
    final outline = theme.colorScheme.outlineVariant;
    final textColor = theme.colorScheme.onSurfaceVariant;

    final minMs = points.first.date.millisecondsSinceEpoch.toDouble();
    final maxMs = points.last.date.millisecondsSinceEpoch.toDouble();
    final dateRange = maxMs == minMs ? 1.0 : maxMs - minMs;
    final maxT = points.first.time, minT = points.last.time;
    final pad = (maxT - minT) * 0.15;
    final tMin = minT - pad, tMax = maxT + pad;
    final tRange = tMax == tMin ? 1.0 : tMax - tMin;

    double px(DateTime d) => (d.millisecondsSinceEpoch - minMs) / dateRange * size.width;
    double py(double t) => size.height - (t - tMin) / tRange * size.height;

    // Grid
    final gridPaint = Paint()..color = outline.withValues(alpha: 0.4)..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final yp = size.height * i / 4;
      canvas.drawLine(Offset(0, yp), Offset(size.width, yp), gridPaint);
      final t = tMax - (tMax - tMin) * i / 4;
      _drawText(canvas, AppUtils.formatTime(t), Offset(-4, yp), textColor, 9,
          align: TextAlign.right, width: 60);
    }

    // Year labels
    final years = <int>{};
    for (final p in points) { years.add(p.date.year); }
    for (final y in years) {
      final d = DateTime(y);
      if (d.millisecondsSinceEpoch < minMs || d.millisecondsSinceEpoch > maxMs) continue;
      _drawText(canvas, y.toString(), Offset(px(d) - 16, size.height + 4), textColor, 9,
          width: 32, align: TextAlign.center);
    }

    // Fill
    final fill = Path()..moveTo(0, size.height)..lineTo(px(points.first.date), py(points.first.time));
    for (int i = 1; i < points.length; i++) {
      fill.lineTo(px(points[i].date), py(points[i - 1].time));
      fill.lineTo(px(points[i].date), py(points[i].time));
    }
    fill.lineTo(size.width, py(points.last.time));
    fill.lineTo(size.width, size.height);
    fill.close();
    canvas.drawPath(fill, Paint()..color = primary.withValues(alpha: 0.1)..style = PaintingStyle.fill);

    // Step line
    final line = Path()..moveTo(px(points.first.date), py(points.first.time));
    for (int i = 1; i < points.length; i++) {
      line.lineTo(px(points[i].date), py(points[i - 1].time));
      line.lineTo(px(points[i].date), py(points[i].time));
    }
    line.lineTo(size.width, py(points.last.time));
    canvas.drawPath(line, Paint()..color = primary..strokeWidth = 2.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);

    // Points + selected highlight
    for (int i = 0; i < points.length; i++) {
      final cx = px(points[i].date), cy = py(points[i].time);
      final isSel = selectedIndex == i;
      if (isSel) {
        canvas.drawCircle(Offset(cx, cy), 10, Paint()..color = primary.withValues(alpha: 0.15));
      }
      canvas.drawCircle(Offset(cx, cy), isSel ? 7 : 5, Paint()..color = primary..style = PaintingStyle.fill);
      canvas.drawCircle(Offset(cx, cy), isSel ? 7 : 5,
          Paint()..color = theme.colorScheme.surface..style = PaintingStyle.stroke..strokeWidth = isSel ? 3 : 2);
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset, Color color, double size,
      {TextAlign align = TextAlign.left, double width = 100}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: size, fontFamily: 'monospace')),
      textAlign: align, textDirection: TextDirection.ltr,
    )..layout(maxWidth: width);
    final dx = align == TextAlign.right ? offset.dx - tp.width
        : align == TextAlign.center ? offset.dx - tp.width / 2
        : offset.dx;
    tp.paint(canvas, Offset(dx, offset.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_ChartPainter old) => old.selectedIndex != selectedIndex || old.points != points;
}
