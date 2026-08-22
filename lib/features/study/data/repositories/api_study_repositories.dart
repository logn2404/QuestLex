import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiStudyRepository {
  final String baseUrl;

  ApiStudyRepository({this.baseUrl = 'http://127.0.0.1:8000'});

  // Lấy <= 30 từ vựng cho mode STUDY hoặc PRACTICE
  Future<List<Map<String, dynamic>>> getStudyWords({
    int limit = 30,
    String mode = 'study',
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/flashcards?limit=$limit&mode=$mode&user_id=user_dev_01'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['flashcards'] ?? []);
        }
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
      final response = await http.post(
        Uri.parse('$baseUrl/api/flashcards/review'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'word': word,
          'quality': quality,
          'user_id': 'user_dev_01'
        }),
      );
      
      final data = jsonDecode(response.body);
      return data['success'] == true;
    } catch (e) {
      print('❌ [Study Repo] Lỗi chấm điểm: $e');
      return false;
    }
  }
}