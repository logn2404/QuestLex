class InventoryVocabItem {
  final String id;
  final String word;
  final String meaning;
  final String cefrLevel; // A1, A2, B1, B2, C1, C2
  final DateTime masteredAt; // Ngày đạt 100% mastery

  const InventoryVocabItem({
    required this.id,
    required this.word,
    required this.meaning,
    required this.cefrLevel,
    required this.masteredAt,
  });

  // Thứ tự độ khó CEFR để hỗ trợ Sort
  int get difficultyWeight {
    switch (cefrLevel.toUpperCase()) {
      case 'A1': return 1;
      case 'A2': return 2;
      case 'B1': return 3;
      case 'B2': return 4;
      case 'C1': return 5;
      case 'C2': return 6;
      default: return 0;
    }
  }
}