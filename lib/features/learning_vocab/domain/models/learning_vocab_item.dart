class LearningVocabItem {
  final String id;
  final String word;
  final String meaning;
  final String definition;
  final String vietnameseMeaning;
  final String cefrLevel;
  final int currentProgress;
  final int maxProgress;
  final DateTime createdAt;

  const LearningVocabItem({
    required this.id,
    required this.word,
    required this.meaning,
    required this.definition,
    required this.vietnameseMeaning,
    required this.cefrLevel,
    required this.currentProgress,
    required this.createdAt,
    this.maxProgress = 100,
  });

  double get progressPercentage => (currentProgress / maxProgress).clamp(0.0, 1.0);

  factory LearningVocabItem.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    final rawDateObj = json['createdAt'] ??
        json['created_at'] ??
        json['masteredAt'] ??
        json['last_reviewed'];
    final String rawDateStr = rawDateObj?.toString().trim() ?? '';

    if (rawDateStr.isNotEmpty) {
      try {
        final formattedIsoStr = rawDateStr.contains(' ')
            ? rawDateStr.replaceFirst(' ', 'T')
            : rawDateStr;
        parsedDate = DateTime.parse(formattedIsoStr);
      } catch (_) {
        parsedDate = DateTime.now();
      }
    } else {
      parsedDate = DateTime.now();
    }

    final rawEnglishDefinition = json['definition'] ??
        json['meaning'] ??
        json['english_definition'] ??
        json['en_definition'] ??
        '';
    final rawVietnameseMeaning = json['vietnamese_meaning'] ??
        json['viMeaning'] ??
        json['meaning_vi'] ??
        json['vn_meaning'] ??
        '';
    final rawLevel = json['cefrLevel'] ??
        json['level'] ??
        json['cefr_level'] ??
        'A1';
    final rawCurrentProgress = json['currentProgress'] ??
        json['progress'] ??
        json['mastery_score'];

    int currentProgress = 0;
    if (rawCurrentProgress is num) {
      final value = rawCurrentProgress.toDouble();
      if (value <= 1.0) {
        currentProgress = (value * 100).round();
      } else {
        currentProgress = value.round();
      }
    }

    final englishDefinition = rawEnglishDefinition.toString();
    final vietnameseDefinition = rawVietnameseMeaning.toString();

    return LearningVocabItem(
      id: json['id']?.toString() ?? '',
      word: json['word'] ?? '',
        meaning: vietnameseDefinition.isNotEmpty
          ? vietnameseDefinition
          : englishDefinition,
      definition: englishDefinition,
      vietnameseMeaning: vietnameseDefinition,
      cefrLevel: rawLevel.toString().toUpperCase(),
      currentProgress: currentProgress.clamp(0, 100),
      createdAt: parsedDate,
      maxProgress: (json['maxProgress'] as num?)?.toInt() ?? 100,
    );
  }
}