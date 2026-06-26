import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../l10n/app_localizations.dart';
import '../../models/run.dart';
import '../../models/game.dart';
import '../../services/speedrun_api.dart';
import '../../widgets/run_tile.dart';
import '../../widgets/game_card.dart';
import '../../widgets/shared_widgets.dart';
import '../leaderboard/game_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _api = SpeedrunApiService();

  List<Run>? _recentRuns;
  List<Game>? _popularGames;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _api.getRecentRuns(max: 10),
        _api.searchGames('', max: 12),
      ]);
      if (mounted) {
        setState(() {
          _recentRuns = results[0] as List<Run>;
          _popularGames = results[1] as List<Game>;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            SliverAppBar.large(
              title: Row(
                children: [
                  Icon(
                    Icons.speed_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l.t('home_title'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _loadData,
                  tooltip: l.t('retry'),
                ),
              ],
            ),
            if (_error != null)
              SliverToBoxAdapter(
                child: ErrorView(message: _error, onRetry: _loadData),
              )
            else ...[
              // ── Recent Runs ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: SectionHeader(title: l.t('home_recent_runs')),
              ),
              if (_loading)
                const SliverToBoxAdapter(child: ShimmerList(count: 5))
              else if (_recentRuns == null || _recentRuns!.isEmpty)
                SliverToBoxAdapter(
                  child: EmptyView(
                    message: l.t('home_empty'),
                    icon: Icons.sports_score_rounded,
                  ),
                )
              else
                SliverList.builder(
                  itemCount: _recentRuns!.length,
                  itemBuilder: (_, i) => RunTile(
                    run: _recentRuns![i],
                    showGame: true,
                  ),
                ),

              // ── Popular Games ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: SectionHeader(title: l.t('home_trending')),
              ),
              if (_loading)
                const SliverToBoxAdapter(child: ShimmerGrid(count: 6))
              else if (_popularGames != null && _popularGames!.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => GameCard(
                        game: _popularGames![i],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                GameDetailScreen(game: _popularGames![i]),
                          ),
                        ),
                      ),
                      childCount: _popularGames!.length,
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
          ],
        ),
      ),
    );
  }
}
