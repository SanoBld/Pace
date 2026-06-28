import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/game.dart';
import '../../services/speedrun_api.dart';
import '../../widgets/game_card.dart';
import '../../widgets/shared_widgets.dart';
import 'game_detail_screen.dart';

enum _SortMode { active, nameAZ, newest }

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final _api = SpeedrunApiService();
  final _searchController = TextEditingController();

  List<Game>? _games;
  List<Game>? _searchResults;
  bool _loading = true;
  bool _searching = false;
  String? _error;
  String _query = '';
  _SortMode _sortMode = _SortMode.active;

  @override
  void initState() {
    super.initState();
    _loadGames();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadGames() async {
    setState(() { _loading = true; _error = null; });
    try {
      List<Game> games;
      switch (_sortMode) {
        case _SortMode.active:
          games = await _api.getActiveGames(max: 24);
        case _SortMode.nameAZ:
          games = await _api.getPopularGames(
              max: 24, orderBy: 'name.int', direction: 'asc');
        case _SortMode.newest:
          games = await _api.getPopularGames(
              max: 24, orderBy: 'released', direction: 'desc');
      }
      if (mounted) setState(() => _games = games);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearchChanged() {
    final q = _searchController.text.trim();
    if (q == _query) return;
    _query = q;
    if (q.isEmpty) {
      setState(() { _searchResults = null; _searching = false; });
      return;
    }
    _search(q);
  }

  Future<void> _search(String q) async {
    setState(() => _searching = true);
    try {
      final results = await _api.searchGames(q, max: 20);
      if (mounted && q == _query) setState(() => _searchResults = results);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _openGame(Game game) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => GameDetailScreen(game: game)));

  @override
  void dispose() {
    _searchController.dispose();
    _api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isSearching = _searchController.text.isNotEmpty;
    final displayGames = isSearching ? (_searchResults ?? []) : (_games ?? []);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadGames,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              title: const Text('Games',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            // Search
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: SearchBar(
                  controller: _searchController,
                  hintText: l.t('search_hint_games'),
                  leading: const Icon(Icons.search_rounded),
                  trailing: [
                    if (isSearching)
                      IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() { _searchResults = null; _query = ''; });
                        },
                      ),
                  ],
                ),
              ),
            ),
            // Sort chips (only when not searching)
            if (!isSearching)
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      _SortChip(
                        label: 'Active',
                        icon: Icons.trending_up_rounded,
                        selected: _sortMode == _SortMode.active,
                        onTap: () {
                          setState(() => _sortMode = _SortMode.active);
                          _loadGames();
                        },
                      ),
                      const SizedBox(width: 8),
                      _SortChip(
                        label: 'A → Z',
                        icon: Icons.sort_by_alpha_rounded,
                        selected: _sortMode == _SortMode.nameAZ,
                        onTap: () {
                          setState(() => _sortMode = _SortMode.nameAZ);
                          _loadGames();
                        },
                      ),
                      const SizedBox(width: 8),
                      _SortChip(
                        label: 'Newest',
                        icon: Icons.new_releases_rounded,
                        selected: _sortMode == _SortMode.newest,
                        onTap: () {
                          setState(() => _sortMode = _SortMode.newest);
                          _loadGames();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            // Section label
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  isSearching ? l.t('search_games') : _sectionLabel(_sortMode),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            // Content
            if (_error != null && !isSearching)
              SliverToBoxAdapter(
                child: ErrorView(message: _error, onRetry: _loadGames),
              )
            else if (_loading && !isSearching)
              const SliverToBoxAdapter(child: ShimmerGrid(count: 9))
            else if (_searching)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
              )
            else if (displayGames.isEmpty)
              SliverToBoxAdapter(
                child: EmptyView(
                  message: l.t('search_empty'),
                  icon: Icons.videogame_asset_off_rounded,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => GameCard(
                      game: displayGames[i],
                      onTap: () => _openGame(displayGames[i]),
                    ),
                    childCount: displayGames.length,
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 3 / 5,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _sectionLabel(_SortMode mode) => switch (mode) {
        _SortMode.active => 'Active games',
        _SortMode.nameAZ => 'All games (A → Z)',
        _SortMode.newest => 'Recently released',
      };
}

class _SortChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 14,
              color: selected
                  ? theme.colorScheme.onSecondaryContainer
                  : theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}