class Game {
  final String id;
  final String name;
  final String? abbreviation;
  final String? weblink;
  final String? coverUrl;
  final int? released;
  final List<String> platforms;

  const Game({
    required this.id,
    required this.name,
    this.abbreviation,
    this.weblink,
    this.coverUrl,
    this.released,
    this.platforms = const [],
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    String? cover;
    final assets = json['assets'];
    if (assets != null) {
      cover = assets['cover-large']?['uri'] as String? ??
          assets['cover-medium']?['uri'] as String? ??
          assets['cover-small']?['uri'] as String?;
    }

    return Game(
      id: json['id'] as String,
      name: (json['names'] as Map<String, dynamic>?)?['international'] as String? ??
          json['id'] as String,
      abbreviation: json['abbreviation'] as String?,
      weblink: json['weblink'] as String?,
      coverUrl: cover,
      released: json['released'] as int?,
      platforms: (() {
        final p = json['platforms'];
        if (p is List) return p.map((e) => e.toString()).toList();
        return <String>[];
      })(),
    );
  }
}
