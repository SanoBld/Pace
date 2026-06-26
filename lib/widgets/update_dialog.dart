import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/update_service.dart';
import '../l10n/app_localizations.dart';

class UpdateDialog extends StatelessWidget {
  final ReleaseInfo release;

  const UpdateDialog({super.key, required this.release});

  static Future<void> showIfNeeded(BuildContext context) async {
    final info = await UpdateService().checkForUpdate();
    if (info != null && context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => UpdateDialog(release: info),
      );
    }
  }

  Future<void> _download() async {
    final uri = Uri.parse(release.downloadUrl);
    if (await canLaunchUrl(uri)) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AlertDialog(
      icon: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.tertiary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          Icons.system_update_rounded,
          color: theme.colorScheme.onPrimary,
          size: 28,
        ),
      ),
      title: Text(
        'update_available',
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'v${release.version}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (release.body != null && release.body!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Nouveautés / What\'s new:',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              constraints: const BoxConstraints(maxHeight: 160),
              child: SingleChildScrollView(
                child: Text(
                  release.body!,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.t('cancel')),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.pop(context);
            _download();
          },
          icon: const Icon(Icons.download_rounded),
          label: const Text('Télécharger / Download'),
        ),
      ],
    );
  }
}
