import 'dart:convert';
import 'package:capyadoo/core/services/api_client.dart';
import 'package:capyadoo/core/services/storage/token_storage.dart';
import 'package:capyadoo/core/model/user.dart';
import 'package:capyadoo/core/services/notification_storage_service.dart';
import 'package:capyadoo/core/services/notification_service.dart';

class AuthService {
  static Future<bool> login(String username, String password) async {
    try {
      final response = await ApiClient.postWithoutToken('/auth/login', {
        'username': username,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'] ?? data['accessToken'];
        if (token != null) {
          await TokenStorage.saveToken(token);
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  static Future<bool> register(
    String username,
    String fullName,
    String password,
  ) async {
    try {
      final response = await ApiClient.postWithoutToken('/auth/register', {
        'username': username,
        'fullName': fullName,
        'password': password,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Optionally auto-login after registration
        return await login(username, password);
      }
      return false;
    } catch (e) {
      print('Register error: $e');
      return false;
    }
  }

  static Future<User?> getProfile() async {
    try {
      final response = await ApiClient.get('/profile');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return User.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Get profile error: $e');
      return null;
    }
  }

  static Future<void> logout() async {
    await TokenStorage.clear();
    // Clear local notifications data to prevent isolation issues
    try {
      await NotificationStorageService.clearAll();
      await NotificationService.cancelAllNotifications();
      print('AuthService: Local notifications cleared on logout');
    } catch (e) {
      print('AuthService: Error clearing notifications on logout: $e');
    }
  }

  static Future<bool> isLoggedIn() async {
    final token = await TokenStorage.getToken();
    return token != null;
  }
}
