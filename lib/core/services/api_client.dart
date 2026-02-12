import 'dart:convert';
import 'package:http/http.dart' as http;
import './storage/token_storage.dart';
import '../config/api_config.dart';

class ApiClient {
  static String get baseUrl => '${ApiConfig.baseUrl}/api';

  static String _previewBody(List<int> bytes) {
    try {
      final s = utf8.decode(bytes);
      if (s.length <= 500) return s;
      return '${s.substring(0, 500)}...';
    } catch (_) {
      return '<non-utf8 body>';
    }
  }

  static Future<http.Response> get(String path) async {
    final token = await TokenStorage.getToken();
    print('TOKEN => $token');
    print('GET => $baseUrl$path');
    try {
      final resp = await http
          .get(
            Uri.parse('$baseUrl$path'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));
      print('GET <= ${resp.statusCode} ${_previewBody(resp.bodyBytes)}');
      return resp;
    } catch (e) {
      print('GET !! error: $e');
      rethrow;
    }
  }

  static Future<http.Response> post(
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final token = await TokenStorage.getToken();

    print('POST => $baseUrl$path');
    try {
      final resp = await http
          .post(
            Uri.parse('$baseUrl$path'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 10));
      print('POST <= ${resp.statusCode} ${_previewBody(resp.bodyBytes)}');
      return resp;
    } catch (e) {
      print('POST !! error: $e');
      rethrow;
    }
  }

  static Future<http.Response> postWithoutToken(
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    print('POST(no-token) => $baseUrl$path');
    try {
      final resp = await http
          .post(
            Uri.parse('$baseUrl$path'),
            headers: {'Content-Type': 'application/json'},
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 10));
      print(
        'POST(no-token) <= ${resp.statusCode} ${_previewBody(resp.bodyBytes)}',
      );
      return resp;
    } catch (e) {
      print('POST(no-token) !! error: $e');
      rethrow;
    }
  }

  static Future<http.Response> put(
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final token = await TokenStorage.getToken();

    print('PUT => $baseUrl$path');
    try {
      final resp = await http
          .put(
            Uri.parse('$baseUrl$path'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 10));
      print('PUT <= ${resp.statusCode} ${_previewBody(resp.bodyBytes)}');
      return resp;
    } catch (e) {
      print('PUT !! error: $e');
      rethrow;
    }
  }

  static Future<http.Response> delete(String path) async {
    final token = await TokenStorage.getToken();

    print('DELETE => $baseUrl$path');
    try {
      final resp = await http
          .delete(
            Uri.parse('$baseUrl$path'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));
      print('DELETE <= ${resp.statusCode} ${_previewBody(resp.bodyBytes)}');
      return resp;
    } catch (e) {
      print('DELETE !! error: $e');
      rethrow;
    }
  }
}
