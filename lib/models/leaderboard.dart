import 'run.dart';
import 'player.dart';

class LeaderboardEntry {
  final int place;
  final Run run;

  const LeaderboardEntry({required this.place, required this.run});

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    // Players can be embedded at the run level or separately
    final runData = json['run'] as Map<String, dynamic>;

    // Merge embedded players if provided at entry level
    List<Player> players = [];
    final embeddedPlayers = json['players'] as List<dynamic>?;
    if (embeddedPlayers != null) {
      players = embeddedPlayers.map((p) {
        if (p['rel'] == 'guest') {
          return Player.guest(p['name'] as String? ?? 'Guest');
        }
        return Player.fromJson(p as Map<String, dynamic>);
      }).toList();
    }

    final run = Run.fromJson(runData);

    // If we got embedded players, override the ones in the run
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

    return LeaderboardEntry(
      place: json['place'] as int,
      run: run,
    );
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
    final runs = (data['runs'] as List<dynamic>? ?? [])
        .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
        .toList();

    return Leaderboard(
      gameId: data['game'] as String,
      categoryId: data['category'] as String,
      levelId: data['level'] as String?,
      runs: runs,
    );
  }
}
