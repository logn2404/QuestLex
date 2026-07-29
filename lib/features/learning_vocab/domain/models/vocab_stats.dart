class VocabStats {
  final Map<String, int> levelCounts;

  const VocabStats({
    required this.levelCounts,
  });

  // 1. Tính tổng EXP hiện tại dựa trên hệ số điểm của từng level
  int get currentExp {
    int total = 0;
    total += (levelCounts['A1'] ?? 0) * 1;
    total += (levelCounts['A2'] ?? 0) * 2;
    total += (levelCounts['B1'] ?? 0) * 3;
    total += (levelCounts['B2'] ?? 0) * 5;
    total += (levelCounts['C1'] ?? 0) * 7;
    total += (levelCounts['C2'] ?? 0) * 10;
    return total;
  }

  // 2. Max EXP để đạt Level 100
  int get maxExp => 35000;

  // 3. Tính Level từ 1 -> 100
  int get calculatedLevel {
    if (maxExp == 0) return 1;
    final level = ((currentExp / maxExp) * 100).floor();
    return level.clamp(1, 100);
  }

  // 4. Tỷ lệ % hoàn thành Level 100
  double get expPercentage {
    if (maxExp == 0) return 0.0;
    return (currentExp / maxExp).clamp(0.0, 1.0);
  }

  double get expProgressRatio => expPercentage;

  // 5. Tính tổng số Sao (Thang điểm 6.0)
  double get totalStars {
    double stars = 0.0;
    for (final level in ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']) {
      final count = levelCounts[level] ?? 0;
      stars += (count / 1000).clamp(0.0, 1.0);
    }
    return double.parse(stars.toStringAsFixed(2));
  }
}