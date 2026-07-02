import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/leaderboard.dart';
import '../core/utils.dart';

class RunDetailSheet extends StatelessWidget {
  final LeaderboardEntry entry;
  const RunDetailSheet({super.key, required this.entry});

  static void show(BuildContext context, LeaderboardEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RunDetailSheet(entry: entry),
    );
  }

  Future<void> _openVideo() async {
    final url = entry.run.videoUrl;
    if (url == null) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _share(BuildContext context) {
    final run = entry.run;
    final player = run.players.isNotEmpty ? run.players.first.name : '?';
    final text = '${run.gameName ?? ''} — ${run.categoryName ?? ''}\n'
        '#${entry.place} by $player\n'
        'Time: ${AppUtils.formatTime(run.primaryTime)}\n'
        '${run.videoUrl ?? run.weblink ?? ''}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: const Text('Copied to clipboard'), behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final run = entry.run;
    final player = run.players.isNotEmpty ? run.players.first : null;
    final isTop3 = entry.place <= 3;

    return Container(
      decoration: BoxDecoration(color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 8),
        Container(width: 40, height: 4, decoration: BoxDecoration(
            color: theme.colorScheme.outlineVariant, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),

        // Rank + time
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            Text(isTop3 ? AppUtils.rankEmoji(entry.place) : '#${entry.place}',
                style: TextStyle(fontSize: isTop3 ? 28 : 20, fontWeight: FontWeight.bold,
                    color: isTop3 ? Color(AppUtils.rankColor(entry.place)) : theme.colorScheme.onSurface)),
            const SizedBox(width: 12),
            Expanded(child: Text(player?.name ?? '?',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isTop3 ? Color(AppUtils.rankColor(entry.place)).withValues(alpha: 0.15)
                    : theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
                border: isTop3 ? Border.all(color: Color(AppUtils.rankColor(entry.place)).withValues(alpha: 0.5)) : null,
              ),
              child: Text(AppUtils.formatTime(run.primaryTime),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold, fontFamily: 'monospace',
                    color: isTop3 ? Color(AppUtils.rankColor(entry.place)) : theme.colorScheme.onPrimaryContainer,
                  )),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        const Divider(indent: 20, endIndent: 20),

        // Metadata
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Column(children: [
            if (run.date != null) _Row(icon: Icons.calendar_today_rounded, label: 'Date', value: AppUtils.formatDate(run.date)),
            if (run.categoryName != null) _Row(icon: Icons.category_rounded, label: 'Category', value: run.categoryName!),
            if (run.realtimeTime != null && run.realtimeTime != run.primaryTime)
              _Row(icon: Icons.timer_outlined, label: 'Real time', value: AppUtils.formatTime(run.realtimeTime)),
            if (run.ingameTime != null && run.ingameTime != run.primaryTime)
              _Row(icon: Icons.games_rounded, label: 'IGT', value: AppUtils.formatTime(run.ingameTime)),
            if (run.platform != null) _Row(icon: Icons.computer_rounded, label: 'Platform', value: run.platform!),
            if (run.emulated) _Row(icon: Icons.memory_rounded, label: 'Emulator', value: 'Yes'),
            if (run.comment != null && run.comment!.isNotEmpty)
              _Row(icon: Icons.comment_rounded, label: 'Note', value: run.comment!),
          ]),
        ),

        // Action buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(children: [
            if (run.videoUrl != null)
              Expanded(child: FilledButton.icon(
                onPressed: _openVideo,
                icon: const Icon(Icons.play_circle_rounded),
                label: const Text('Watch run'),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              )),
            if (run.videoUrl != null) const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: () => _share(context),
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text('Copy'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
            if (run.weblink != null) ...[
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(run.weblink!);
                  if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                icon: const Icon(Icons.open_in_browser_rounded, size: 16),
                label: const Text('SRC'),
                style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ],
          ]),
        ),
      ]),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Row({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 10),
        Text('$label ', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        Expanded(child: Text(value, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.end, maxLines: 2, overflow: TextOverflow.ellipsis)),
      ]),
    );
  }
}
