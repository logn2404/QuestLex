import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  // Địa chỉ kết nối Local Backend FastAPI
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  /// Kiểm tra trạng thái Server AI
  static Future<bool> checkHealth() async {
    try {
      print('[AI DEBUG] health_request_started');
      final response = await http.get(Uri.parse('http://127.0.0.1:8000/'));
      print('[AI DEBUG] health_response status=${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('[AI DEBUG] health_request_failed error=$e');
      return false;
    }
  }

  /// 🚀 Gửi tín hiệu kích hoạt Python AI quét toàn bộ thư mục images/ chung
  static Future<Map<String, dynamic>?> triggerScanFolder({
    String userId = 'user_dev_01',
    int? durationMs,
  }) async {
    try {
      print('[AI DEBUG] scan_request_started durationMs=$durationMs');
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
      print('[AI DEBUG] scan_request_finished status=${response.statusCode}');

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

  /// Lấy trạng thái của một job scan nền.
  static Future<Map<String, dynamic>?> getScanStatus({
    String? jobId,
  }) async {
    try {
      final queryParameters = <String, String>{
        if (jobId != null && jobId.isNotEmpty) 'job_id': jobId,
      };
      final uri = Uri.parse('$baseUrl/scan-status').replace(
        queryParameters: queryParameters,
      );
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      print('[AI DEBUG] status_response jobId=${jobId ?? 'active'} status=${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        print('[AI DEBUG] status_decoded jobId=${jobId ?? 'active'} state=${decoded['status']}');
        return decoded is Map<String, dynamic> ? decoded : null;
      }
    } catch (e) {
      print('❌ [AIService Status Error]: $e');
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