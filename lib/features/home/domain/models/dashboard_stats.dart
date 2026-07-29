class DashboardStats {
  final int totalInventoryVocab;
  final int inventoryMonthlyDiff; // Chênh lệch so với tháng trước (+320)

  final int totalLearningVocab;
  final int learningMonthlyDiff;  // Chênh lệch so với tháng trước (-20)

  final int pendingVocab;
  final int streakDays;

  const DashboardStats({
    required this.totalInventoryVocab,
    required this.inventoryMonthlyDiff,
    required this.totalLearningVocab,
    required this.learningMonthlyDiff,
    required this.pendingVocab,
    required this.streakDays,
  });
}