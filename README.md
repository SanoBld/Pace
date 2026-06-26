# Pace 🏃‍♂️

A speedrun leaderboard Flutter app powered by the **speedrun.com public API v1**.

## Features

- 🏠 **Home** — Recent verified runs feed + trending games grid
- 🏆 **Leaderboards** — Browse games → full game categories & individual levels → ranked runs
- 🔍 **Search** — Search games and players simultaneously
- 👤 **Profile** — Look up any runner by username: avatar, socials, all personal bests with rank medals
- ⚙️ **Settings** — Toggle language (EN/FR), theme (light / dark / system)

## Data source

All data is fetched from the [speedrun.com REST API v1](https://github.com/speedruncomorg/api).  
No API key required — the API is fully public.

## Setup

### Requirements

- Flutter SDK ≥ 3.2.0
- Dart SDK ≥ 3.2.0

### Install & run

```bash
# 1. Install dependencies
flutter pub get

# 2. Run (mobile, web, or desktop)
flutter run

# Build APK (Android)
flutter build apk --release

# Build for web
flutter build web --release
```

### Platforms supported

| Platform | Status |
|----------|--------|
| Android  | ✅     |
| iOS      | ✅     |
| Web      | ✅     |
| macOS    | ✅     |
| Windows  | ✅     |
| Linux    | ✅     |

## Project structure

```
lib/
├── main.dart                        # App entry point
├── core/
│   ├── constants.dart               # API base URL, page sizes
│   ├── utils.dart                   # Time formatting, rank helpers
│   └── theme/app_theme.dart         # Material 3 light & dark themes
├── l10n/
│   └── app_localizations.dart       # EN/FR strings (no codegen needed)
├── models/
│   ├── game.dart
│   ├── category.dart
│   ├── run.dart
│   ├── player.dart
│   ├── leaderboard.dart
│   └── variable.dart                # Sub-categories & personal bests
├── providers/
│   └── settings_provider.dart       # Theme + locale (SharedPreferences)
├── services/
│   └── speedrun_api.dart            # All speedrun.com API calls
├── screens/
│   ├── main_scaffold.dart           # Bottom navigation
│   ├── home/home_screen.dart
│   ├── leaderboard/
│   │   ├── leaderboard_screen.dart
│   │   ├── game_detail_screen.dart
│   │   └── category_leaderboard_screen.dart
│   ├── search/search_screen.dart
│   ├── profile/profile_screen.dart
│   └── settings/settings_screen.dart
└── widgets/
    ├── run_tile.dart
    ├── game_card.dart
    ├── leaderboard_entry_tile.dart
    └── shared_widgets.dart          # Error, empty, shimmer, section header
```

## API endpoints used

| Endpoint | Purpose |
|----------|---------|
| `GET /games` | Browse / search games |
| `GET /games/{id}/categories` | List categories for a game |
| `GET /games/{id}/levels` | List individual levels |
| `GET /levels/{id}/categories` | Categories for a level |
| `GET /categories/{id}/variables` | Sub-category variables |
| `GET /leaderboards/{game}/category/{cat}` | Full game leaderboard |
| `GET /leaderboards/{game}/level/{lvl}/{cat}` | IL leaderboard |
| `GET /runs` | Recent verified runs feed |
| `GET /users` | Search players |
| `GET /users/{id}` | Player profile |
| `GET /users/{id}/personal-bests` | Player PBs |

## License

MIT — not affiliated with speedrun.com.
