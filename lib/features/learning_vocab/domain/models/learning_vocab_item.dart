class LearningVocabItem {
  final String id;
  final String word;
  final String meaning;
  final String cefrLevel;
  final int currentProgress;
  final int maxProgress;
  final DateTime createdAt;

  const LearningVocabItem({
    required this.id,
    required this.word,
    required this.meaning,
    required this.cefrLevel,
    required this.currentProgress,
    required this.createdAt,
    this.maxProgress = 100,
  });

  double get progressPercentage => (currentProgress / maxProgress).clamp(0.0, 1.0);

  factory LearningVocabItem.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    final rawDateObj = json['createdAt'] ?? json['created_at'] ?? json['masteredAt'];
    final String rawDateStr = rawDateObj?.toString().trim() ?? '';

    if (rawDateStr.isNotEmpty) {
      try {
        // 🛠️ CHUYỂN ĐỔI CHUẨN ISO: Thay khoảng trắng thành 'T' (VD: "2026-08-10 11:47:28" -> "2026-08-10T11:47:28")
        final formattedIsoStr = rawDateStr.contains(' ') 
            ? rawDateStr.replaceFirst(' ', 'T') 
            : rawDateStr;
        parsedDate = DateTime.parse(formattedIsoStr);
      } catch (e) {
        parsedDate = DateTime.now(); // Fallback an toàn
      }
    } else {
      parsedDate = DateTime.now();
    }

    return LearningVocabItem(
      id: json['id']?.toString() ?? '',
      word: json['word'] ?? '',
      meaning: json['meaning'] ?? '',
      cefrLevel: json['cefrLevel'] ?? 'A1',
      currentProgress: (json['currentProgress'] as num?)?.toInt() ?? 0,
      createdAt: parsedDate,
      maxProgress: (json['maxProgress'] as num?)?.toInt() ?? 100,
    );
  }
}