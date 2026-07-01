import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
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
  String? _twitchUsername;

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

    _twitchUsername = username;
    final live = await TwitchService().isLive(username);
    if (mounted) setState(() => _isLive = live);
  }

  void _showStreamPreview() {
    if (_twitchUsername == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StreamPreviewSheet(
        username: _twitchUsername!,
        playerName: widget.entry.run.players.isNotEmpty
            ? widget.entry.run.players.first.name
            : _twitchUsername!,
        twitchUrl:
            widget.entry.run.players.first.socials['twitch'] ??
            'https://twitch.tv/$_twitchUsername',
      ),
    );
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
            // Rank
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
                      child: Text('#$place',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center),
                    ),
            ),
            const SizedBox(width: 12),

            // Avatar + live badge
            GestureDetector(
              onTap: _isLive ? _showStreamPreview : null,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor:
                        theme.colorScheme.surfaceContainerHighest,
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
                          color: _isLive
                              ? Colors.green
                              : const Color(0xFF9146FF),
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
            ),
            const SizedBox(width: 10),

            // Name + date + LIVE badge
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
                        GestureDetector(
                          onTap: _showStreamPreview,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('LIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                )),
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
                          fontSize: 11),
                    ),
                ],
              ),
            ),

            // Time
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isTop3
                    ? Color(AppUtils.rankColor(place)).withValues(alpha: 0.15)
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: isTop3
                    ? Border.all(
                        color: Color(AppUtils.rankColor(place))
                            .withValues(alpha: 0.5))
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

// ── Stream preview bottom sheet ───────────────────────────────────────────────

class _StreamPreviewSheet extends StatelessWidget {
  final String username;
  final String playerName;
  final String twitchUrl;

  const _StreamPreviewSheet({
    required this.username,
    required this.playerName,
    required this.twitchUrl,
  });

  Future<void> _openTwitch() async {
    final uri = Uri.parse(twitchUrl);
    if (await canLaunchUrl(uri)) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Twitch CDN preview — updates every 5s, no auth needed
    final previewUrl =
        'https://static-cdn.jtvnw.net/previews-ttv/live_user_${username.toLowerCase()}-640x360.jpg';

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  playerName,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 6),
                Text('is live on Twitch',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Stream thumbnail
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: previewUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: Colors.black,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: Colors.black,
                    child: const Center(
                      child: Icon(Icons.live_tv_rounded,
                          color: Colors.white, size: 48),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Watch button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: FilledButton.icon(
              onPressed: _openTwitch,
              icon: const Icon(Icons.live_tv_rounded),
              label: const Text('Watch on Twitch'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: const Color(0xFF9146FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
