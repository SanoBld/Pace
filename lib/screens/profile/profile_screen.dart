import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../models/player.dart';
import '../../models/variable.dart';
import '../../services/speedrun_api.dart';
import '../../widgets/shared_widgets.dart';
import '../../core/utils.dart';

class ProfileScreen extends StatefulWidget {
  final Player? initialUser;

  const ProfileScreen({super.key, this.initialUser});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _api = SpeedrunApiService();
  final _controller = TextEditingController();

  Player? _user;
  List<PersonalBest>? _pbs;
  bool _loadingUser = false;
  bool _loadingPbs = false;
  String? _userError;
  String? _pbsError;

  // True = arrived from a player tap (no search bar needed)
  bool get _isDirectProfile => widget.initialUser != null;

  @override
  void initState() {
    super.initState();
    if (widget.initialUser != null) {
      _user = widget.initialUser;
      _loadFull(widget.initialUser!.id);
    }
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loadingUser = true;
      _userError = null;
      _pbs = null;
      _pbsError = null;
    });
    try {
      final user = await _api.getUser(query);
      if (mounted) {
        setState(() { _user = user; _loadingUser = false; });
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
    _controller.dispose();
    _api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: Text(
              _isDirectProfile
                  ? (_user?.name ?? l.t('profile_title'))
                  : l.t('profile_title'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            // Loading indicator in AppBar when fetching profile
            bottom: _loadingUser
                ? const PreferredSize(
                    preferredSize: Size.fromHeight(2),
                    child: LinearProgressIndicator(),
                  )
                : null,
          ),

          // Search bar — only on the standalone Profile tab
          if (!_isDirectProfile)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: l.t('profile_hint'),
                          prefixIcon: const Icon(Icons.person_search_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
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

          if (_userError != null)
            SliverToBoxAdapter(child: ErrorView(message: _userError)),

          if (_user != null) ...[
            SliverToBoxAdapter(
              child: _UserHeader(user: _user!, l: l, onOpenUrl: _openUrl),
            ),
            const SliverToBoxAdapter(child: Divider()),
            SliverToBoxAdapter(child: SectionHeader(title: l.t('profile_pbs'))),

            if (_loadingPbs)
              const SliverToBoxAdapter(child: ShimmerList(count: 6))
            else if (_pbsError != null)
              SliverToBoxAdapter(
                child: ErrorView(
                  message: _pbsError,
                  onRetry: () => _loadPbs(_user!.id),
                ),
              )
            else if (_pbs == null || _pbs!.isEmpty)
              SliverToBoxAdapter(
                child: EmptyView(
                  message: l.t('profile_no_pbs'),
                  icon: Icons.emoji_events_rounded,
                ),
              )
            else
              SliverList.separated(
                itemCount: _pbs!.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 72),
                itemBuilder: (_, i) => _PbTile(pb: _pbs![i], l: l),
              ),
          ] else if (!_loadingUser && !_isDirectProfile)
            SliverToBoxAdapter(
              child: EmptyView(
                message: l.t('profile_enter_user'),
                icon: Icons.person_rounded,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

class _UserHeader extends StatelessWidget {
  final Player user;
  final dynamic l;
  final Future<void> Function(String) onOpenUrl;

  const _UserHeader({
    required this.user,
    required this.l,
    required this.onOpenUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
                Text(
                  user.name,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (user.pronouns != null && user.pronouns!.isNotEmpty)
                  Text(
                    user.pronouns!,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                if (user.country != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(Icons.flag_rounded,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          user.country!.toUpperCase(),
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
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

  const _SocialChip(
      {required this.label, required this.icon, required this.onTap});

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
  final dynamic l;

  const _PbTile({required this.pb, required this.l});

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
                    child: Text(
                      '#${pb.place}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pb.gameName ?? '—',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  pb.categoryName ?? '—',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.primary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (pb.date != null)
                  Text(
                    AppUtils.formatDate(pb.date),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isTop3
                  ? Color(AppUtils.rankColor(pb.place)).withOpacity(0.15)
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: isTop3
                  ? Border.all(
                      color: Color(AppUtils.rankColor(pb.place))
                          .withOpacity(0.5))
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