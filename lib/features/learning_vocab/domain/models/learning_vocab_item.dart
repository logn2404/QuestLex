class LearningVocabItem {
  final String id;
  final String word;
  final String meaning;
  final String cefrLevel; // A1, A2, B1, B2, C1, C2
  final int currentProgress; // Ví dụ: 99
  final int maxProgress; // Ví dụ: 100

  const LearningVocabItem({
    required this.id,
    required this.word,
    required this.meaning,
    required this.cefrLevel,
    required this.currentProgress,
    this.maxProgress = 100,
  });

  double get progressPercentage => (currentProgress / maxProgress).clamp(0.0, 1.0);
}