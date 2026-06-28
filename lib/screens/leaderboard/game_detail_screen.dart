import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../models/game.dart';
import '../../models/category.dart';
import '../../providers/favorites_provider.dart';
import '../../services/speedrun_api.dart';
import '../../widgets/shared_widgets.dart';
import 'category_leaderboard_screen.dart';

class GameDetailScreen extends StatefulWidget {
  final Game game;

  const GameDetailScreen({super.key, required this.game});

  @override
  State<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen>
    with SingleTickerProviderStateMixin {
  final _api = SpeedrunApiService();
  late TabController _tabController;

  List<Category>? _fullGameCategories;
  List<Category>? _miscCategories;
  List<Map<String, dynamic>>? _levels;
  bool _loadingCategories = true;
  bool _loadingLevels = true;
  String? _catError;
  String? _levelError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCategories();
    _loadLevels();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loadingCategories = true;
      _catError = null;
    });
    try {
      final all = await _api.getAllCategories(widget.game.id);
      if (mounted) {
        setState(() {
          _fullGameCategories =
              all.where((c) => c.isPerGame && !c.miscellaneous).toList();
          _miscCategories =
              all.where((c) => c.isPerGame && c.miscellaneous).toList();
          _loadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _catError = e.toString();
          _loadingCategories = false;
        });
      }
    }
  }

  Future<void> _loadLevels() async {
    setState(() {
      _loadingLevels = true;
      _levelError = null;
    });
    try {
      final levels = await _api.getLevels(widget.game.id);
      if (mounted) {
        setState(() {
          _levels = levels;
          _loadingLevels = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _levelError = e.toString();
          _loadingLevels = false;
        });
      }
    }
  }

  void _openCategory(Category cat, {String? levelId, String? levelName}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryLeaderboardScreen(
          game: widget.game,
          category: cat,
          levelId: levelId,
          levelName: levelName,
        ),
      ),
    );
  }

  Future<void> _openLevel(Map<String, dynamic> level) async {
    final levelId = level['id'] as String;
    final levelName = (level['name'] as String?) ?? levelId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _LevelCategoriesSheet(
        api: _api,
        game: widget.game,
        levelId: levelId,
        levelName: levelName,
        onCategoryTap: (cat) {
          Navigator.pop(context);
          _openCategory(cat, levelId: levelId, levelName: levelName);
        },
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final game = widget.game;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
        SliverAppBar(
            expandedHeight: game.coverUrl != null ? 240 : 120,
            pinned: true,
            foregroundColor: Colors.white,
            backgroundColor: theme.colorScheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.fromSTEB(56, 0, 80, 16),
              title: Text(
                game.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.white,
                  shadows: [
                    Shadow(blurRadius: 12, color: Colors.black),
                    Shadow(blurRadius: 4, color: Colors.black54),
                  ],
                ),
              ),
              background: game.coverUrl != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: game.coverUrl!,
                          fit: BoxFit.cover,
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black54,
                              ],
                              stops: [0.4, 1.0],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ColoredBox(
                      color: theme.colorScheme.primary,
                      child: Center(
                        child: Icon(
                          Icons.videogame_asset_rounded,
                          size: 64,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ),
            ),
            actions: [
              Consumer<FavoritesProvider>(
                builder: (_, favs, __) => IconButton(
                  icon: Icon(
                    favs.isFavorite(game.id)
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: favs.isFavorite(game.id)
                        ? Colors.redAccent
                        : Colors.white,
                  ),
                  tooltip: favs.isFavorite(game.id)
                      ? 'Remove from favorites'
                      : 'Add to favorites',
                  onPressed: () => favs.toggleFavorite(game),
                ),
              ),
              if (game.weblink != null)
                IconButton(
                  icon: const Icon(Icons.open_in_browser_rounded, color: Colors.white),
                  tooltip: l.t('open_link'),
                  onPressed: () async {
                    final uri = Uri.parse(game.weblink!);
                    if (await canLaunchUrl(uri)) {
                      launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
            ],
          ),
          // Game meta row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (game.released != null)
                    Chip(
                      avatar: const Icon(Icons.calendar_today_rounded, size: 14),
                      label: Text('${game.released}'),
                      visualDensity: VisualDensity.compact,
                    ),
                  if (game.abbreviation != null)
                    Chip(
                      avatar: const Icon(Icons.tag_rounded, size: 14),
                      label: Text(game.abbreviation!),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                tabs: [
                  Tab(
                    icon: const Icon(Icons.sports_esports_rounded),
                    text: l.t('lb_full_game'),
                  ),
                  Tab(
                    icon: const Icon(Icons.grid_view_rounded),
                    text: l.t('lb_individual_levels'),
                  ),
                ],
              ),
              theme.colorScheme.surface,
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            // ── Full Game Tab ────────────────────────────────────────────
            _FullGameTab(
              categories: _fullGameCategories,
              miscCategories: _miscCategories,
              loading: _loadingCategories,
              error: _catError,
              onRetry: _loadCategories,
              onCategoryTap: _openCategory,
              l: l,
            ),
            // ── Individual Levels Tab ────────────────────────────────────
            _LevelsTab(
              levels: _levels,
              loading: _loadingLevels,
              error: _levelError,
              onRetry: _loadLevels,
              onLevelTap: _openLevel,
              l: l,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Full Game Tab ────────────────────────────────────────────────────────────

class _FullGameTab extends StatelessWidget {
  final List<Category>? categories;
  final List<Category>? miscCategories;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final void Function(Category) onCategoryTap;
  final dynamic l;

  const _FullGameTab({
    required this.categories,
    required this.miscCategories,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.onCategoryTap,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    if (error != null) return ErrorView(message: error, onRetry: onRetry);
    if (loading) return const ShimmerList(count: 5);
    if (categories == null || categories!.isEmpty) {
      return EmptyView(
        message: l.t('lb_no_runs'),
        icon: Icons.category_rounded,
      );
    }

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      children: [
        // Main categories
        ...categories!.map(
          (cat) => _CategoryTile(
            category: cat,
            onTap: () => onCategoryTap(cat),
          ),
        ),
        // Miscellaneous
        if (miscCategories != null && miscCategories!.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              'Miscellaneous',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          ...miscCategories!.map(
            (cat) => _CategoryTile(
              category: cat,
              onTap: () => onCategoryTap(cat),
              muted: true,
            ),
          ),
        ],
      ],
    );
  }
}

// ── Levels Tab ───────────────────────────────────────────────────────────────

class _LevelsTab extends StatelessWidget {
  final List<Map<String, dynamic>>? levels;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final void Function(Map<String, dynamic>) onLevelTap;
  final dynamic l;

  const _LevelsTab({
    required this.levels,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.onLevelTap,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    if (error != null) return ErrorView(message: error, onRetry: onRetry);
    if (loading) return const ShimmerList(count: 5);
    if (levels == null || levels!.isEmpty) {
      return EmptyView(
        message: l.t('lb_no_runs'),
        icon: Icons.grid_view_rounded,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: levels!.length,
      itemBuilder: (_, i) {
        final level = levels![i];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor:
                Theme.of(context).colorScheme.secondaryContainer,
            child: Text(
              '${i + 1}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            level['name'] as String? ?? 'Level ${i + 1}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => onLevelTap(level),
        );
      },
    );
  }
}

// ── Category Tile ────────────────────────────────────────────────────────────

class _CategoryTile extends StatelessWidget {
  final Category category;
  final VoidCallback onTap;
  final bool muted;

  const _CategoryTile({
    required this.category,
    required this.onTap,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: muted
              ? theme.colorScheme.surfaceContainerHighest
              : theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.leaderboard_rounded,
          size: 20,
          color: muted
              ? theme.colorScheme.onSurfaceVariant
              : theme.colorScheme.onPrimaryContainer,
        ),
      ),
      title: Text(
        category.name,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: muted ? theme.colorScheme.onSurfaceVariant : null,
        ),
      ),
      subtitle: category.rules != null
          ? Text(
              category.rules!.replaceAll('\n', ' ').trim(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}

// ── Level Categories Sheet ───────────────────────────────────────────────────

class _LevelCategoriesSheet extends StatefulWidget {
  final SpeedrunApiService api;
  final Game game;
  final String levelId;
  final String levelName;
  final void Function(Category) onCategoryTap;

  const _LevelCategoriesSheet({
    required this.api,
    required this.game,
    required this.levelId,
    required this.levelName,
    required this.onCategoryTap,
  });

  @override
  State<_LevelCategoriesSheet> createState() => _LevelCategoriesSheetState();
}

class _LevelCategoriesSheetState extends State<_LevelCategoriesSheet> {
  List<Category>? _categories;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final cats = await widget.api.getLevelCategories(widget.levelId);
      if (mounted) setState(() => _categories = cats);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, sc) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              widget.levelName,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const ShimmerList(count: 4)
                : _error != null
                    ? ErrorView(message: _error)
                    : _categories == null || _categories!.isEmpty
                        ? const EmptyView(icon: Icons.category_rounded)
                        : ListView.builder(
                            controller: sc,
                            itemCount: _categories!.length,
                            itemBuilder: (_, i) => ListTile(
                              leading: const Icon(Icons.leaderboard_rounded),
                              title: Text(_categories![i].name),
                              trailing:
                                  const Icon(Icons.chevron_right_rounded),
                              onTap: () =>
                                  widget.onCategoryTap(_categories![i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

// ── Tab bar delegate ─────────────────────────────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color background;

  _TabBarDelegate(this.tabBar, this.background);

  @override
  Widget build(_, double shrinkOffset, bool overlapsContent) => Material(
        color: background,
        child: tabBar,
      );

  @override
  double get maxExtent => tabBar.preferredSize.height;
  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  bool shouldRebuild(_TabBarDelegate old) => old.tabBar != tabBar;
}