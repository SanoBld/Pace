import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game.dart';

class FavoritesProvider extends ChangeNotifier {
  static const _key = 'favorites_v1';
  List<Game> _favorites = [];

  List<Game> get favorites => List.unmodifiable(_favorites);

  FavoritesProvider() {
    _load();
  }

  bool isFavorite(String gameId) => _favorites.any((g) => g.id == gameId);

  Future<void> toggleFavorite(Game game) async {
    if (isFavorite(game.id)) {
      _favorites.removeWhere((g) => g.id == game.id);
    } else {
      _favorites.insert(0, game);
    }
    notifyListeners();
    await _save();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    try {
      final list = json.decode(raw) as List<dynamic>;
      _favorites = list.map((e) => _fromMap(e as Map<String, dynamic>)).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json.encode(_favorites.map(_toMap).toList()));
  }

  Map<String, dynamic> _toMap(Game g) => {
        'id': g.id,
        'name': g.name,
        'abbreviation': g.abbreviation,
        'weblink': g.weblink,
        'coverUrl': g.coverUrl,
        'released': g.released,
      };

  Game _fromMap(Map<String, dynamic> m) => Game(
        id: m['id'] as String,
        name: m['name'] as String,
        abbreviation: m['abbreviation'] as String?,
        weblink: m['weblink'] as String?,
        coverUrl: m['coverUrl'] as String?,
        released: m['released'] as int?,
      );
}