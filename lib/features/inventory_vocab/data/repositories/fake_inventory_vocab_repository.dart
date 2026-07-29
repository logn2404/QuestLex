import '../../domain/models/inventory_vocab_item.dart';
import '../../domain/repositories/inventory_vocab_repository.dart';

class FakeInventoryVocabRepository implements InventoryVocabRepository {
  @override
  Future<List<InventoryVocabItem>> getMasteredVocab() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      InventoryVocabItem(
        id: 'inv_1',
        word: 'Abundant',
        meaning: 'Dồi dào, phong phú',
        cefrLevel: 'C1',
        masteredAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      InventoryVocabItem(
        id: 'inv_2',
        word: 'Benchmark',
        meaning: 'Điểm chuẩn, tiêu chuẩn đánh giá',
        cefrLevel: 'B2',
        masteredAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      InventoryVocabItem(
        id: 'inv_3',
        word: 'Cognitive',
        meaning: 'Liên quan đến nhận thức',
        cefrLevel: 'C2',
        masteredAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      InventoryVocabItem(
        id: 'inv_4',
        word: 'Database',
        meaning: 'Cơ sở dữ liệu',
        cefrLevel: 'A2',
        masteredAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      InventoryVocabItem(
        id: 'inv_5',
        word: 'Ecosystem',
        meaning: 'Hệ sinh thái',
        cefrLevel: 'B1',
        masteredAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
      InventoryVocabItem(
        id: 'inv_6',
        word: 'Framework',
        meaning: 'Khung làm việc / Cấu trúc',
        cefrLevel: 'B2',
        masteredAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
    ];
  }
}