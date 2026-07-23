import '../models/vocab_items.dart';

class VocabRepository {
  List<VocabItem> getLearningVocabs() {
    try {
      return const [
        VocabItem(id: '1', word: 'Algorithm', type: 'noun', meaning: 'Thuật toán'),
        VocabItem(id: '2', word: 'Optimization', type: 'noun', meaning: 'Tối ưu hóa'),
        VocabItem(id: '3', word: 'Asynchronous', type: 'adj', meaning: 'Bất đồng bộ'),
      ];
    } catch (e) {
      // Trả về danh sách rỗng nếu có lỗi để tránh sập app
      return [];
    }
  }

  int get totalVocabCount => 1240;
  int get masteredVocabCount => 850;
}