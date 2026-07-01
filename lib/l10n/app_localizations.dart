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
      // Onboarding
      'onboard_welcome_title': 'Welcome to Pace',
      'onboard_welcome_desc':
          'Your speedrun companion.\nBrowse leaderboards, follow runners and track world records — all powered by speedrun.com.',
      'onboard_get_started': 'Get Started',
      'onboard_features_title': 'Everything you need',
      'onboard_next': 'Next',
      'onboard_connect_title': 'Connect your account',
      'onboard_connect_optional': 'Optional — you can skip this',
      'onboard_connect_benefits': 'With your API key you get:',
      'onboard_warning':
          'Never share your API key. It gives full access to your speedrun.com account.',
      'onboard_api_key_label': 'API Key',
      'onboard_api_key_hint': 'Paste your speedrun.com API key',
      'onboard_get_key': 'Get your key at speedrun.com/settings/api',
      'onboard_connect_continue': 'Connect & Continue',
      'onboard_skip': 'Skip — use without account',
      // Account / API key
      'account_title': 'Account',
      'account_key_connected': 'API Key connected',
      'account_key_none': 'No API Key',
      'account_key_desc': 'Connect to unlock personal stats & mod tools',
      'account_key_change': 'Change',
      'account_key_add': 'Add',
      'account_key_remove': 'Remove',
      'account_key_save': 'Save',
      'account_key_cancel': 'Cancel',
      'account_authenticated':
          'Authenticated — personal profile, mod tools and run management unlocked.',
      // Notifications
      'notifications_title': 'Notifications',
      'notifications_empty': 'No notifications',
      // My runs
      'my_runs_title': 'My Runs',
      'my_runs_empty': 'No runs found',
      'my_runs_pending': 'pending',
      'my_runs_verified': 'verified',
      'my_runs_rejected': 'rejected',
      'my_runs_all': 'all',
      // WR chart
      'wr_chart_title': 'WR Progression',
      'wr_chart_empty': 'No WR history available',
      'wr_chart_history': 'Record history',
      'wr_chart_tab': 'WR History',
      'leaderboard_tab': 'Leaderboard',
      // Material You
      'settings_material_you': 'Material You',
      'settings_material_you_desc': 'Use wallpaper colors',
      // Games tab (renamed from Leaderboards)
      'games_title': 'Games',
      'games_active': 'Active',
      'games_az': 'A → Z',
      'games_newest': 'Newest',
      'top_filter_all': 'All',
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
      // Onboarding
      'onboard_welcome_title': 'Bienvenue sur Pace',
      'onboard_welcome_desc':
          'Votre compagnon de speedrun.\nParcourez les classements, suivez les coureurs et suivez les records du monde — propulsé par speedrun.com.',
      'onboard_get_started': 'Commencer',
      'onboard_features_title': 'Tout ce dont vous avez besoin',
      'onboard_next': 'Suivant',
      'onboard_connect_title': 'Connectez votre compte',
      'onboard_connect_optional': 'Optionnel — vous pouvez passer cette étape',
      'onboard_connect_benefits': 'Avec votre clé API, vous obtenez :',
      'onboard_warning':
          'Ne partagez jamais votre clé API. Elle donne un accès complet à votre compte speedrun.com.',
      'onboard_api_key_label': 'Clé API',
      'onboard_api_key_hint': 'Collez votre clé API speedrun.com',
      'onboard_get_key': 'Obtenez votre clé sur speedrun.com/settings/api',
      'onboard_connect_continue': 'Connecter et continuer',
      'onboard_skip': 'Passer — utiliser sans compte',
      // Account / API key
      'account_title': 'Compte',
      'account_key_connected': 'Clé API connectée',
      'account_key_none': 'Aucune clé API',
      'account_key_desc':
          'Connectez-vous pour débloquer vos stats perso et les outils de modération',
      'account_key_change': 'Modifier',
      'account_key_add': 'Ajouter',
      'account_key_remove': 'Supprimer',
      'account_key_save': 'Enregistrer',
      'account_key_cancel': 'Annuler',
      'account_authenticated':
          'Authentifié — profil personnel, outils de modération et gestion des runs débloqués.',
      // Notifications
      'notifications_title': 'Notifications',
      'notifications_empty': 'Aucune notification',
      // My runs
      'my_runs_title': 'Mes runs',
      'my_runs_empty': 'Aucun run trouvé',
      'my_runs_pending': 'en attente',
      'my_runs_verified': 'vérifié',
      'my_runs_rejected': 'rejeté',
      'my_runs_all': 'tous',
      // WR chart
      'wr_chart_title': 'Progression du WR',
      'wr_chart_empty': 'Aucun historique de WR disponible',
      'wr_chart_history': 'Historique des records',
      'wr_chart_tab': 'Historique WR',
      'leaderboard_tab': 'Classement',
      // Material You
      'settings_material_you': 'Material You',
      'settings_material_you_desc': "Utiliser les couleurs du fond d'écran",
      // Games tab
      'games_title': 'Jeux',
      'games_active': 'Actifs',
      'games_az': 'A → Z',
      'games_newest': 'Récents',
      'top_filter_all': 'Tous',
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
