import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../models/category.dart';
import '../../models/game.dart';
import '../../models/leaderboard.dart';
import '../../models/variable.dart';
import '../../models/run.dart';
import '../../services/speedrun_api.dart';
import '../../widgets/leaderboard_entry_tile.dart';
import '../../widgets/wr_progression_chart.dart';
import '../../widgets/shared_widgets.dart';
import '../../core/utils.dart';
import '../../widgets/run_detail_sheet.dart';

class CategoryLeaderboardScreen extends StatefulWidget {
  final Game game;
  final Category category;
  final String? levelId;
  final String? levelName;

  const CategoryLeaderboardScreen({
    super.key,
    required this.game,
    required this.category,
    this.levelId,
    this.levelName,
  });

  @override
  State<CategoryLeaderboardScreen> createState() =>
      _CategoryLeaderboardScreenState();
}

class _CategoryLeaderboardScreenState
    extends State<CategoryLeaderboardScreen>
    with SingleTickerProviderStateMixin {
  final _api = SpeedrunApiService();
  late TabController _tabController;

  // Leaderboard state
  Leaderboard? _leaderboard;
  List<Variable> _variables = [];
  final Map<String, String> _selectedVars = {};
  bool _loadingLb = true;
  String? _lbError;
  int? _maxPlace;

  // Chart state
  List<WrPoint>? _wrPoints;
  bool _loadingChart = false;
  String? _chartError;

  static const _topFilters = [10, 25, 50, 100];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && _wrPoints == null && !_loadingChart) {
        _loadChart();
      }
    });
    _loadVariables();
  }

  Future<void> _loadVariables() async {
    try {
      final vars = await _api.getCategoryVariables(widget.category.id);
      final sub = vars.where((v) => v.isSubcategory).toList();
      setState(() => _variables = sub);
      for (final v in sub) {
        if (v.defaultValue != null) {
          _selectedVars[v.id] = v.defaultValue!;
        } else if (v.values.isNotEmpty) {
          _selectedVars[v.id] = v.values.keys.first;
        }
      }
    } catch (_) {}
    await _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() { _loadingLb = true; _lbError = null; });
    try {
      Leaderboard lb;
      if (widget.levelId != null) {
        lb = await _api.getLevelLeaderboard(
            widget.game.id, widget.levelId!, widget.category.id);
      } else {
        lb = await _api.getLeaderboard(
          widget.game.id,
          widget.category.id,
          variables: _selectedVars.isNotEmpty ? _selectedVars : null,
        );
        if (lb.runs.isEmpty && _selectedVars.isNotEmpty) {
          lb = await _api.getLeaderboard(widget.game.id, widget.category.id);
        }
      }
      if (mounted) setState(() => _leaderboard = lb);
    } catch (e) {
      if (mounted) setState(() => _lbError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingLb = false);
    }
  }

  Future<void> _loadChart() async {
    setState(() { _loadingChart = true; _chartError = null; });
    try {
      final runs = await _api.getCategoryRunHistory(
          widget.game.id, widget.category.id);
      final points = _computeWrProgression(runs);
      if (mounted) setState(() => _wrPoints = points);
    } catch (e) {
      if (mounted) setState(() => _chartError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingChart = false);
    }
  }

  List<WrPoint> _computeWrProgression(List<Run> runs) {
    double? best;
    final points = <WrPoint>[];
    for (final run in runs) {
      if (run.primaryTime == null || run.date == null) continue;
      if (best == null || run.primaryTime! < best) {
        best = run.primaryTime!;
        final name = run.players.isNotEmpty ? run.players.first.name : '?';
        try {
          points.add(WrPoint(
            date: DateTime.parse(run.date!),
            time: best,
            playerName: name,
          ));
        } catch (_) {}
      }
    }
    return points;
  }

  List<LeaderboardEntry> get _filteredRuns {
    if (_leaderboard == null) return [];
    final all = _leaderboard!.runs;
    if (_maxPlace == null) return all;
    return all.where((e) => e.place <= _maxPlace!).toList();
  }

  Future<void> _openVideo(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
    final filtered = _filteredRuns;

    final title = widget.levelName != null
        ? '${widget.levelName} — ${widget.category.name}'
        : widget.category.name;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            pinned: true,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                Text(widget.game.name,
                    style: TextStyle(
                        fontSize: 12, color: theme.colorScheme.primary)),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _loadLeaderboard,
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.leaderboard_rounded), text: 'Leaderboard'),
                Tab(icon: Icon(Icons.show_chart_rounded), text: 'WR History'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            // ── Tab 1: Leaderboard ───────────────────────────────────
            RefreshIndicator(
              onRefresh: _loadLeaderboard,
              child: CustomScrollView(
                slivers: [
                  // Subcategory filters
                  if (_variables.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _variables.map((v) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(v.name,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant)),
                              const SizedBox(height: 6),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: v.values.values.map((val) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      label: Text(val.label),
                                      selected: _selectedVars[v.id] == val.id,
                                      onSelected: (_) {
                                        setState(() => _selectedVars[v.id] = val.id);
                                        _loadLeaderboard();
                                      },
                                    ),
                                  )).toList(),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          )).toList(),
                        ),
                      ),
                    ),

                  // Top N filter
                  if (_leaderboard != null && _leaderboard!.runs.isNotEmpty)
                    SliverToBoxAdapter(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: const Text('All'),
                                selected: _maxPlace == null,
                                onSelected: (_) => setState(() => _maxPlace = null),
                              ),
                            ),
                            ..._topFilters
                                .where((n) => n < _leaderboard!.runs.length)
                                .map((n) => Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: FilterChip(
                                        label: Text('Top $n'),
                                        selected: _maxPlace == n,
                                        onSelected: (_) =>
                                            setState(() => _maxPlace = n),
                                      ),
                                    )),
                          ],
                        ),
                      ),
                    ),

                  // Summary
                  if (_leaderboard != null && !_loadingLb)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                        child: Row(
                          children: [
                            Icon(Icons.leaderboard_rounded,
                                size: 14, color: theme.colorScheme.primary),
                            const SizedBox(width: 6),
                            Text(
                              '${filtered.length} runs'
                              '${_maxPlace != null ? ' (top $_maxPlace)' : ''}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant),
                            ),
                            if (_leaderboard!.runs.isNotEmpty) ...[
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '🥇 ${AppUtils.formatTime(_leaderboard!.runs.first.run.primaryTime)}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(child: Divider(height: 1)),

                  if (_lbError != null)
                    SliverToBoxAdapter(
                      child: ErrorView(message: _lbError, onRetry: _loadLeaderboard),
                    )
                  else if (_loadingLb)
                    const SliverToBoxAdapter(child: ShimmerList(count: 10))
                  else if (filtered.isEmpty)
                    SliverToBoxAdapter(
                      child: EmptyView(
                        message: l.t('lb_no_runs'),
                        icon: Icons.sports_score_rounded,
                      ),
                    )
                  else
                    SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 16, endIndent: 16),
                      itemBuilder: (_, i) {
                        final entry = filtered[i];
                        return LeaderboardEntryTile(
                          entry: entry,
                          onTap: () => RunDetailSheet.show(context, entry),
                          onVideoTap: entry.run.videoUrl != null
                              ? () => _openVideo(entry.run.videoUrl!)
                              : null,
                        );
                      },
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),

            // ── Tab 2: WR History chart ──────────────────────────────
            Builder(builder: (_) {
              if (_loadingChart) {
                return const Center(child: CircularProgressIndicator());
              }
              if (_chartError != null) {
                return ErrorView(message: _chartError, onRetry: _loadChart);
              }
              if (_wrPoints == null) {
                return const Center(child: CircularProgressIndicator());
              }
              return SingleChildScrollView(
                child: WrProgressionChart(points: _wrPoints!),
              );
            }),
          ],
        ),
      ),
    );
  }
}
