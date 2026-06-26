class Variable {
  final String id;
  final String name;
  final bool mandatory;
  final bool isSubcategory;
  final Map<String, VariableValue> values;
  final String? defaultValue;

  const Variable({
    required this.id,
    required this.name,
    required this.mandatory,
    required this.isSubcategory,
    required this.values,
    this.defaultValue,
  });

  factory Variable.fromJson(Map<String, dynamic> json) {
    final valuesData =
        (json['values'] as Map<String, dynamic>?)?['values'] as Map<String, dynamic>? ?? {};

    return Variable(
      id: json['id'] as String,
      name: json['name'] as String,
      mandatory: json['mandatory'] as bool? ?? false,
      isSubcategory: json['is-subcategory'] as bool? ?? false,
      defaultValue: (json['values'] as Map<String, dynamic>?)?['default'] as String?,
      values: valuesData.map(
        (key, value) => MapEntry(
          key,
          VariableValue.fromJson(key, value as Map<String, dynamic>),
        ),
      ),
    );
  }
}

class VariableValue {
  final String id;
  final String label;
  final bool miscellaneous;

  const VariableValue({
    required this.id,
    required this.label,
    required this.miscellaneous,
  });

  factory VariableValue.fromJson(String id, Map<String, dynamic> json) {
    return VariableValue(
      id: id,
      label: json['label'] as String? ?? id,
      miscellaneous: (json['flags'] as Map<String, dynamic>?)?['miscellaneous'] as bool? ?? false,
    );
  }
}

class PersonalBest {
  final int place;
  final String? gameId;
  final String? gameName;
  final String? categoryId;
  final String? categoryName;
  final double? primaryTime;
  final String? date;

  const PersonalBest({
    required this.place,
    this.gameId,
    this.gameName,
    this.categoryId,
    this.categoryName,
    this.primaryTime,
    this.date,
  });

  factory PersonalBest.fromJson(Map<String, dynamic> json) {
    String? gameName;
    String? gameId;
    final gameData = json['game'];
    if (gameData is Map) {
      final data = gameData['data'] as Map<String, dynamic>?;
      if (data != null) {
        gameId = data['id'] as String?;
        gameName = (data['names'] as Map<String, dynamic>?)?['international'] as String?;
      }
    }

    String? categoryName;
    String? categoryId;
    final catData = json['category'];
    if (catData is Map) {
      final data = catData['data'] as Map<String, dynamic>?;
      if (data != null) {
        categoryId = data['id'] as String?;
        categoryName = data['name'] as String?;
      }
    }

    final run = json['run'] as Map<String, dynamic>? ?? {};
    final times = run['times'] as Map<String, dynamic>? ?? {};
    double? primaryTime;
    final pt = times['primary_t'];
    if (pt is num) primaryTime = pt.toDouble();

    return PersonalBest(
      place: json['place'] as int? ?? 0,
      gameId: gameId ?? run['game'] as String?,
      gameName: gameName,
      categoryId: categoryId ?? run['category'] as String?,
      categoryName: categoryName,
      primaryTime: primaryTime,
      date: run['date'] as String?,
    );
  }
}
