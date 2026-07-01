import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/run.dart';
import '../core/utils.dart';

class RunTile extends StatelessWidget {
  final Run run;
  final VoidCallback? onTap;        // tap right side → game
  final VoidCallback? onPlayerTap;  // tap avatar/name → player profile
  final bool showGame;

  const RunTile({
    super.key,
    required this.run,
    this.onTap,
    this.onPlayerTap,
    this.showGame = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playerName = run.players.isNotEmpty ? run.players.first.name : '?';
    final avatarUrl = run.players.isNotEmpty ? run.players.first.avatarUrl : null;
    final hasVideo = run.videoUrl != null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          // ── Left: player tap zone ────────────────────────────────────
          InkWell(
            onTap: onPlayerTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    backgroundImage: avatarUrl != null
                        ? CachedNetworkImageProvider(avatarUrl)
                        : null,
                    child: avatarUrl == null
                        ? Text(
                            playerName.isNotEmpty
                                ? playerName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          )
                        : null,
                  ),
                  if (hasVideo)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 15,
                        height: 15,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: theme.colorScheme.surface, width: 1.5),
                        ),
                        child: const Icon(Icons.play_arrow_rounded,
                            size: 9, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Right: game tap zone ─────────────────────────────────────
          Expanded(
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 14, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            playerName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (showGame && run.gameName != null)
                            Text(
                              run.gameName!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (run.categoryName != null)
                            Text(
                              run.categoryName!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            AppUtils.formatTime(run.primaryTime),
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        if (run.date != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              AppUtils.formatDate(run.date),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
