import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/game.dart';
import '../models/category.dart';
import '../models/run.dart';
import '../models/player.dart';
import '../models/leaderboard.dart';
import '../models/variable.dart';

class SpeedrunApiException implements Exception {
  final String message;
  final int? statusCode;
  SpeedrunApiException(this.message, {this.statusCode});
  @override
  String toString() => 'SpeedrunApiException: $message (HTTP $statusCode)';
}

class SpeedrunApiService {
  final http.Client _client;

  SpeedrunApiService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> get _headers => {
        'User-Agent': AppConstants.userAgent,
        'Accept': 'application/json',
      };

  Future<Map<String, dynamic>> _get(String path,
      {Map<String, String>? params}) async {
    final uri = Uri.parse('${AppConstants.apiBase}$path').replace(
      queryParameters: params,
    );
    final response = await _client.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw SpeedrunApiException(
      'Request failed: $path',
      statusCode: response.statusCode,
    );
  }

  // ── GAMES ──────────────────────────────────────────────────────────────────

  /// Search games by name
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

  Future<List<Game>> getPopularGames({int max = 20, String? orderBy, String direction = 'desc'}) async {
    final params = <String, String>{'max': max.toString()};
    if (orderBy != null) {
      params['orderby'] = orderBy;
      params['direction'] = direction;
    }
    final data = await _get('/games', params: params);
    final list = data['data'] as List<dynamic>;
    return list.map((e) => Game.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Games derived from recent run activity (with cover images)
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

  /// Fetch a single game by ID or abbreviation
  Future<Game> getGame(String idOrAbbr) async {
    final data = await _get('/games/$idOrAbbr');
    return Game.fromJson(data['data'] as Map<String, dynamic>);
  }

  // ── CATEGORIES ─────────────────────────────────────────────────────────────

  /// Fetch categories for a game
  Future<List<Category>> getCategories(String gameId) async {
    final data = await _get('/games/$gameId/categories', params: {
      'miscellaneous': 'no',
    });
    final list = data['data'] as List<dynamic>;
    return list
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch all categories (including misc)
  Future<List<Category>> getAllCategories(String gameId) async {
    final data = await _get('/games/$gameId/categories');
    final list = data['data'] as List<dynamic>;
    return list
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch variables (subcategories) for a category
  Future<List<Variable>> getCategoryVariables(String categoryId) async {
    final data = await _get('/categories/$categoryId/variables');
    final list = data['data'] as List<dynamic>;
    return list
        .map((e) => Variable.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── LEVELS ─────────────────────────────────────────────────────────────────

  /// Fetch individual levels for a game
  Future<List<Map<String, dynamic>>> getLevels(String gameId) async {
    final data = await _get('/games/$gameId/levels');
    return (data['data'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
  }

  /// Fetch categories for a specific level
  Future<List<Category>> getLevelCategories(String levelId) async {
    final data = await _get('/levels/$levelId/categories');
    final list = data['data'] as List<dynamic>;
    return list
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── LEADERBOARDS ───────────────────────────────────────────────────────────

  /// Full game leaderboard
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
      variables.forEach((varId, valueId) {
        params['var-$varId'] = valueId;
      });
    }

    final data = await _get(
      '/leaderboards/$gameId/category/$categoryId',
      params: params,
    );
    return Leaderboard.fromJson(data);
  }

  /// Individual level leaderboard
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

  /// Fetch recent verified runs (global feed)
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

  /// Fetch a single run by ID
  Future<Run> getRun(String runId) async {
    final data = await _get('/runs/$runId', params: {'embed': 'game,category,players'});
    return Run.fromJson(data['data'] as Map<String, dynamic>);
  }

  // ── USERS ──────────────────────────────────────────────────────────────────

  /// Search users by name
  Future<List<Player>> searchUsers(String query) async {
    final data = await _get('/users', params: {'name': query, 'max': '20'});
    final list = data['data'] as List<dynamic>;
    return list
        .map((e) => Player.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch user by ID or username
  Future<Player> getUser(String idOrName) async {
    final data = await _get('/users/$idOrName');
    return Player.fromJson(data['data'] as Map<String, dynamic>);
  }

  /// Fetch user personal bests
  Future<List<PersonalBest>> getUserPersonalBests(
    String userId, {
    int? top,
  }) async {
    final params = <String, String>{
      'embed': 'game,category',
    };
    if (top != null) params['top'] = top.toString();

    final data = await _get('/users/$userId/personal-bests', params: params);
    final list = data['data'] as List<dynamic>;
    return list
        .map((e) => PersonalBest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  void dispose() => _client.close();
}