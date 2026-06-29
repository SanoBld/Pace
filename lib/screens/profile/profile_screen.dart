import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../models/player.dart';
import '../../models/variable.dart';
import '../../providers/auth_provider.dart';
import '../../services/speedrun_api.dart';
import '../../widgets/shared_widgets.dart';
import '../../core/utils.dart';

class ProfileScreen extends StatefulWidget {
  final Player? initialUser;
  const ProfileScreen({super.key, this.initialUser});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final SpeedrunApiService _api;
  final _searchController = TextEditingController();
  late TabController _tabController;

  Player? _user;
  List<PersonalBest>? _pbs;
  List<dynamic>? _myRuns; // authenticated user's submitted runs
  bool _loadingUser = false;
  bool _loadingPbs = false;
  bool _loadingRuns = false;
  String? _userError;
  String? _pbsError;

  bool get _isDirectProfile => widget.initialUser != null;
  bool get _isOwnProfile {
    final auth = context.read<AuthProvider>();
    return !_isDirectProfile && auth.isAuthenticated;
  }

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _api = SpeedrunApiService(apiKey: auth.apiKey);
    _tabController = TabController(
      length: _isDirectProfile ? 1 : (auth.isAuthenticated ? 2 : 1),
      vsync: this,
    );

    if (widget.initialUser != null) {
      _user = widget.initialUser;
      _loadFull(widget.initialUser!.id);
    } else if (auth.isAuthenticated) {
      _loadAuthenticatedUser();
    }
  }

  Future<void> _loadAuthenticatedUser() async {
    setState(() { _loadingUser = true; _userError = null; });
    try {
      final user = await _api.getProfile();
      if (mounted) {
        setState(() { _user = user; _loadingUser = false; });
        context.read<AuthProvider>().setCurrentUser(user);
        _loadPbs(user.id);
      }
    } catch (e) {
      if (mounted) setState(() { _userError = e.toString(); _loadingUser = false; });
    }
  }

  Future<void> _loadFull(String userId) async {
    setState(() { _loadingUser = true; _userError = null; });
    try {
      final user = await _api.getUser(userId);
      if (mounted) {
        setState(() { _user = user; _loadingUser = false; });
        _loadPbs(userId);
      }
    } catch (e) {
      if (mounted) setState(() { _userError = e.toString(); _loadingUser = false; });
    }
  }

  Future<void> _search() async {
    final q = _searchController.text.trim();
    if (q.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() { _loadingUser = true; _userError = null; _pbs = null; });
    try {
      final user = await _api.getUser(q);
      if (mounted) {
        setState(() { _user = user; _loadingUser = false; });
        _loadPbs(user.id);
      }
    } catch (e) {
      if (mounted) setState(() { _userError = e.toString(); _loadingUser = false; });
    }
  }

  Future<void> _loadPbs(String userId) async {
    setState(() { _loadingPbs = true; _pbsError = null; });
    try {
      final pbs = await _api.getUserPersonalBests(userId);
      pbs.sort((a, b) => a.place.compareTo(b.place));
      if (mounted) setState(() => _pbs = pbs);
    } catch (e) {
      if (mounted) setState(() => _pbsError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingPbs = false);
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
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
    final auth = context.watch<AuthProvider>();
    final showTabs = !_isDirectProfile && auth.isAuthenticated;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            pinned: true,
            title: Text(
              _isDirectProfile
                  ? (_user?.name ?? l.t('profile_title'))
                  : l.t('profile_title'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            bottom: showTabs
                ? TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(icon: Icon(Icons.person_rounded), text: 'Profile'),
                      Tab(icon: Icon(Icons.videogame_asset_rounded), text: 'My Runs'),
                    ],
                  )
                : (_loadingUser
                    ? const PreferredSize(
                        preferredSize: Size.fromHeight(2),
                        child: LinearProgressIndicator(),
                      )
                    : null),
          ),

          // Search bar — only on standalone Profile tab (not direct or auth)
          if (!_isDirectProfile && !auth.isAuthenticated)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: l.t('profile_hint'),
                          prefixIcon: const Icon(Icons.person_search_rounded),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14)),
                          filled: true,
                        ),
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _search(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: _loadingUser ? null : _search,
                      child: Text(l.t('profile_search_btn')),
                    ),
                  ],
                ),
              ),
            ),

          // Search bar for direct profile — allow searching other users
          if (_isDirectProfile)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search another player…',
                          prefixIcon: const Icon(Icons.search_rounded),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          isDense: true,
                        ),
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _search(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      icon: const Icon(Icons.search_rounded),
                      onPressed: _search,
                    ),
                  ],
                ),
              ),
            ),
        ],
        body: showTabs
            ? TabBarView(
                controller: _tabController,
                children: [
                  _ProfileTab(
                    user: _user,
                    pbs: _pbs,
                    loadingUser: _loadingUser,
                    loadingPbs: _loadingPbs,
                    userError: _userError,
                    pbsError: _pbsError,
                    onReloadPbs: () => _user != null ? _loadPbs(_user!.id) : null,
                    onOpenUrl: _openUrl,
                    l: l,
                  ),
                  _MyRunsTab(api: _api, l: l),
                ],
              )
            : _ProfileTab(
                user: _user,
                pbs: _pbs,
                loadingUser: _loadingUser,
                loadingPbs: _loadingPbs,
                userError: _userError,
                pbsError: _pbsError,
                onReloadPbs: () => _user != null ? _loadPbs(_user!.id) : null,
                onOpenUrl: _openUrl,
                l: l,
              ),
      ),
    );
  }
}

// ── Profile tab ───────────────────────────────────────────────────────────────

class _ProfileTab extends StatelessWidget {
  final Player? user;
  final List<PersonalBest>? pbs;
  final bool loadingUser;
  final bool loadingPbs;
  final String? userError;
  final String? pbsError;
  final VoidCallback? onReloadPbs;
  final Future<void> Function(String) onOpenUrl;
  final dynamic l;

  const _ProfileTab({
    required this.user,
    required this.pbs,
    required this.loadingUser,
    required this.loadingPbs,
    required this.userError,
    required this.pbsError,
    required this.onReloadPbs,
    required this.onOpenUrl,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    if (userError != null) return ErrorView(message: userError);

    return CustomScrollView(
      slivers: [
        if (user != null) ...[
          SliverToBoxAdapter(
            child: _UserHeader(user: user!, onOpenUrl: onOpenUrl, l: l),
          ),
          const SliverToBoxAdapter(child: Divider()),
          SliverToBoxAdapter(
            child: SectionHeader(title: l.t('profile_pbs')),
          ),
          if (loadingPbs)
            const SliverToBoxAdapter(child: ShimmerList(count: 6))
          else if (pbsError != null)
            SliverToBoxAdapter(
              child: ErrorView(message: pbsError, onRetry: onReloadPbs),
            )
          else if (pbs == null || pbs!.isEmpty)
            SliverToBoxAdapter(
              child: EmptyView(
                message: l.t('profile_no_pbs'),
                icon: Icons.emoji_events_rounded,
              ),
            )
          else
            SliverList.separated(
              itemCount: pbs!.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 72),
              itemBuilder: (_, i) => _PbTile(pb: pbs![i]),
            ),
        ] else if (!loadingUser)
          SliverToBoxAdapter(
            child: EmptyView(
              message: l.t('profile_enter_user'),
              icon: Icons.person_rounded,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

// ── My Runs tab (authenticated) ───────────────────────────────────────────────

class _MyRunsTab extends StatefulWidget {
  final SpeedrunApiService api;
  final dynamic l;
  const _MyRunsTab({required this.api, required this.l});

  @override
  State<_MyRunsTab> createState() => _MyRunsTabState();
}

class _MyRunsTabState extends State<_MyRunsTab> {
  List<dynamic>? _runs;
  bool _loading = true;
  String? _error;
  String _statusFilter = 'verified';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final runs = await widget.api.getMyRuns(
        status: _statusFilter == 'all' ? null : _statusFilter,
        max: 50,
      );
      if (mounted) setState(() => _runs = runs);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                for (final s in ['verified', 'new', 'rejected', 'all'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(s == 'new' ? 'pending' : s),
                      selected: _statusFilter == s,
                      onSelected: (_) {
                        setState(() => _statusFilter = s);
                        _load();
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (_error != null)
          SliverToBoxAdapter(child: ErrorView(message: _error, onRetry: _load))
        else if (_loading)
          const SliverToBoxAdapter(child: ShimmerList(count: 8))
        else if (_runs == null || _runs!.isEmpty)
          SliverToBoxAdapter(
            child: EmptyView(
              message: 'No ${_statusFilter == 'new' ? 'pending' : _statusFilter} runs',
              icon: Icons.sports_score_rounded,
            ),
          )
        else
          SliverList.separated(
            itemCount: _runs!.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 16, endIndent: 16),
            itemBuilder: (_, i) => _RunRow(run: _runs![i]),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

class _RunRow extends StatelessWidget {
  final dynamic run;
  const _RunRow({required this.run});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = run.status ?? 'unknown';
    final statusColor = switch (status) {
      'verified' => Colors.green,
      'rejected' => theme.colorScheme.error,
      _ => theme.colorScheme.tertiary,
    };

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          switch (status) {
            'verified' => Icons.check_circle_rounded,
            'rejected' => Icons.cancel_rounded,
            _ => Icons.schedule_rounded,
          },
          color: statusColor,
          size: 20,
        ),
      ),
      title: Text(
        run.gameName ?? run.gameId ?? '—',
        style: const TextStyle(fontWeight: FontWeight.bold),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${run.categoryName ?? '—'} • ${AppUtils.formatDate(run.date)}',
        style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          AppUtils.formatTime(run.primaryTime),
          style: TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _UserHeader extends StatelessWidget {
  final Player user;
  final Future<void> Function(String) onOpenUrl;
  final dynamic l;

  const _UserHeader(
      {required this.user, required this.onOpenUrl, required this.l});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: theme.colorScheme.primaryContainer,
            backgroundImage: user.avatarUrl != null
                ? CachedNetworkImageProvider(user.avatarUrl!)
                : null,
            child: user.avatarUrl == null
                ? Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                if (user.pronouns != null && user.pronouns!.isNotEmpty)
                  Text(user.pronouns!,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                if (user.country != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(children: [
                      Icon(Icons.flag_rounded,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(user.country!.toUpperCase(),
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ]),
                  ),
                if (user.signupDate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${l.t('profile_signed_up')}: ${AppUtils.formatDate(user.signupDate?.substring(0, 10))}',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (user.socials['twitch'] != null)
                      _SocialChip(
                          label: 'Twitch',
                          icon: Icons.live_tv_rounded,
                          onTap: () => onOpenUrl(user.socials['twitch']!)),
                    if (user.socials['youtube'] != null)
                      _SocialChip(
                          label: 'YouTube',
                          icon: Icons.play_circle_rounded,
                          onTap: () => onOpenUrl(user.socials['youtube']!)),
                    if (user.socials['twitter'] != null)
                      _SocialChip(
                          label: 'Twitter',
                          icon: Icons.tag_rounded,
                          onTap: () => onOpenUrl(user.socials['twitter']!)),
                    if (user.weblink != null)
                      _SocialChip(
                          label: 'speedrun.com',
                          icon: Icons.open_in_browser_rounded,
                          onTap: () => onOpenUrl(user.weblink!)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _SocialChip({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => ActionChip(
        avatar: Icon(icon, size: 14),
        label: Text(label),
        onPressed: onTap,
        visualDensity: VisualDensity.compact,
      );
}

class _PbTile extends StatelessWidget {
  final PersonalBest pb;
  const _PbTile({required this.pb});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTop3 = pb.place <= 3;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: isTop3
                ? Text(AppUtils.rankEmoji(pb.place),
                    style: const TextStyle(fontSize: 22),
                    textAlign: TextAlign.center)
                : Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('#${pb.place}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pb.gameName ?? '—',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(pb.categoryName ?? '—',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.primary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (pb.date != null)
                  Text(AppUtils.formatDate(pb.date),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      )),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isTop3
                  ? Color(AppUtils.rankColor(pb.place)).withOpacity(0.15)
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: isTop3
                  ? Border.all(
                      color: Color(AppUtils.rankColor(pb.place)).withOpacity(0.5))
                  : null,
            ),
            child: Text(
              AppUtils.formatTime(pb.primaryTime),
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: isTop3
                    ? Color(AppUtils.rankColor(pb.place))
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}