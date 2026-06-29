import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/update_service.dart';
import '../../widgets/update_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '—';
  bool _checkingUpdate = false;
  bool _editingKey = false;
  final _keyController = TextEditingController();
  bool _keyVisible = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _version = '${info.version}+${info.buildNumber}');
    }
  }

  Future<void> _checkUpdate() async {
    setState(() => _checkingUpdate = true);
    final release = await UpdateService().checkForUpdate();
    if (!mounted) return;
    setState(() => _checkingUpdate = false);
    if (release != null) {
      showDialog(context: context, builder: (_) => UpdateDialog(release: release));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('You are up to date ✓'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _saveApiKey() async {
    final auth = context.read<AuthProvider>();
    await auth.setApiKey(_keyController.text.trim());
    setState(() => _editingKey = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.isAuthenticated
              ? 'API key saved ✓'
              : 'API key removed'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _openApiPage() async {
    final uri = Uri.parse('https://www.speedrun.com/settings/api');
    if (await canLaunchUrl(uri)) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final settings = context.watch<SettingsProvider>();
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: Text(l.t('settings_title'),
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          SliverList.list(
            children: [

              // ── Account ──────────────────────────────────────────────────
              _SectionTitle(title: 'Account'),

              // API Key tile
              if (!_editingKey)
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: auth.isAuthenticated
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      auth.isAuthenticated
                          ? Icons.vpn_key_rounded
                          : Icons.vpn_key_off_rounded,
                      size: 20,
                      color: auth.isAuthenticated
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  title: Text(
                    auth.isAuthenticated ? 'API Key connected' : 'No API Key',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: auth.isAuthenticated
                          ? theme.colorScheme.primary
                          : null,
                    ),
                  ),
                  subtitle: Text(
                    auth.isAuthenticated
                        ? '${auth.apiKey!.substring(0, 8)}••••••••••••'
                        : 'Connect to unlock personal stats & mod tools',
                    style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (auth.isAuthenticated)
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded),
                          onPressed: () async {
                            await auth.setApiKey(null);
                          },
                          tooltip: 'Remove',
                          color: theme.colorScheme.error,
                        ),
                      FilledButton.tonal(
                        onPressed: () {
                          _keyController.text = auth.apiKey ?? '';
                          setState(() => _editingKey = true);
                        },
                        child: Text(auth.isAuthenticated ? 'Change' : 'Add'),
                      ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _keyController,
                        obscureText: !_keyVisible,
                        decoration: InputDecoration(
                          labelText: 'API Key',
                          hintText: 'Your speedrun.com API key',
                          prefixIcon: const Icon(Icons.vpn_key_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(_keyVisible
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded),
                            onPressed: () =>
                                setState(() => _keyVisible = !_keyVisible),
                          ),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          filled: true,
                        ),
                        autofocus: true,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  setState(() => _editingKey = false),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: _saveApiKey,
                              child: const Text('Save'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      TextButton.icon(
                        icon: const Icon(Icons.open_in_browser_rounded,
                            size: 14),
                        label: const Text(
                            'Get your key at speedrun.com/settings/api',
                            style: TextStyle(fontSize: 12)),
                        onPressed: _openApiPage,
                        style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact),
                      ),
                    ],
                  ),
                ),

              if (auth.isAuthenticated)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: theme.colorScheme.primary, size: 16),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Authenticated — personal profile, mod tools and run management unlocked.',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer),
                        ),
                      ),
                    ],
                  ),
                ),

              const Divider(height: 24),

              // ── Appearance ───────────────────────────────────────────────
              _SectionTitle(title: l.t('settings_appearance')),

              _SettingsTile(
                icon: Icons.language_rounded,
                title: l.t('settings_language'),
                trailing: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'en', label: Text('EN')),
                    ButtonSegment(value: 'fr', label: Text('FR')),
                  ],
                  selected: {settings.locale.languageCode},
                  onSelectionChanged: (s) =>
                      settings.setLocale(Locale(s.first)),
                  style: const ButtonStyle(
                      visualDensity: VisualDensity.compact),
                ),
              ),

              _SettingsTile(
                icon: Icons.palette_rounded,
                title: l.t('settings_theme'),
                trailing: SegmentedButton<ThemeMode>(
                  segments: [
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: const Icon(Icons.brightness_auto_rounded),
                      tooltip: l.t('settings_theme_system'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: const Icon(Icons.light_mode_rounded),
                      tooltip: l.t('settings_theme_light'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: const Icon(Icons.dark_mode_rounded),
                      tooltip: l.t('settings_theme_dark'),
                    ),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (s) =>
                      settings.setThemeMode(s.first),
                  style: const ButtonStyle(
                      visualDensity: VisualDensity.compact),
                ),
              ),

              SwitchListTile(
                secondary: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.colorize_rounded,
                      size: 20,
                      color: theme.colorScheme.onSecondaryContainer),
                ),
                title: const Text('Material You'),
                subtitle: Text('Use wallpaper colors',
                    style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12)),
                value: settings.useDynamicColor,
                onChanged: settings.setUseDynamicColor,
              ),

              const Divider(height: 24),

              // ── Updates ──────────────────────────────────────────────────
              _SectionTitle(title: 'Updates'),

              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.system_update_rounded,
                      size: 20,
                      color: theme.colorScheme.onTertiaryContainer),
                ),
                title: const Text('Check for updates'),
                subtitle: Text('${l.t('settings_version')} $_version',
                    style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant)),
                trailing: _checkingUpdate
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : FilledButton.tonal(
                        onPressed: _checkUpdate,
                        child: const Text('Check'),
                      ),
              ),

              const Divider(height: 24),

              // ── About ────────────────────────────────────────────────────
              _SectionTitle(title: l.t('settings_about')),

              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.tertiary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.speed_rounded,
                      color: theme.colorScheme.onPrimary),
                ),
                title: const Text('Pace',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18)),
                subtitle: Text('${l.t('settings_version')} $_version',
                    style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant)),
              ),

              _InfoTile(
                icon: Icons.api_rounded,
                title: l.t('settings_source'),
                subtitle: l.t('settings_source_desc'),
              ),

              _InfoTile(
                icon: Icons.info_outline_rounded,
                title: l.t('settings_about_app'),
                subtitle:
                    'Pace is an unofficial speedrun leaderboard viewer. '
                    'Data provided by the public speedrun.com API.',
              ),

              const SizedBox(height: 80),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget trailing;

  const _SettingsTile(
      {required this.icon, required this.title, required this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                size: 20,
                color: theme.colorScheme.onSecondaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text(title, style: theme.textTheme.bodyLarge)),
          trailing,
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoTile(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            size: 20, color: theme.colorScheme.onSurfaceVariant),
      ),
      title: Text(title),
      subtitle: Text(subtitle,
          style:
              TextStyle(color: theme.colorScheme.onSurfaceVariant)),
      isThreeLine: subtitle.length > 60,
    );
  }
}