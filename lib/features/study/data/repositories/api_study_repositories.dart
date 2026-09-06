import '../../../../services/questlex_api_client.dart';

class ApiStudyRepository {
  final QuestLexApiClient apiClient;

  ApiStudyRepository({
    String baseUrl = 'http://127.0.0.1:8000',
    QuestLexApiClient? apiClient,
  }) : apiClient = apiClient ?? QuestLexApiClient(baseUrl: baseUrl);

  // Lấy <= 30 từ vựng cho mode STUDY hoặc PRACTICE
  Future<List<Map<String, dynamic>>> getStudyWords({
    int limit = 30,
    String mode = 'study',
  }) async {
    try {
      final data = await apiClient.getJson(
        'flashcards',
        queryParameters: {
          'limit': limit.toString(),
          'mode': mode,
        },
      );
      if (data?['success'] == true && data?['flashcards'] is List) {
        return (data!['flashcards'] as List)
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
      return [];
    } catch (e) {
      print('❌ [Study Repo] Lỗi tải từ vựng: $e');
      return [];
    }
  }

  // Gửi điểm đánh giá (1-4) về Backend cập nhật Mastery
  Future<bool> reviewWord(String word, int quality) async {
    try {
      final data = await apiClient.postJson(
        'flashcards/review',
        body: {
          'word': word,
          'quality': quality,
        },
      );
      return data?['success'] == true;
    } catch (e) {
      print('❌ [Study Repo] Lỗi chấm điểm: $e');
      return false;
    }
  }
}