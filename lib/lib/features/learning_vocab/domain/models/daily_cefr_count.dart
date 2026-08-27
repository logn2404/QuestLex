class DailyCEFRCount {
  final String label; // VD: "T2", "T3", "Thg 1"
  final Map<String, int> countsByLevel; // {'A1': 2, 'A2': 5, 'B1': 3, ...}

  const DailyCEFRCount({
    required this.label,
    required this.countsByLevel,
  });

  int get total => countsByLevel.values.fold(0, (sum, val) => sum + val);

  factory DailyCEFRCount.fromJson(Map<String, dynamic> json) {
    final rawMap = json['countsByLevel'] as Map<String, dynamic>? ?? {};
    final Map<String, int> parsedMap = rawMap.map(
      (key, value) => MapEntry(key, (value as num).toInt()),
    );

    return DailyCEFRCount(
      label: json['label'] ?? '',
      countsByLevel: parsedMap,
    );
  }
}