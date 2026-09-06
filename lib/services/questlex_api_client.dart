import 'dart:convert';

import 'package:http/http.dart' as http;

class QuestLexApiClient {
  final String baseUrl;
  final String userId;
  final Duration timeout;

  const QuestLexApiClient({
    this.baseUrl = 'http://127.0.0.1:8000',
    this.userId = 'user_dev_01',
    this.timeout = const Duration(seconds: 5),
  });

  Uri endpoint(String path, [Map<String, String>? queryParameters]) {
    return Uri.parse('$baseUrl/api/$path').replace(
      queryParameters: {
        'user_id': userId,
        ...?queryParameters,
      },
    );
  }

  Future<Map<String, dynamic>?> getJson(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final response = await http
        .get(
          endpoint(path, queryParameters),
          headers: {'Content-Type': 'application/json'},
        )
        .timeout(timeout);
    return _decodeSuccessfulResponse(response);
  }

  Future<Map<String, dynamic>?> postJson(
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
  }) async {
    final response = await http
        .post(
          endpoint(path, queryParameters),
          headers: {'Content-Type': 'application/json'},
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(timeout);
    return _decodeSuccessfulResponse(response);
  }

  Map<String, dynamic>? _decodeSuccessfulResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    final decoded = jsonDecode(response.body);
    return decoded is Map<String, dynamic> ? decoded : null;
  }
}