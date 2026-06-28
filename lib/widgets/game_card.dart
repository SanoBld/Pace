import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/game.dart';
import '../providers/favorites_provider.dart';

class GameCard extends StatelessWidget {
  final Game game;
  final VoidCallback? onTap;

  const GameCard({super.key, required this.game, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 3 / 4,
                  child: game.coverUrl != null
                      ? CachedNetworkImage(
                          imageUrl: game.coverUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _placeholder(theme),
                          errorWidget: (_, __, ___) => _placeholder(theme),
                        )
                      : _placeholder(theme),
                ),
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
          // Favorite button overlay
          Positioned(
            top: 4,
            right: 4,
            child: Consumer<FavoritesProvider>(
              builder: (_, favs, __) {
                final isFav = favs.isFavorite(game.id);
                return GestureDetector(
                  onTap: () => favs.toggleFavorite(game),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isFav
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 14,
                      color: isFav ? Colors.redAccent : Colors.white,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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

class GameListTile extends StatelessWidget {
  final Game game;
  final VoidCallback? onTap;
  final Widget? trailing;

  const GameListTile({super.key, required this.game, this.onTap, this.trailing});

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
                  errorWidget: (_, __, ___) => _tilePlaceholder(theme),
                )
              : _tilePlaceholder(theme),
        ),
      ),
      title: Text(game.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: game.released != null
          ? Text('${game.released}',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant))
          : null,
      trailing: trailing ??
          Consumer<FavoritesProvider>(
            builder: (_, favs, __) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    favs.isFavorite(game.id)
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 18,
                    color: favs.isFavorite(game.id)
                        ? Colors.redAccent
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () => favs.toggleFavorite(game),
                  visualDensity: VisualDensity.compact,
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
    );
  }

  Widget _tilePlaceholder(ThemeData theme) => Container(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Icon(Icons.videogame_asset_rounded,
            size: 22, color: theme.colorScheme.onSurfaceVariant),
      );
}