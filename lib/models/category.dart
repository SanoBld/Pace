class Category {
  final String id;
  final String name;
  final String type; // 'per-game' or 'per-level'
  final String? rules;
  final bool miscellaneous;

  const Category({
    required this.id,
    required this.name,
    required this.type,
    this.rules,
    this.miscellaneous = false,
  });

  bool get isPerGame => type == 'per-game';

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String? ?? 'per-game',
      rules: json['rules'] as String?,
      miscellaneous: json['miscellaneous'] as bool? ?? false,
    );
  }
}
