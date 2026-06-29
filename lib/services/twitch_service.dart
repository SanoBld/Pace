import 'dart:convert';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────────────────────────────────────
// Setup: register a free app at https://dev.twitch.tv/console
// Fill in your Client ID and Client Secret below.
// The Client Secret is only used to get a read-only app token
// (no user data access). Safe for personal/open-source apps.
// ─────────────────────────────────────────────────────────────────────────────
const String _kClientId = '';     // ← your Twitch Client ID
const String _kClientSecret = ''; // ← your Twitch Client Secret

class TwitchService {
  static final TwitchService _i = TwitchService._();
  TwitchService._();
  factory TwitchService() => _i;

  String? _accessToken;
  DateTime? _tokenExpiry;
  final _cache = <String, ({bool live, DateTime at})>{};

  bool get isConfigured =>
      _kClientId.isNotEmpty && _kClientSecret.isNotEmpty;

  /// Extract Twitch username from a speedrun.com social URL
  static String? usernameFrom(String? url) {
    if (url == null) return null;
    try {
      return Uri.parse(url).pathSegments.last;
    } catch (_) {
      return null;
    }
  }

  Future<bool> isLive(String username) async {
    if (!isConfigured) return false;
    final key = username.toLowerCase();

    // 5-minute cache
    final cached = _cache[key];
    if (cached != null &&
        DateTime.now().difference(cached.at).inMinutes < 5) {
      return cached.live;
    }

    try {
      final token = await _token();
      if (token == null) return false;

      final res = await http.get(
        Uri.parse(
            'https://api.twitch.tv/helix/streams?user_login=$key'),
        headers: {
          'Client-Id': _kClientId,
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final data = json.decode(res.body)['data'] as List<dynamic>;
        final live = data.isNotEmpty;
        _cache[key] = (live: live, at: DateTime.now());
        return live;
      }
    } catch (_) {}
    return false;
  }

  /// Batch check — more efficient for leaderboard tiles
  Future<Map<String, bool>> areLive(List<String> usernames) async {
    if (!isConfigured || usernames.isEmpty) return {};
    final token = await _token();
    if (token == null) return {};

    final now = DateTime.now();
    final toFetch = <String>[];
    final result = <String, bool>{};

    for (final u in usernames) {
      final key = u.toLowerCase();
      final cached = _cache[key];
      if (cached != null && now.difference(cached.at).inMinutes < 5) {
        result[key] = cached.live;
      } else {
        toFetch.add(key);
      }
    }

    if (toFetch.isEmpty) return result;

    try {
      final query = toFetch.map((u) => 'user_login=$u').join('&');
      final res = await http.get(
        Uri.parse('https://api.twitch.tv/helix/streams?$query'),
        headers: {
          'Client-Id': _kClientId,
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final live = (json.decode(res.body)['data'] as List<dynamic>)
            .map((s) => (s['user_login'] as String).toLowerCase())
            .toSet();

        for (final u in toFetch) {
          final isLive = live.contains(u);
          _cache[u] = (live: isLive, at: now);
          result[u] = isLive;
        }
      }
    } catch (_) {}

    return result;
  }

  Future<String?> _token() async {
    if (_accessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _accessToken;
    }

    try {
      final res = await http
          .post(
            Uri.parse('https://id.twitch.tv/oauth2/token'),
            body: {
              'client_id': _kClientId,
              'client_secret': _kClientSecret,
              'grant_type': 'client_credentials',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        _accessToken = data['access_token'] as String?;
        final expiresIn = (data['expires_in'] as int?) ?? 3600;
        _tokenExpiry =
            DateTime.now().add(Duration(seconds: expiresIn - 60));
        return _accessToken;
      }
    } catch (_) {}
    return null;
  }
}