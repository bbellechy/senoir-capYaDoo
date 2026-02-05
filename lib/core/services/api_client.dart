import 'dart:convert';
import 'package:http/http.dart' as http;
import './storage/token_storage.dart';
import '../config/api_config.dart';

class ApiClient {
  static String get baseUrl => '${ApiConfig.baseUrl}/api';

  static Future<http.Response> get(String path) async {
    final token = await TokenStorage.getToken();
    print('TOKEN => $token');
    return http
        .get(
          Uri.parse('$baseUrl$path'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 10));
  }

  static Future<http.Response> post(
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final token = await TokenStorage.getToken();

    return http
        .post(
          Uri.parse('$baseUrl$path'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(const Duration(seconds: 10));
  }

  static Future<http.Response> postWithoutToken(
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    return http
        .post(
          Uri.parse('$baseUrl$path'),
          headers: {'Content-Type': 'application/json'},
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(const Duration(seconds: 10));
  }

  static Future<http.Response> put(
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final token = await TokenStorage.getToken();

    return http
        .put(
          Uri.parse('$baseUrl$path'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(const Duration(seconds: 10));
  }

  static Future<http.Response> delete(String path) async {
    final token = await TokenStorage.getToken();

    return http
        .delete(
          Uri.parse('$baseUrl$path'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 10));
  }
}
