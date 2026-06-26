import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const Map<String, Map<String, String>> _values = {
    'en': {
      // Nav
      'nav_home': 'Home',
      'nav_leaderboards': 'Leaderboards',
      'nav_search': 'Search',
      'nav_profile': 'Profile',
      'nav_settings': 'Settings',
      // Home
      'home_title': 'Pace',
      'home_recent_runs': 'Recent Runs',
      'home_trending': 'Trending Games',
      'home_empty': 'No recent runs found.',
      'home_see_all': 'See all',
      // Leaderboard
      'lb_title': 'Leaderboards',
      'lb_browse_games': 'Browse Games',
      'lb_popular': 'Popular Games',
      'lb_categories': 'Categories',
      'lb_full_game': 'Full Game',
      'lb_individual_levels': 'Individual Levels',
      'lb_rank': 'Rank',
      'lb_player': 'Player',
      'lb_time': 'Time',
      'lb_date': 'Date',
      'lb_platform': 'Platform',
      'lb_video': 'Video',
      'lb_no_runs': 'No runs found for this category.',
      'lb_subcategory': 'Sub-category',
      'lb_filter': 'Filter',
      'lb_wr': 'WR',
      // Search
      'search_title': 'Search',
      'search_hint_games': 'Search games...',
      'search_hint_players': 'Search players...',
      'search_games': 'Games',
      'search_players': 'Players',
      'search_empty': 'No results found.',
      'search_start': 'Start typing to search.',
      // Profile
      'profile_title': 'Profile',
      'profile_enter_user': 'Enter a username',
      'profile_hint': 'speedrun.com username',
      'profile_search_btn': 'Look up',
      'profile_pbs': 'Personal Bests',
      'profile_no_pbs': 'No personal bests found.',
      'profile_signed_up': 'Member since',
      'profile_location': 'Location',
      'profile_twitch': 'Twitch',
      'profile_youtube': 'YouTube',
      'profile_twitter': 'Twitter',
      'profile_place': 'Place',
      'profile_game': 'Game',
      'profile_category': 'Category',
      // Settings
      'settings_title': 'Settings',
      'settings_appearance': 'Appearance',
      'settings_language': 'Language',
      'settings_theme': 'Theme',
      'settings_theme_system': 'System',
      'settings_theme_light': 'Light',
      'settings_theme_dark': 'Dark',
      'settings_lang_en': 'English',
      'settings_lang_fr': 'Français',
      'settings_about': 'About',
      'settings_about_app': 'About Pace',
      'settings_version': 'Version',
      'settings_source': 'Data source',
      'settings_source_desc': 'speedrun.com public API v1',
      'settings_developer': 'Developer',
      // General
      'loading': 'Loading...',
      'error': 'An error occurred.',
      'retry': 'Retry',
      'open_link': 'Open link',
      'close': 'Close',
      'cancel': 'Cancel',
      'ok': 'OK',
      'time_ago': 'ago',
      'world_record': 'World Record',
      'no_video': 'No video',
    },
    'fr': {
      // Nav
      'nav_home': 'Accueil',
      'nav_leaderboards': 'Classements',
      'nav_search': 'Recherche',
      'nav_profile': 'Profil',
      'nav_settings': 'Paramètres',
      // Home
      'home_title': 'Pace',
      'home_recent_runs': 'Runs récents',
      'home_trending': 'Jeux tendance',
      'home_empty': 'Aucun run récent trouvé.',
      'home_see_all': 'Voir tout',
      // Leaderboard
      'lb_title': 'Classements',
      'lb_browse_games': 'Parcourir les jeux',
      'lb_popular': 'Jeux populaires',
      'lb_categories': 'Catégories',
      'lb_full_game': 'Jeu complet',
      'lb_individual_levels': 'Niveaux individuels',
      'lb_rank': 'Rang',
      'lb_player': 'Joueur',
      'lb_time': 'Temps',
      'lb_date': 'Date',
      'lb_platform': 'Plateforme',
      'lb_video': 'Vidéo',
      'lb_no_runs': 'Aucun run trouvé pour cette catégorie.',
      'lb_subcategory': 'Sous-catégorie',
      'lb_filter': 'Filtrer',
      'lb_wr': 'WR',
      // Search
      'search_title': 'Recherche',
      'search_hint_games': 'Rechercher des jeux...',
      'search_hint_players': 'Rechercher des joueurs...',
      'search_games': 'Jeux',
      'search_players': 'Joueurs',
      'search_empty': 'Aucun résultat trouvé.',
      'search_start': 'Commencez à taper pour rechercher.',
      // Profile
      'profile_title': 'Profil',
      'profile_enter_user': 'Entrez un nom d\'utilisateur',
      'profile_hint': 'Nom speedrun.com',
      'profile_search_btn': 'Rechercher',
      'profile_pbs': 'Meilleurs temps personnels',
      'profile_no_pbs': 'Aucun meilleur temps trouvé.',
      'profile_signed_up': 'Membre depuis',
      'profile_location': 'Localisation',
      'profile_twitch': 'Twitch',
      'profile_youtube': 'YouTube',
      'profile_twitter': 'Twitter',
      'profile_place': 'Place',
      'profile_game': 'Jeu',
      'profile_category': 'Catégorie',
      // Settings
      'settings_title': 'Paramètres',
      'settings_appearance': 'Apparence',
      'settings_language': 'Langue',
      'settings_theme': 'Thème',
      'settings_theme_system': 'Système',
      'settings_theme_light': 'Clair',
      'settings_theme_dark': 'Sombre',
      'settings_lang_en': 'English',
      'settings_lang_fr': 'Français',
      'settings_about': 'À propos',
      'settings_about_app': 'À propos de Pace',
      'settings_version': 'Version',
      'settings_source': 'Source des données',
      'settings_source_desc': 'API publique speedrun.com v1',
      'settings_developer': 'Développeur',
      // General
      'loading': 'Chargement...',
      'error': 'Une erreur est survenue.',
      'retry': 'Réessayer',
      'open_link': 'Ouvrir le lien',
      'close': 'Fermer',
      'cancel': 'Annuler',
      'ok': 'OK',
      'time_ago': 'il y a',
      'world_record': 'Record du monde',
      'no_video': 'Pas de vidéo',
    },
  };

  String t(String key) {
    final lang = locale.languageCode;
    return _values[lang]?[key] ?? _values['en']?[key] ?? key;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'fr'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
