import 'dart:convert';
import 'package:http/http.dart' as http;
import './storage/token_storage.dart';

class ApiClient {
  static const String baseUrl = 'http://10.0.2.2:8080/api';

  static Future<http.Response> get(String path) async {
    final token = await TokenStorage.getToken();
    print('TOKEN => $token');
    return http.get(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }

  static Future<http.Response> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final token = await TokenStorage.getToken();

    return http.post(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> put(
    String path,
    Map<String, dynamic> body,
  ) async {
    final token = await TokenStorage.getToken();

    return http.put(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> delete(String path) async {
    final token = await TokenStorage.getToken();

    return http.delete(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }
}
