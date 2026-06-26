import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

/// Configuration — replace with your actual GitHub repo
const String _kGithubOwner = 'YOUR_GITHUB_USERNAME'; // ← change this
const String _kGithubRepo = 'pace';

class ReleaseInfo {
  final String version;     // e.g. "1.2.0"
  final String tagName;     // e.g. "v1.2.0"
  final String? body;       // release notes
  final String downloadUrl; // direct APK URL
  final String htmlUrl;     // GitHub release page

  const ReleaseInfo({
    required this.version,
    required this.tagName,
    this.body,
    required this.downloadUrl,
    required this.htmlUrl,
  });
}

class UpdateService {
  static final UpdateService _instance = UpdateService._();
  UpdateService._();
  factory UpdateService() => _instance;

  /// Returns [ReleaseInfo] if a newer version is available, null otherwise.
  Future<ReleaseInfo?> checkForUpdate() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final current = _parseVersion(info.version);

      final uri = Uri.parse(
        'https://api.github.com/repos/$_kGithubOwner/$_kGithubRepo/releases/latest',
      );
      final response = await http.get(uri, headers: {
        'Accept': 'application/vnd.github+json',
        'User-Agent': 'pace-app',
      }).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final tagName = json['tag_name'] as String? ?? '';
      final latest = _parseVersion(tagName.replaceAll('v', ''));

      if (!_isNewer(latest, current)) return null;

      // Find the APK asset
      final assets = json['assets'] as List<dynamic>? ?? [];
      String downloadUrl = json['html_url'] as String? ?? '';
      for (final asset in assets) {
        final name = asset['name'] as String? ?? '';
        if (name.endsWith('.apk')) {
          downloadUrl = asset['browser_download_url'] as String? ?? downloadUrl;
          break;
        }
      }

      return ReleaseInfo(
        version: latest.join('.'),
        tagName: tagName,
        body: json['body'] as String?,
        downloadUrl: downloadUrl,
        htmlUrl: json['html_url'] as String? ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  List<int> _parseVersion(String v) {
    return v
        .split('.')
        .map((s) => int.tryParse(s.replaceAll(RegExp(r'[^\d]'), '')) ?? 0)
        .toList();
  }

  bool _isNewer(List<int> latest, List<int> current) {
    for (int i = 0; i < 3; i++) {
      final l = i < latest.length ? latest[i] : 0;
      final c = i < current.length ? current[i] : 0;
      if (l > c) return true;
      if (l < c) return false;
    }
    return false;
  }
}
