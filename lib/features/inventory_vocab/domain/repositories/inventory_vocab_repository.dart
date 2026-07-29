import '../models/inventory_vocab_item.dart';

abstract class InventoryVocabRepository {
  Future<List<InventoryVocabItem>> getMasteredVocab();
}