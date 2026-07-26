class DailyCEFRCount {
  final String label; // VD: "Thứ 2", "T1", "20/07"
  final Map<String, int> countsByLevel; // {'A1': 2, 'A2': 5, 'B1': 3, ...}

  const DailyCEFRCount({
    required this.label,
    required this.countsByLevel,
  });

  int get total => countsByLevel.values.fold(0, (sum, val) => sum + val);
}