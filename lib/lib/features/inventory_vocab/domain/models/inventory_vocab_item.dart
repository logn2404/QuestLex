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

  // 🛠️ FIX: Factory Constructor parse từ JSON với cơ chế an toàn tuyệt đối
  factory InventoryVocabItem.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    
    // 1. Kiểm tra tất cả các key ngày tháng có thể có từ Backend
    final rawDateObj = json['masteredAt'] ?? json['createdAt'] ?? json['created_at'];
    final String rawDateStr = rawDateObj?.toString().trim() ?? '';

    if (rawDateStr.isNotEmpty) {
      try {
        // 🛠️ CHUẨN HÓA ISO: Thay khoảng trắng thành 'T' (Ví dụ: "2026-08-10 11:47:28" -> "2026-08-10T11:47:28")
        // Đây là bước quan trọng nhất để DateTime.parse không bị nổ exception [1, 2].
        final formattedIsoStr = rawDateStr.contains(' ') 
            ? rawDateStr.replaceFirst(' ', 'T') 
            : rawDateStr;
        parsedDate = DateTime.parse(formattedIsoStr);
      } catch (_) {
        parsedDate = DateTime.now(); // Fallback nếu định dạng chuỗi vẫn lỗi
      }
    } else {
      parsedDate = DateTime.now(); // Fallback nếu không có dữ liệu ngày tháng
    }

    return InventoryVocabItem(
      // Ép kiểu String an toàn để tránh lỗi Null check operator [2]
      id: json['id']?.toString() ?? '',
      word: json['word'] ?? '',
      meaning: json['meaning'] ?? '',
      cefrLevel: json['cefrLevel'] ?? 'A1',
      pos: json['pos'] ?? 'NOUN',
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