import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/models/inventory_vocab_item.dart';
import '../../domain/repositories/inventory_vocab_repository.dart';

class ApiInventoryVocabRepository implements InventoryVocabRepository {
  // 🎯 CẤU HÌNH ĐƯỜNG DẪN API BACKEND:
  // - Chạy trên Windows / macOS / Web / iOS Simulator: http://127.0.0.1:8000
  // - Chạy trên Android Emulator: http://10.0.2.2:8000
  // - Chạy trên thiết bị thật (Wifi LAN): http://<IP_MÁY_TÍNH>:8000
  final String baseUrl;

  ApiInventoryVocabRepository({this.baseUrl = 'http://127.0.0.1:8000'});

  @override
  Future<List<InventoryVocabItem>> getMasteredVocab() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/inventory?user_id=user_dev_01'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> wordsJson = data['words'] ?? [];
          // 🎯 Parse từng item bằng factory InventoryVocabItem.fromJson
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