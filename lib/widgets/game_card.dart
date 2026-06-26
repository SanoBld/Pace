import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/game.dart';

class GameCard extends StatelessWidget {
  final Game game;
  final VoidCallback? onTap;

  const GameCard({super.key, required this.game, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover art
            AspectRatio(
              aspectRatio: 3 / 4,
              child: game.coverUrl != null
                  ? CachedNetworkImage(
                      imageUrl: game.coverUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Center(
                          child: Icon(Icons.videogame_asset_rounded, size: 40),
                        ),
                      ),
                      errorWidget: (_, __, ___) => _placeholder(theme),
                    )
                  : _placeholder(theme),
            ),
            // Name
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Text(
                game.name,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(ThemeData theme) => Container(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Center(
          child: Icon(
            Icons.videogame_asset_rounded,
            size: 40,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
}

/// Horizontal compact game tile for list views
class GameListTile extends StatelessWidget {
  final Game game;
  final VoidCallback? onTap;
  final Widget? trailing;

  const GameListTile({
    super.key,
    required this.game,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 44,
          height: 44,
          child: game.coverUrl != null
              ? CachedNetworkImage(
                  imageUrl: game.coverUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.videogame_asset_rounded, size: 22),
                  ),
                )
              : Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.videogame_asset_rounded,
                    size: 22,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
        ),
      ),
      title: Text(
        game.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: game.released != null
          ? Text('${game.released}',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant))
          : null,
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded),
    );
  }
}
