import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/game.dart';
import '../../models/player.dart';
import '../../services/speedrun_api.dart';
import '../../widgets/game_card.dart';
import '../../widgets/shared_widgets.dart';
import '../leaderboard/game_detail_screen.dart';
import '../profile/profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final _api = SpeedrunApiService();
  final _searchController = TextEditingController();
  late TabController _tabController;

  List<Game> _gameResults = [];
  List<Player> _playerResults = [];
  bool _loadingGames = false;
  bool _loadingPlayers = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_onChanged);
  }

  void _onChanged() {
    final q = _searchController.text.trim();
    if (q == _query) return;
    _query = q;
    if (q.length < 2) {
      setState(() {
        _gameResults = [];
        _playerResults = [];
      });
      return;
    }
    _search(q);
  }

  Future<void> _search(String q) async {
    setState(() {
      _loadingGames = true;
      _loadingPlayers = true;
    });

    await Future.wait([
      _api.searchGames(q, max: 20).then((r) {
        if (mounted && q == _query) {
          setState(() => _gameResults = _sortByRelevance(r, q));
        }
      }).catchError((_) {}).whenComplete(() {
        if (mounted) setState(() => _loadingGames = false);
      }),
      _api.searchUsers(q).then((r) {
        if (mounted && q == _query) setState(() => _playerResults = r);
      }).catchError((_) {}).whenComplete(() {
        if (mounted) setState(() => _loadingPlayers = false);
      }),
    ]);
  }

  List<Game> _sortByRelevance(List<Game> games, String query) {
    final q = query.toLowerCase().trim();
    int score(Game g) {
      final name = g.name.toLowerCase();
      if (name == q) return 3;
      if (name.startsWith(q)) return 2;
      if (name.contains(q)) return 1;
      return 0;
    }
    return games..sort((a, b) => score(b).compareTo(score(a)));
  }

  void _openGame(Game game) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => GameDetailScreen(game: game)));
  }

  void _openPlayer(Player player) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => ProfileScreen(initialUser: player)));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final hasQuery = _query.isNotEmpty;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            pinned: true,
            title: Text(
              l.t('search_title'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: SearchBar(
                controller: _searchController,
                hintText: l.t('search_hint_games'),
                leading: const Icon(Icons.search_rounded),
                autoFocus: false,
                trailing: [
                  if (hasQuery)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _query = '';
                          _gameResults = [];
                          _playerResults = [];
                        });
                      },
                    ),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabDelegate(
              TabBar(
                controller: _tabController,
                tabs: [
                  Tab(
                    icon: const Icon(Icons.videogame_asset_rounded),
                    text: l.t('search_games'),
                  ),
                  Tab(
                    icon: const Icon(Icons.person_search_rounded),
                    text: l.t('search_players'),
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
            // ── Games ────────────────────────────────────────────────────
            _GamesTab(
              query: _query,
              games: _gameResults,
              loading: _loadingGames,
              onTap: _openGame,
              l: l,
            ),
            // ── Players ──────────────────────────────────────────────────
            _PlayersTab(
              query: _query,
              players: _playerResults,
              loading: _loadingPlayers,
              onTap: _openPlayer,
              l: l,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Games tab ────────────────────────────────────────────────────────────────

class _GamesTab extends StatelessWidget {
  final String query;
  final List<Game> games;
  final bool loading;
  final void Function(Game) onTap;
  final dynamic l;

  const _GamesTab({
    required this.query,
    required this.games,
    required this.loading,
    required this.onTap,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return EmptyView(
        message: l.t('search_start'),
        icon: Icons.search_rounded,
      );
    }
    if (loading) return const ShimmerList(count: 8);
    if (games.isEmpty) {
      return EmptyView(
        message: l.t('search_empty'),
        icon: Icons.videogame_asset_off_rounded,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: games.length,
      itemBuilder: (_, i) => GameListTile(
        game: games[i],
        onTap: () => onTap(games[i]),
      ),
    );
  }
}

// ── Players tab ──────────────────────────────────────────────────────────────

class _PlayersTab extends StatelessWidget {
  final String query;
  final List<Player> players;
  final bool loading;
  final void Function(Player) onTap;
  final dynamic l;

  const _PlayersTab({
    required this.query,
    required this.players,
    required this.loading,
    required this.onTap,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (query.isEmpty) {
      return EmptyView(
        message: l.t('search_start'),
        icon: Icons.search_rounded,
      );
    }
    if (loading) return const ShimmerList(count: 8);
    if (players.isEmpty) {
      return EmptyView(
        message: l.t('search_empty'),
        icon: Icons.person_off_rounded,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: players.length,
      itemBuilder: (_, i) {
        final player = players[i];
        return ListTile(
          onTap: () => onTap(player),
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            backgroundImage: player.avatarUrl != null
                ? NetworkImage(player.avatarUrl!)
                : null,
            child: player.avatarUrl == null
                ? Text(
                    player.name.isNotEmpty
                        ? player.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          title: Text(
            player.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: player.country != null
              ? Text(
                  player.country!.toUpperCase(),
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                )
              : null,
          trailing: const Icon(Icons.chevron_right_rounded),
        );
      },
    );
  }
}

class _TabDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tab;
  final Color bg;
  _TabDelegate(this.tab, this.bg);
  @override
  Widget build(_, __, ___) => Material(color: bg, child: tab);
  @override
  double get maxExtent => tab.preferredSize.height;
  @override
  double get minExtent => tab.preferredSize.height;
  @override
  bool shouldRebuild(_TabDelegate old) => false;
}