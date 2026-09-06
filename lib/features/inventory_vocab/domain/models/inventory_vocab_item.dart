class InventoryVocabItem {
  final String id;
  final String word;
  final String meaning;
  final String cefrLevel; // A1, A2, B1, B2, C1, C2
  final String pos; // Từ loại (NOUN, VERB, ADJ,...)
  final DateTime masteredAt; // Ngày đạt 100% mastery

  const InventoryVocabItem({
    required this.id,
    required this.word,
    required this.meaning,
    required this.cefrLevel,
    required this.pos,
    required this.masteredAt,
  });

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

  factory InventoryVocabItem.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;

    final rawDateObj = json['masteredAt'] ??
        json['createdAt'] ??
        json['created_at'] ??
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

    final rawMeaning = json['meaning'] ??
        json['definition'] ??
        json['vietnamese_meaning'] ??
        json['viMeaning'] ??
        '';
    final rawLevel = json['cefrLevel'] ?? json['level'] ?? json['cefr_level'] ?? 'A1';
    final rawPos = json['pos'] ?? json['type'] ?? json['partOfSpeech'] ?? 'NOUN';

    return InventoryVocabItem(
      id: json['id']?.toString() ?? '',
      word: json['word'] ?? '',
      meaning: rawMeaning.toString(),
      cefrLevel: rawLevel.toString().toUpperCase(),
      pos: rawPos.toString().toUpperCase(),
      masteredAt: parsedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word': word,
      'meaning': meaning,
      'cefrLevel': cefrLevel,
      'pos': pos,
      'masteredAt': masteredAt.toIso8601String(),
    };
  }
}