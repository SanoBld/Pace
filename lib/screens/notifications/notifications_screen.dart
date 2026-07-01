import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/notification.dart';
import '../../providers/auth_provider.dart';
import '../../services/speedrun_api.dart';
import '../../widgets/shared_widgets.dart';
import '../../core/utils.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final SpeedrunApiService _api;
  List<AppNotification>? _notifications;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _api = SpeedrunApiService(apiKey: auth.apiKey);
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final notifs = await _api.getNotifications(max: 30);
      if (mounted) setState(() => _notifications = notifs);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(AppNotification n) async {
    if (n.itemUrl == null) return;
    final uri = Uri.parse(n.itemUrl!);
    if (await canLaunchUrl(uri)) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              title: const Text('Notifications',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _load,
                ),
              ],
            ),
            if (_error != null)
              SliverToBoxAdapter(
                child: ErrorView(message: _error, onRetry: _load),
              )
            else if (_loading)
              const SliverToBoxAdapter(child: ShimmerList(count: 8))
            else if (_notifications == null || _notifications!.isEmpty)
              const SliverToBoxAdapter(
                child: EmptyView(
                  message: 'No notifications',
                  icon: Icons.notifications_none_rounded,
                ),
              )
            else
              SliverList.separated(
                itemCount: _notifications!.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 16, endIndent: 16),
                itemBuilder: (_, i) {
                  final n = _notifications![i];
                  return ListTile(
                    onTap: n.itemUrl != null ? () => _open(n) : null,
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: n.read
                            ? theme.colorScheme.surfaceContainerHighest
                            : theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        switch (n.itemType) {
                          'run' => Icons.sports_score_rounded,
                          'comment' => Icons.comment_rounded,
                          'game' => Icons.videogame_asset_rounded,
                          _ => Icons.notifications_rounded,
                        },
                        size: 18,
                        color: n.read
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    title: Text(
                      n.text,
                      style: TextStyle(
                        fontWeight:
                            n.read ? FontWeight.normal : FontWeight.w600,
                      ),
                    ),
                    subtitle: n.date != null
                        ? Text(AppUtils.formatDate(n.date))
                        : null,
                    trailing: !n.read
                        ? Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
                  );
                },
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}
