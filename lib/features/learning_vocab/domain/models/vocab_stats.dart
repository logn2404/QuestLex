class VocabStats {
  final int overallScore; // Điểm level/mastery (VD: 61)
  final int starRating;   // Số sao (0 - 6)
  final Map<String, int> levelCounts;
  final double currentExp; // Ví dụ: 65
  final double maxExp;     // Ví dụ: 100

  const VocabStats({
    required this.overallScore,
    required this.starRating,
    required this.levelCounts,
    this.currentExp = 65.0, // 👈 Đặt giá trị mặc định ở đây
    this.maxExp = 100.0,    // 👈 Đặt giá trị mặc định ở đây
  });

  double get expPercentage => (maxExp > 0) ? (currentExp / maxExp).clamp(0.0, 1.0) : 0.0;
}