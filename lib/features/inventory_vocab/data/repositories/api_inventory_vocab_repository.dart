import '../../domain/models/inventory_vocab_item.dart';
import '../../domain/repositories/inventory_vocab_repository.dart';
import '../../../../services/questlex_api_client.dart';

class ApiInventoryVocabRepository implements InventoryVocabRepository {
  final QuestLexApiClient apiClient;

  ApiInventoryVocabRepository({
    String baseUrl = 'http://127.0.0.1:8000',
    QuestLexApiClient? apiClient,
  }) : apiClient = apiClient ?? QuestLexApiClient(baseUrl: baseUrl);

  @override
  Future<List<InventoryVocabItem>> getMasteredVocab() async {
    try {
      final data = await apiClient.getJson('inventory');
      if (data?['success'] == true) {
        final wordsJson = data?['words'];
        if (wordsJson is List) {
          return wordsJson
              .map((json) => InventoryVocabItem.fromJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('❌ [Inventory Repo Error]: Lỗi kết nối API -> $e');
      return [];
    }
  }
}