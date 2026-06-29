import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/leaderboard.dart';
import '../core/utils.dart';
import '../services/twitch_service.dart';

class LeaderboardEntryTile extends StatefulWidget {
  final LeaderboardEntry entry;
  final VoidCallback? onTap;
  final VoidCallback? onVideoTap;

  const LeaderboardEntryTile({
    super.key,
    required this.entry,
    this.onTap,
    this.onVideoTap,
  });

  @override
  State<LeaderboardEntryTile> createState() => _LeaderboardEntryTileState();
}

class _LeaderboardEntryTileState extends State<LeaderboardEntryTile> {
  bool _isLive = false;

  @override
  void initState() {
    super.initState();
    _checkLive();
  }

  Future<void> _checkLive() async {
    final player = widget.entry.run.players.isNotEmpty
        ? widget.entry.run.players.first
        : null;
    if (player == null) return;

    final username = TwitchService.usernameFrom(player.socials['twitch']);
    if (username == null) return;

    final live = await TwitchService().isLive(username);
    if (mounted) setState(() => _isLive = live);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final run = widget.entry.run;
    final place = widget.entry.place;
    final isTop3 = place <= 3;
    final player = run.players.isNotEmpty ? run.players.first : null;
    final playerName = player?.name ?? 'Unknown';
    final avatarUrl = player?.avatarUrl;
    final hasTwitch = player?.socials['twitch'] != null;

    return InkWell(
      onTap: widget.onTap,
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

            // Avatar + live badge
            Stack(
              clipBehavior: Clip.none,
              children: [
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
                if (hasTwitch)
                  Positioned(
                    right: -3,
                    bottom: -3,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: _isLive ? Colors.green : const Color(0xFF9146FF),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: theme.colorScheme.surface, width: 1.5),
                      ),
                      child: Icon(
                        _isLive ? Icons.circle : Icons.live_tv_rounded,
                        size: 8,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),

            // Name + date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          playerName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: isTop3
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_isLive) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isTop3
                    ? Color(AppUtils.rankColor(place)).withOpacity(0.15)
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: isTop3
                    ? Border.all(
                        color: Color(AppUtils.rankColor(place)).withOpacity(0.5))
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
            if (widget.onVideoTap != null)
              IconButton(
                icon: Icon(Icons.play_circle_outline_rounded,
                    size: 20, color: theme.colorScheme.primary),
                onPressed: widget.onVideoTap,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.only(left: 4),
              ),
          ],
        ),
      ),
    );
  }
}