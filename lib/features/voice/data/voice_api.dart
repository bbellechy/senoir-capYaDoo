import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';

import '../../../core/services/storage/token_storage.dart';

class VoiceApi {
  static Future<Map<String, dynamic>> sendVoice(String path) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/voice/command',
    );

    final request = http.MultipartRequest('POST', uri);

    // Add Auth Token
    final token = await TokenStorage.getToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    print('Sending voice file: $path');
    request.files.add(
      await http.MultipartFile.fromPath('file', path),
    );

    try {
      final response = await request.send();
      final responseBody = await http.Response.fromStream(response);
      
      print('Voice API Status: ${responseBody.statusCode}');
      print('Voice API Body: ${responseBody.body}');

      if (responseBody.statusCode != 200) {
        throw Exception('Server error: ${responseBody.statusCode}');
      }

      if (responseBody.body.isEmpty) {
        throw Exception('Empty response from server');
      }

      return jsonDecode(responseBody.body);
    } catch (e) {
      print('Voice API Exception: $e');
      rethrow;
    }
  }
}
