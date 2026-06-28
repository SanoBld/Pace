import 'run.dart';
import 'player.dart';

class LeaderboardEntry {
  final int place;
  final Run run;

  const LeaderboardEntry({required this.place, required this.run});

  factory LeaderboardEntry.fromJson(
    Map<String, dynamic> json, {
    Map<String, Player> playerMap = const {},
  }) {
    final runData = json['run'] as Map<String, dynamic>;

    // Resolve players: prefer top-level playerMap (full data), fallback to entry-level
    List<Player> players = [];
    final playersRaw = json['players'];
    if (playersRaw is List) {
      for (final p in playersRaw) {
        if (p is! Map) continue;
        if (p['rel'] == 'guest') {
          players.add(Player.guest(p['name'] as String? ?? 'Guest'));
        } else {
          final id = p['id'] as String? ?? '';
          // Look up full player data from map first
          players.add(playerMap[id] ??
              (p.containsKey('names')
                  ? Player.fromJson(p as Map<String, dynamic>)
                  : Player(id: id, name: id)));
        }
      }
    }

    final run = Run.fromJson(runData);

    if (players.isNotEmpty) {
      return LeaderboardEntry(
        place: json['place'] as int,
        run: Run(
          id: run.id,
          gameId: run.gameId,
          gameName: run.gameName,
          categoryId: run.categoryId,
          categoryName: run.categoryName,
          weblink: run.weblink,
          primaryTime: run.primaryTime,
          realtimeTime: run.realtimeTime,
          realtimeNoLoads: run.realtimeNoLoads,
          ingameTime: run.ingameTime,
          date: run.date,
          submitted: run.submitted,
          status: run.status,
          players: players,
          videoUrl: run.videoUrl,
          comment: run.comment,
          platform: run.platform,
          emulated: run.emulated,
        ),
      );
    }

    return LeaderboardEntry(place: json['place'] as int, run: run);
  }
}

class Leaderboard {
  final String gameId;
  final String categoryId;
  final String? levelId;
  final List<LeaderboardEntry> runs;

  const Leaderboard({
    required this.gameId,
    required this.categoryId,
    this.levelId,
    required this.runs,
  });

  factory Leaderboard.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;

    // Build player lookup map from top-level embedded players
    final playerMap = <String, Player>{};
    final playersEmbed = data['players'];
    if (playersEmbed is Map) {
      final list = playersEmbed['data'] as List<dynamic>?;
      if (list != null) {
        for (final p in list) {
          if (p is Map<String, dynamic>) {
            try {
              final player = Player.fromJson(p);
              playerMap[player.id] = player;
            } catch (_) {}
          }
        }
      }
    }

    final runs = (data['runs'] as List<dynamic>? ?? [])
        .map((e) => LeaderboardEntry.fromJson(
              e as Map<String, dynamic>,
              playerMap: playerMap,
            ))
        .toList();

    return Leaderboard(
      gameId: data['game'] as String,
      categoryId: data['category'] as String,
      levelId: data['level'] as String?,
      runs: runs,
    );
  }
}