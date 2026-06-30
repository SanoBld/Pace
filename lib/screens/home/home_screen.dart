import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/run.dart';
import '../../models/game.dart';
import '../../models/player.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/speedrun_api.dart';
import '../../widgets/run_tile.dart';
import '../../widgets/game_card.dart';
import '../../widgets/shared_widgets.dart';
import '../leaderboard/game_detail_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';
import '../notifications/notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final SpeedrunApiService _api;
  List<Run>? _recentRuns;
  List<Game>? _activeGames;
  String? _runsError;
  String? _gamesError;
  bool _loadingRuns = true;
  bool _loadingGames = true;
  int? _unreadCount;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _api = SpeedrunApiService(apiKey: auth.apiKey);
    _loadRecentRuns();
    _loadActiveGames();
    if (auth.isAuthenticated) _loadNotifCount();
  }

  Future<void> _loadRecentRuns() async {
    if (mounted) setState(() { _loadingRuns = true; _runsError = null; });
    try {
      final runs = await _api.getRecentRuns(max: 10);
      if (mounted) setState(() => _recentRuns = runs);
    } catch (e) {
      if (mounted) setState(() => _runsError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingRuns = false);
    }
  }

  Future<void> _loadActiveGames() async {
    if (mounted) setState(() { _loadingGames = true; _gamesError = null; });
    try {
      final games = await _api.getActiveGames(max: 12);
      if (mounted) setState(() => _activeGames = games);
    } catch (e) {
      if (mounted) setState(() => _gamesError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingGames = false);
    }
  }

  Future<void> _loadNotifCount() async {
    try {
      final notifs = await _api.getNotifications(max: 30);
      final unread = notifs.where((n) => !n.read).length;
      if (mounted) setState(() => _unreadCount = unread);
    } catch (_) {}
  }

  void _openGame(Game game) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => GameDetailScreen(game: game)));

  void _openPlayer(Player player) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => ProfileScreen(initialUser: player)));

  void _openSettings() => Navigator.push(
      context, MaterialPageRoute(builder: (_) => const SettingsScreen()));

  void _openNotifications() => Navigator.push(
      context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))
      .then((_) => _loadNotifCount());

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final favs = context.watch<FavoritesProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([_loadRecentRuns(), _loadActiveGames()]);
          if (auth.isAuthenticated) _loadNotifCount();
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              title: Row(
                children: [
                  Icon(Icons.speed_rounded,
                      color: theme.colorScheme.primary, size: 22),
                  const SizedBox(width: 8),
                  Text(l.t('home_title'),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              actions: [
                if (auth.isAuthenticated)
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        tooltip: 'Notifications',
                        onPressed: _openNotifications,
                      ),
                      if (_unreadCount != null && _unreadCount! > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  tooltip: 'Settings',
                  onPressed: _openSettings,
                ),
              ],
            ),

            // ── Favorites ─────────────────────────────────────────────
            if (favs.favorites.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: _SectionHeader(
                  icon: Icons.favorite_rounded,
                  iconColor: Colors.redAccent,
                  title: 'Favorites',
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 172,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    itemCount: favs.favorites.length,
                    itemBuilder: (_, i) => SizedBox(
                      width: 90,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: GameCard(
                          game: favs.favorites[i],
                          onTap: () => _openGame(favs.favorites[i]),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                  child: Divider(height: 8, indent: 16, endIndent: 16)),
            ],

            // ── Recent Runs ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: _SectionHeader(
                icon: Icons.history_rounded,
                title: l.t('home_recent_runs'),
              ),
            ),
            if (_runsError != null)
              SliverToBoxAdapter(
                child: _InlineError(
                    message: _runsError!, onRetry: _loadRecentRuns),
              )
            else if (_loadingRuns)
              const SliverToBoxAdapter(child: ShimmerList(count: 5))
            else if (_recentRuns == null || _recentRuns!.isEmpty)
              SliverToBoxAdapter(
                child: EmptyView(
                    message: l.t('home_empty'),
                    icon: Icons.sports_score_rounded),
              )
            else
              SliverList.builder(
                itemCount: _recentRuns!.length,
                itemBuilder: (_, i) {
                  final run = _recentRuns![i];
                  return RunTile(
                    run: run,
                    showGame: true,
                    onTap: run.gameId != null
                        ? () => _openGame(Game(
                              id: run.gameId!,
                              name: run.gameName ?? run.gameId!,
                            ))
                        : null,
                    onPlayerTap: run.players.isNotEmpty
                        ? () => _openPlayer(run.players.first)
                        : null,
                  );
                },
              ),

            // ── Active Games ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: _SectionHeader(
                icon: Icons.trending_up_rounded,
                title: l.t('home_trending'),
              ),
            ),
            if (_gamesError != null)
              SliverToBoxAdapter(
                child: _InlineError(
                    message: _gamesError!, onRetry: _loadActiveGames),
              )
            else if (_loadingGames)
              const SliverToBoxAdapter(child: ShimmerGrid(count: 6))
            else if (_activeGames != null && _activeGames!.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => GameCard(
                      game: _activeGames![i],
                      onTap: () => _openGame(_activeGames![i]),
                    ),
                    childCount: _activeGames!.length,
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

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? iconColor;
  const _SectionHeader(
      {required this.title, required this.icon, this.iconColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(icon,
              size: 18, color: iconColor ?? theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _InlineError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: theme.colorScheme.error, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: onRetry,
              style:
                  TextButton.styleFrom(visualDensity: VisualDensity.compact),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}