import 'player.dart';

class Run {
  final String id;
  final String? gameId;
  final String? gameName;
  final String? categoryId;
  final String? categoryName;
  final String? weblink;
  final double? primaryTime;
  final double? realtimeTime;
  final double? realtimeNoLoads;
  final double? ingameTime;
  final String? date;
  final String? submitted;
  final String? status; // 'verified', 'new', 'rejected'
  final List<Player> players;
  final String? videoUrl;
  final String? comment;
  final String? platform;
  final bool emulated;

  const Run({
    required this.id,
    this.gameId,
    this.gameName,
    this.categoryId,
    this.categoryName,
    this.weblink,
    this.primaryTime,
    this.realtimeTime,
    this.realtimeNoLoads,
    this.ingameTime,
    this.date,
    this.submitted,
    this.status,
    this.players = const [],
    this.videoUrl,
    this.comment,
    this.platform,
    this.emulated = false,
  });

  factory Run.fromJson(Map<String, dynamic> json) {
    final times = json['times'] as Map<String, dynamic>? ?? {};

    double? parseTime(String key) {
      final val = times[key];
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val);
      return null;
    }

    // Extract video URL
    String? videoUrl;
    final videos = json['videos'];
    if (videos != null) {
      final links = videos['links'] as List<dynamic>?;
      if (links != null && links.isNotEmpty) {
        videoUrl = links.first['uri'] as String?;
      }
    }

    List<Player> players = [];
    final playersRaw = json['players'];
    if (playersRaw is Map) {
      final embedded = playersRaw['data'] as List<dynamic>?;
      if (embedded != null) {
        players = embedded.map((p) {
          if (p is Map && p['rel'] == 'guest') {
            return Player.guest(p['name'] as String? ?? 'Guest');
          }
          return Player.fromJson(p as Map<String, dynamic>);
        }).toList();
      }
    } else if (playersRaw is List) {
      for (final p in playersRaw) {
        if (p['rel'] == 'guest') {
          players.add(Player.guest(p['name'] as String? ?? 'Guest'));
        } else if (p['rel'] == 'user') {
          players.add(Player(id: p['id'] as String, name: p['id'] as String));
        }
      }
    }

    // Game/category from embeds
    String? gameName;
    String? gameId;
    final gameEmbed = json['game'];
    if (gameEmbed is Map) {
      final data = gameEmbed['data'] as Map<String, dynamic>?;
      if (data != null) {
        gameId = data['id'] as String?;
        gameName = (data['names'] as Map<String, dynamic>?)?['international'] as String?;
      } else {
        gameId = gameEmbed['id'] as String? ?? json['game'] as String?;
      }
    } else if (gameEmbed is String) {
      gameId = gameEmbed;
    }

    String? categoryName;
    String? categoryId;
    final catEmbed = json['category'];
    if (catEmbed is Map) {
      final data = catEmbed['data'] as Map<String, dynamic>?;
      if (data != null) {
        categoryId = data['id'] as String?;
        categoryName = data['name'] as String?;
      } else {
        categoryId = catEmbed['id'] as String? ?? json['category'] as String?;
      }
    } else if (catEmbed is String) {
      categoryId = catEmbed;
    }

    final systemData = json['system'] as Map<String, dynamic>? ?? {};

    return Run(
      id: json['id'] as String,
      gameId: gameId,
      gameName: gameName,
      categoryId: categoryId,
      categoryName: categoryName,
      weblink: json['weblink'] as String?,
      primaryTime: parseTime('primary_t'),
      realtimeTime: parseTime('realtime_t'),
      realtimeNoLoads: parseTime('realtime_noloads_t'),
      ingameTime: parseTime('ingame_t'),
      date: json['date'] as String?,
      submitted: json['submitted'] as String?,
      status: (json['status'] as Map<String, dynamic>?)?['status'] as String?,
      players: players,
      videoUrl: videoUrl,
      comment: json['comment'] as String?,
      platform: systemData['platform'] as String?,
      emulated: systemData['emulated'] as bool? ?? false,
    );
  }
}
