import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/game.dart';
import '../models/category.dart';
import '../models/run.dart';
import '../models/player.dart';
import '../models/leaderboard.dart';
import '../models/variable.dart';
import '../models/notification.dart';

class SpeedrunApiException implements Exception {
  final String message;
  final int? statusCode;
  SpeedrunApiException(this.message, {this.statusCode});
  @override
  String toString() => 'SpeedrunApiException: $message (HTTP $statusCode)';
}

class SpeedrunApiService {
  final http.Client _client;
  String? _apiKey;

  SpeedrunApiService({http.Client? client, String? apiKey})
      : _client = client ?? http.Client(),
        _apiKey = apiKey;

  void setApiKey(String? key) => _apiKey = key;

  Map<String, String> get _headers => {
        'User-Agent': AppConstants.userAgent,
        'Accept': 'application/json',
        if (_apiKey != null && _apiKey!.isNotEmpty) 'X-API-Key': _apiKey!,
      };

  Future<Map<String, dynamic>> _get(String path,
      {Map<String, String>? params}) async {
    final uri = Uri.parse('${AppConstants.apiBase}$path')
        .replace(queryParameters: params);
    final response = await _client.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw SpeedrunApiException('Request failed: $path',
        statusCode: response.statusCode);
  }

  Future<Map<String, dynamic>> _delete(String path) async {
    final uri = Uri.parse('${AppConstants.apiBase}$path');
    final response = await _client.delete(uri, headers: _headers);
    if (response.statusCode == 200 || response.statusCode == 204) {
      return response.body.isEmpty ? {} : json.decode(response.body);
    }
    throw SpeedrunApiException('Delete failed: $path',
        statusCode: response.statusCode);
  }

  Future<Map<String, dynamic>> _put(
      String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('${AppConstants.apiBase}$path');
    final response = await _client.put(
      uri,
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: json.encode(body),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw SpeedrunApiException('Update failed: $path',
        statusCode: response.statusCode);
  }

  // ── AUTHENTICATED ──────────────────────────────────────────────────────────

  /// Get the authenticated user's profile (requires API key)
  Future<Player> getProfile() async {
    final data = await _get('/profile');
    return Player.fromJson(data['data'] as Map<String, dynamic>);
  }

  /// Get runs submitted by the authenticated user
  Future<List<Run>> getMyRuns({
    String? status,
    int max = 50,
    int offset = 0,
  }) async {
    final profile = await getProfile();
    final params = <String, String>{
      'user': profile.id,
      'max': max.toString(),
      'offset': offset.toString(),
      'embed': 'game,category,players',
      'orderby': 'submitted',
      'direction': 'desc',
    };
    if (status != null) params['status'] = status;
    final data = await _get('/runs', params: params);
    final list = data['data'] as List<dynamic>;
    return list.map((e) => Run.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Delete a run (requires API key + ownership)
  Future<void> deleteRun(String runId) async {
    await _delete('/runs/$runId');
  }

  /// Verify a run (moderators only)
  Future<Run> verifyRun(String runId) async {
    final data = await _put('/runs/$runId/status', {
      'status': {'status': 'verified'}
    });
    return Run.fromJson(data['data'] as Map<String, dynamic>);
  }

  /// Reject a run with a reason (moderators only)
  Future<Run> rejectRun(String runId, String reason) async {
    final data = await _put('/runs/$runId/status', {
      'status': {'status': 'rejected', 'reason': reason}
    });
    return Run.fromJson(data['data'] as Map<String, dynamic>);
  }

  /// Get runs awaiting verification for a game (moderators)
  Future<List<Run>> getPendingRuns(String gameId, {int max = 50}) async {
    final data = await _get('/runs', params: {
      'game': gameId,
      'status': 'new',
      'max': max.toString(),
      'embed': 'game,category,players',
      'orderby': 'submitted',
      'direction': 'asc',
    });
    final list = data['data'] as List<dynamic>;
    return list.map((e) => Run.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Get the authenticated user's notifications (likes, comments, verifications…)
  /// Synced directly from your speedrun.com account.
  Future<List<AppNotification>> getNotifications({int max = 20}) async {
    final data = await _get('/notifications', params: {
      'max': max.toString(),
      'orderby': 'created',
      'direction': 'desc',
    });
    final list = data['data'] as List<dynamic>;
    return list
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── GAMES ──────────────────────────────────────────────────────────────────

  Future<List<Game>> searchGames(String query,
      {int offset = 0, int max = 20}) async {
    final data = await _get('/games', params: {
      'name': query,
      'max': max.toString(),
      'offset': offset.toString(),
    });
    final list = data['data'] as List<dynamic>;
    return list.map((e) => Game.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Game>> getPopularGames(
      {int max = 20, String? orderBy, String direction = 'desc'}) async {
    final params = <String, String>{'max': max.toString()};
    if (orderBy != null) {
      params['orderby'] = orderBy;
      params['direction'] = direction;
    }
    final data = await _get('/games', params: params);
    final list = data['data'] as List<dynamic>;
    return list.map((e) => Game.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Game>> getActiveGames({int max = 12}) async {
    final data = await _get('/runs', params: {
      'status': 'verified',
      'orderby': 'verify-date',
      'direction': 'desc',
      'max': '50',
      'embed': 'game',
    });
    final list = data['data'] as List<dynamic>;
    final seen = <String>{};
    final games = <Game>[];
    for (final r in list) {
      final gameEmbed = r['game'];
      if (gameEmbed is Map) {
        final gameData = gameEmbed['data'] as Map<String, dynamic>?;
        if (gameData != null) {
          final game = Game.fromJson(gameData);
          if (!seen.contains(game.id)) {
            seen.add(game.id);
            games.add(game);
            if (games.length >= max) break;
          }
        }
      }
    }
    return games;
  }

  Future<Game> getGame(String idOrAbbr) async {
    final data = await _get('/games/$idOrAbbr');
    return Game.fromJson(data['data'] as Map<String, dynamic>);
  }

  // ── CATEGORIES ─────────────────────────────────────────────────────────────

  Future<List<Category>> getCategories(String gameId) async {
    final data = await _get('/games/$gameId/categories',
        params: {'miscellaneous': 'no'});
    final list = data['data'] as List<dynamic>;
    return list
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Category>> getAllCategories(String gameId) async {
    final data = await _get('/games/$gameId/categories');
    final list = data['data'] as List<dynamic>;
    return list
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Variable>> getCategoryVariables(String categoryId) async {
    final data = await _get('/categories/$categoryId/variables');
    final list = data['data'] as List<dynamic>;
    return list
        .map((e) => Variable.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── LEVELS ─────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getLevels(String gameId) async {
    final data = await _get('/games/$gameId/levels');
    return (data['data'] as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<List<Category>> getLevelCategories(String levelId) async {
    final data = await _get('/levels/$levelId/categories');
    final list = data['data'] as List<dynamic>;
    return list
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── LEADERBOARDS ───────────────────────────────────────────────────────────

  Future<Leaderboard> getLeaderboard(
    String gameId,
    String categoryId, {
    Map<String, String>? variables,
    int top = 100,
  }) async {
    final params = <String, String>{
      'top': top.toString(),
      'embed': 'players',
    };
    if (variables != null) {
      variables.forEach((k, v) => params['var-$k'] = v);
    }
    final data = await _get(
        '/leaderboards/$gameId/category/$categoryId',
        params: params);
    return Leaderboard.fromJson(data);
  }

  Future<Leaderboard> getLevelLeaderboard(
    String gameId,
    String levelId,
    String categoryId, {
    int top = 100,
  }) async {
    final data = await _get(
      '/leaderboards/$gameId/level/$levelId/$categoryId',
      params: {'top': top.toString(), 'embed': 'players'},
    );
    return Leaderboard.fromJson(data);
  }

  // ── RUNS ───────────────────────────────────────────────────────────────────

  Future<List<Run>> getRecentRuns({int max = 20, int offset = 0}) async {
    final data = await _get('/runs', params: {
      'status': 'verified',
      'orderby': 'verify-date',
      'direction': 'desc',
      'max': max.toString(),
      'offset': offset.toString(),
      'embed': 'game,category,players',
    });
    final list = data['data'] as List<dynamic>;
    return list.map((e) => Run.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Run> getRun(String runId) async {
    final data = await _get('/runs/$runId',
        params: {'embed': 'game,category,players'});
    return Run.fromJson(data['data'] as Map<String, dynamic>);
  }

  /// All verified runs for a category sorted by date — for WR progression chart
  Future<List<Run>> getCategoryRunHistory(
    String gameId,
    String categoryId, {
    int max = 200,
  }) async {
    final data = await _get('/runs', params: {
      'game': gameId,
      'category': categoryId,
      'status': 'verified',
      'orderby': 'date',
      'direction': 'asc',
      'max': max.toString(),
      'embed': 'players',
    });
    final list = data['data'] as List<dynamic>;
    return list.map((e) => Run.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── USERS ──────────────────────────────────────────────────────────────────

  Future<List<Player>> searchUsers(String query) async {
    final data =
        await _get('/users', params: {'name': query, 'max': '20'});
    final list = data['data'] as List<dynamic>;
    return list
        .map((e) => Player.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Player> getUser(String idOrName) async {
    final data = await _get('/users/$idOrName');
    return Player.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<List<PersonalBest>> getUserPersonalBests(
    String userId, {
    int? top,
  }) async {
    final params = <String, String>{'embed': 'game,category'};
    if (top != null) params['top'] = top.toString();
    final data =
        await _get('/users/$userId/personal-bests', params: params);
    final list = data['data'] as List<dynamic>;
    return list
        .map((e) => PersonalBest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  void dispose() => _client.close();
}
