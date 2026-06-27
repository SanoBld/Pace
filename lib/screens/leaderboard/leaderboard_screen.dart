import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/game.dart';
import '../../services/speedrun_api.dart';
import '../../widgets/game_card.dart';
import '../../widgets/shared_widgets.dart';
import 'game_detail_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadPopular();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadPopular() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final games = await _api.getPopularGames(max: 24);
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
      setState(() {
        _searchResults = null;
        _searching = false;
      });
      return;
    }
    _search(q);
  }

  Future<void> _search(String q) async {
    setState(() => _searching = true);
    try {
      final results = await _api.searchGames(q, max: 20);
      if (mounted && q == _query) {
        setState(() => _searchResults = results);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _openGame(Game game) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GameDetailScreen(game: game)),
    );
  }

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
    final displayGames =
        isSearching ? (_searchResults ?? []) : (_games ?? []);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadPopular,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              title: Text(
                l.t('lb_title'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            // Search bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
                          setState(() {
                            _searchResults = null;
                            _query = '';
                          });
                        },
                      ),
                  ],
                ),
              ),
            ),
            // Section label
            SliverToBoxAdapter(
              child: SectionHeader(
                title: isSearching
                    ? (l.t('search_games'))
                    : l.t('lb_popular'),
              ),
            ),
            // Content
            if (_error != null && !isSearching)
              SliverToBoxAdapter(
                child: ErrorView(message: _error, onRetry: _loadPopular),
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
}