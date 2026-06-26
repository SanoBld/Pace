class Player {
  final String id;
  final String name;
  final String? pronouns;
  final String? country;
  final String? avatarUrl;
  final String? weblink;
  final Map<String, String?> socials;
  final String? signupDate;
  final String? nameStyle; // color hex or 'gradient'
  final String? nameColorFrom;
  final String? nameColorTo;

  const Player({
    required this.id,
    required this.name,
    this.pronouns,
    this.country,
    this.avatarUrl,
    this.weblink,
    this.socials = const {},
    this.signupDate,
    this.nameStyle,
    this.nameColorFrom,
    this.nameColorTo,
  });

  /// For guests (no account)
  factory Player.guest(String name) {
    return Player(id: 'guest_$name', name: name);
  }

  factory Player.fromJson(Map<String, dynamic> json) {
    String? country;
    final location = json['location'];
    if (location != null) {
      country = location['country']?['code'] as String?;
    }

    String? nameColorFrom;
    String? nameColorTo;
    String? nameStyle;
    final style = json['name-style'];
    if (style != null) {
      nameStyle = style['style'] as String?;
      if (nameStyle == 'gradient') {
        nameColorFrom = style['color-from']?['light'] as String?;
        nameColorTo = style['color-to']?['light'] as String?;
      } else {
        nameColorFrom = style['color']?['light'] as String?;
      }
    }

    return Player(
      id: json['id'] as String,
      name: (json['names'] as Map<String, dynamic>?)?['international'] as String? ??
          json['id'],
      pronouns: json['pronouns'] as String?,
      country: country,
      avatarUrl: (json['assets'] as Map<String, dynamic>?)?['image']?['uri'] as String?,
      weblink: json['weblink'] as String?,
      signupDate: json['signup'] as String?,
      socials: {
        'twitch': json['twitch']?['uri'] as String?,
        'youtube': json['youtube']?['uri'] as String?,
        'twitter': json['twitter']?['uri'] as String?,
        'hitbox': json['hitbox']?['uri'] as String?,
      },
      nameStyle: nameStyle,
      nameColorFrom: nameColorFrom,
      nameColorTo: nameColorTo,
    );
  }
}
