import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  // Địa chỉ kết nối Local Backend FastAPI
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  /// Kiểm tra trạng thái Server AI
  static Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:8000/'));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// 🚀 Gửi tín hiệu kích hoạt Python AI quét toàn bộ thư mục images/ chung
  static Future<Map<String, dynamic>?> triggerScanFolder({
    String userId = 'user_dev_01',
    int? durationMs,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/scan-images-folder').replace(
        queryParameters: {
          'user_id': userId,
          if (durationMs != null) 'duration_ms': durationMs.toString(),
        },
      );
      
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      print('📡 [AIService Response]: Code ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('⚠️ Server trả về lỗi: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [AIService Error]: $e');
    }
    return null;
  }

  /// Lấy Level từ vựng hiện tại của User
  static Future<String> getUserLevel({String userId = 'user_dev_01'}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/level?user_id=$userId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['level'] ?? 'A1';
      }
    } catch (e) {
      print('❌ [AIService Level Error]: $e');
    }
    return 'A1';
  }

  /// Lấy toàn bộ lịch sử từ vựng
  static Future<List<dynamic>> fetchHistory({String userId = 'user_dev_01'}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/history?user_id=$userId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['history'] ?? [];
      }
    } catch (e) {
      print('❌ [AIService History Error]: $e');
    }
    return [];
  }
}