import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/settings_provider.dart';
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

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _version = '${info.version}+${info.buildNumber}');
  }

  Future<void> _checkUpdate() async {
    setState(() => _checkingUpdate = true);
    final release = await UpdateService().checkForUpdate();
    if (!mounted) return;
    setState(() => _checkingUpdate = false);

    if (release != null) {
      showDialog(
        context: context,
        builder: (_) => UpdateDialog(release: release),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vous êtes à jour / You are up to date ✓'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text(
              l.t('settings_title'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SliverList.list(
            children: [
              // ── Appearance ──────────────────────────────────────────────
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
                    visualDensity: VisualDensity.compact,
                  ),
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
                  onSelectionChanged: (s) => settings.setThemeMode(s.first),
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),

              // Material You toggle
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
                subtitle: Text(
                  'Use wallpaper colors',
                  style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 12),
                ),
                value: settings.useDynamicColor,
                onChanged: settings.setUseDynamicColor,
              ),

              const Divider(height: 24),

              // ── Updates ─────────────────────────────────────────────────
              _SectionTitle(title: 'Mises à jour / Updates'),

              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.system_update_rounded,
                    size: 20,
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                ),
                title: const Text('Vérifier les mises à jour'),
                subtitle: Text(
                  '${l.t('settings_version')} $_version',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
                trailing: _checkingUpdate
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : FilledButton.tonal(
                        onPressed: _checkUpdate,
                        child: const Text('Vérifier'),
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
                  child: Icon(
                    Icons.speed_rounded,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
                title: const Text(
                  'Pace',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                subtitle: Text(
                  '${l.t('settings_version')} $_version',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
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
                    'Pace est un viewer non-officiel de classements speedrun. '
                    'Données fournies par l\'API publique speedrun.com.',
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

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.trailing,
  });

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
            child: Icon(
              icon,
              size: 20,
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: theme.textTheme.bodyLarge)),
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

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

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
        child:
            Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
      ),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
      ),
      isThreeLine: subtitle.length > 60,
    );
  }
}