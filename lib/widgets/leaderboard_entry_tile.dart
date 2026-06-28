import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/leaderboard.dart';
import '../core/utils.dart';

class LeaderboardEntryTile extends StatelessWidget {
  final LeaderboardEntry entry;
  final VoidCallback? onTap;       // tap row → player profile
  final VoidCallback? onVideoTap;  // tap video icon → open video

  const LeaderboardEntryTile({
    super.key,
    required this.entry,
    this.onTap,
    this.onVideoTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final run = entry.run;
    final place = entry.place;
    final isTop3 = place <= 3;
    final playerName =
        run.players.isNotEmpty ? run.players.first.name : 'Unknown';
    final avatarUrl =
        run.players.isNotEmpty ? run.players.first.avatarUrl : null;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Rank badge
            SizedBox(
              width: 44,
              child: isTop3
                  ? Text(AppUtils.rankEmoji(place),
                      style: const TextStyle(fontSize: 22),
                      textAlign: TextAlign.center)
                  : Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '#$place',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            // Avatar
            CircleAvatar(
              radius: 18,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              backgroundImage: avatarUrl != null
                  ? CachedNetworkImageProvider(avatarUrl)
                  : null,
              child: avatarUrl == null
                  ? Text(
                      playerName.isNotEmpty
                          ? playerName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            // Name + date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playerName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight:
                          isTop3 ? FontWeight.bold : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (run.date != null)
                    Text(
                      AppUtils.formatDate(run.date),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            // Time badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isTop3
                    ? Color(AppUtils.rankColor(place)).withOpacity(0.15)
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: isTop3
                    ? Border.all(
                        color:
                            Color(AppUtils.rankColor(place)).withOpacity(0.5))
                    : null,
              ),
              child: Text(
                AppUtils.formatTime(run.primaryTime),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: isTop3
                      ? Color(AppUtils.rankColor(place))
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
            // Video button
            if (onVideoTap != null)
              IconButton(
                icon: Icon(
                  Icons.play_circle_outline_rounded,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                onPressed: onVideoTap,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.only(left: 4),
              ),
          ],
        ),
      ),
    );
  }
}