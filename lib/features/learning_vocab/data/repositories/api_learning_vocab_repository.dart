import '../../domain/models/daily_cefr_count.dart';
import '../../domain/models/learning_vocab_item.dart';
import '../../domain/repositories/learning_vocab_repository.dart';
import '../../../../services/questlex_api_client.dart';

class ApiLearningVocabRepository implements LearningVocabRepository {
  final QuestLexApiClient apiClient;

  ApiLearningVocabRepository({
    String baseUrl = 'http://127.0.0.1:8000',
    QuestLexApiClient? apiClient,
  }) : apiClient = apiClient ?? QuestLexApiClient(baseUrl: baseUrl);

  @override
  Future<List<LearningVocabItem>> getLearningVocab() async {
    try {
      final data = await apiClient.getJson('learning');
      if (data?['success'] == true) {
          final wordsJson = data?['words'];
          if (wordsJson is List) {
          return wordsJson
              .map((json) => LearningVocabItem.fromJson(json))
              .toList();
          }
      }
      return [];
    } catch (e) {
      print('❌ [Learning Repo Error]: Lỗi kết nối API lấy danh sách từ -> $e');
      return [];
    }
  }

  @override
  Future<List<LearningVocabItem>> getMasteredVocabForAnalytics() async {
    try {
      final data = await apiClient.getJson('inventory');
      if (data?['success'] == true) {
          final wordsJson = data?['words'];
          if (wordsJson is List) {
          return wordsJson.map((json) {
            final item = Map<String, dynamic>.from(json as Map);
            final masteredAt = item['masteredAt'] ??
                item['createdAt'] ??
                item['created_at'];
            return LearningVocabItem.fromJson({
              ...item,
              'createdAt': masteredAt,
              'currentProgress': 100,
              'maxProgress': 100,
            });
          }).toList();
          }
      }
      return [];
    } catch (e) {
      print('❌ [Learning Analytics Error]: Lỗi lấy từ đã mastery -> $e');
      return [];
    }
  }

  @override
  Future<List<DailyCEFRCount>> getDailyStats() async {
    try {
      final data = await apiClient.getJson('learning/stats');
      if (data?['success'] == true) {
          final dailyJson = data?['dailyStats'];
          if (dailyJson is List) {
          return dailyJson
              .map((json) => DailyCEFRCount.fromJson(json))
              .toList();
          }
      }
      return [];
    } catch (e) {
      print('❌ [Learning Daily Stats Error]: $e');
      return [];
    }
  }

  @override
  Future<List<DailyCEFRCount>> getMonthlyStats() async {
    try {
      final data = await apiClient.getJson('learning/stats');
      if (data?['success'] == true) {
          final monthlyJson = data?['monthlyStats'];
          if (monthlyJson is List) {
          return monthlyJson
              .map((json) => DailyCEFRCount.fromJson(json))
              .toList();
          }
      }
      return [];
    } catch (e) {
      print('❌ [Learning Monthly Stats Error]: $e');
      return [];
    }
  }
}