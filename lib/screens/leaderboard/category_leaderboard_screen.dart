import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../models/category.dart';
import '../../models/game.dart';
import '../../models/leaderboard.dart';
import '../../models/variable.dart';
import '../../services/speedrun_api.dart';
import '../../widgets/leaderboard_entry_tile.dart';
import '../../widgets/shared_widgets.dart';
import '../../core/utils.dart';

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
    extends State<CategoryLeaderboardScreen> {
  final _api = SpeedrunApiService();

  Leaderboard? _leaderboard;
  List<Variable> _variables = [];
  final Map<String, String> _selectedVars = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVariables();
  }

  Future<void> _loadVariables() async {
    try {
      final vars = await _api.getCategoryVariables(widget.category.id);
      final subcategoryVars = vars.where((v) => v.isSubcategory).toList();
      setState(() => _variables = subcategoryVars);

      // Set defaults
      for (final v in subcategoryVars) {
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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      Leaderboard lb;
      if (widget.levelId != null) {
        lb = await _api.getLevelLeaderboard(
          widget.game.id,
          widget.levelId!,
          widget.category.id,
        );
      } else {
        lb = await _api.getLeaderboard(
          widget.game.id,
          widget.category.id,
          variables: _selectedVars.isNotEmpty ? _selectedVars : null,
        );
      }
      if (mounted) setState(() => _leaderboard = lb);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onVarChanged(String varId, String valueId) {
    setState(() => _selectedVars[varId] = valueId);
    _loadLeaderboard();
  }

  Future<void> _openVideo(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final title = widget.levelName != null
        ? '${widget.levelName} — ${widget.category.name}'
        : widget.category.name;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadLeaderboard,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style:
                          const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(
                    widget.game.name,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _loadLeaderboard,
                ),
              ],
            ),

            // Sub-category filters
            if (_variables.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _variables.map((v) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(v.name,
                              style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                          const SizedBox(height: 6),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: v.values.values.map((val) {
                                final selected = _selectedVars[v.id] == val.id;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: Text(val.label),
                                    selected: selected,
                                    onSelected: (_) =>
                                        _onVarChanged(v.id, val.id),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),

            // Summary row
            if (_leaderboard != null && !_loading)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Row(
                    children: [
                      Icon(Icons.leaderboard_rounded,
                          size: 16,
                          color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        '${_leaderboard!.runs.length} runs',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
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

            // Content
            if (_error != null)
              SliverToBoxAdapter(
                child: ErrorView(message: _error, onRetry: _loadLeaderboard),
              )
            else if (_loading)
              const SliverToBoxAdapter(child: ShimmerList(count: 10))
            else if (_leaderboard == null || _leaderboard!.runs.isEmpty)
              SliverToBoxAdapter(
                child:
                    EmptyView(message: l.t('lb_no_runs'),
                        icon: Icons.sports_score_rounded),
              )
            else
              SliverList.separated(
                itemCount: _leaderboard!.runs.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 16, endIndent: 16),
                itemBuilder: (_, i) {
                  final entry = _leaderboard!.runs[i];
                  return LeaderboardEntryTile(
                    entry: entry,
                    onTap: entry.run.videoUrl != null
                        ? () => _openVideo(entry.run.videoUrl!)
                        : null,
                  );
                },
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}
