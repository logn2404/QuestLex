class DashboardStats {
  final int totalVocab;
  final int addedVocab;
  final int learningVocab;
  final int masterChange;
  final int pendingVocab;
  final int streakDays;

  const DashboardStats({
    required this.totalVocab,
    required this.addedVocab,
    required this.learningVocab,
    required this.masterChange,
    required this.pendingVocab,
    required this.streakDays,
  });
}
