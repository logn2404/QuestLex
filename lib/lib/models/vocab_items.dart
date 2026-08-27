class VocabItem {
  final String id;
  final String word;
  final String type;
  final String meaning;

  const VocabItem({
    required this.id,
    required this.word,
    required this.type,
    required this.meaning,
  });

  // Chuyển đổi dữ liệu (dùng khi nối C++ FFI / Database sau này)
  factory VocabItem.fromMap(Map<String, String> map) {
    return VocabItem(
      id: map['id'] ?? '',
      word: map['word'] ?? '',
      type: map['type'] ?? '',
      meaning: map['meaning'] ?? '',
    );
  }
}