import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/models/daily_cefr_count.dart';
import '../../domain/models/learning_vocab_item.dart';
import '../../domain/repositories/learning_vocab_repository.dart';

class ApiLearningVocabRepository implements LearningVocabRepository {
  // 🎯 CẤU HÌNH ĐƯỜNG DẪN MẠNG BACKEND:
  // - iOS Simulator / Windows / macOS / Web: http://127.0.0.1:8000
  // - Android Emulator: http://10.0.2.2:8000
  final String baseUrl;

  ApiLearningVocabRepository({this.baseUrl = 'http://127.0.0.1:8000'});

  @override
  Future<List<LearningVocabItem>> getLearningVocab() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/learning?user_id=user_dev_01'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> wordsJson = data['words'] ?? [];
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
  Future<List<DailyCEFRCount>> getDailyStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/learning/stats?user_id=user_dev_01'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> dailyJson = data['dailyStats'] ?? [];
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
      final response = await http.get(
        Uri.parse('$baseUrl/api/learning/stats?user_id=user_dev_01'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> monthlyJson = data['monthlyStats'] ?? [];
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