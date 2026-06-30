class AppNotification {
  final String id;
  final String text;
  final String? itemId;
  final String? itemType; // 'run', 'comment', 'game', ...
  final String? itemUrl;
  final bool read;
  final String? date;

  const AppNotification({
    required this.id,
    required this.text,
    this.itemId,
    this.itemType,
    this.itemUrl,
    this.read = false,
    this.date,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final item = json['item'] as Map<String, dynamic>?;
    return AppNotification(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      itemId: item?['id'] as String?,
      itemType: item?['rel'] as String?,
      itemUrl: item?['uri'] as String?,
      read: json['read'] as bool? ?? false,
      date: json['created'] as String?,
    );
  }
}
