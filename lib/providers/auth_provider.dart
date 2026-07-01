import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player.dart';

class AuthProvider extends ChangeNotifier {
  static const _keyApiKey = 'api_key';
  static const _keyOnboarded = 'has_onboarded';

  String? _apiKey;
  Player? _currentUser;
  bool _hasOnboarded = false;
  bool _loadingUser = false;

  String? get apiKey => _apiKey;
  Player? get currentUser => _currentUser;
  bool get hasOnboarded => _hasOnboarded;
  bool get isAuthenticated => _apiKey != null && _apiKey!.isNotEmpty;
  bool get loadingUser => _loadingUser;

  AuthProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString(_keyApiKey);
    _hasOnboarded = prefs.getBool(_keyOnboarded) ?? false;
    notifyListeners();
  }

  /// Called after onboarding is complete (with or without key)
  Future<void> completeOnboarding({String? apiKey}) async {
    _apiKey = apiKey?.trim().isEmpty == true ? null : apiKey?.trim();
    _hasOnboarded = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboarded, true);
    if (_apiKey != null) {
      await prefs.setString(_keyApiKey, _apiKey!);
    } else {
      await prefs.remove(_keyApiKey);
    }
    notifyListeners();
  }

  /// Save API key from settings (without re-onboarding)
  Future<void> setApiKey(String? key) async {
    _apiKey = key?.trim().isEmpty == true ? null : key?.trim();
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    if (_apiKey != null) {
      await prefs.setString(_keyApiKey, _apiKey!);
    } else {
      await prefs.remove(_keyApiKey);
    }
    notifyListeners();
  }

  Future<void> logout() async {
    _apiKey = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyApiKey);
    notifyListeners();
  }

  void setCurrentUser(Player? user) {
    _currentUser = user;
    notifyListeners();
  }

  void setLoadingUser(bool v) {
    _loadingUser = v;
    notifyListeners();
  }
}
