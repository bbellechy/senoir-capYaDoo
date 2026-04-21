import 'dart:convert';
import 'package:capyadoo/core/services/api_client.dart';
import 'package:capyadoo/core/services/storage/token_storage.dart';
import 'package:capyadoo/core/model/user.dart';
import 'package:capyadoo/core/services/notification_storage_service.dart';
import 'package:capyadoo/core/services/notification_service.dart';

class OtpRequestResult {
  final bool success;
  final String? otpSessionId;
  final String? message;

  const OtpRequestResult({
    required this.success,
    this.otpSessionId,
    this.message,
  });
}

class OtpVerifyResult {
  final bool success;
  final String? resetToken;
  final String? message;

  const OtpVerifyResult({required this.success, this.resetToken, this.message});
}

class AuthService {
  static Map<String, dynamic>? _tryParseBody(String body) {
    if (body.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

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
    String phoneNumber,
    String password,
  ) async {
    try {
      final response = await ApiClient.postWithoutToken('/auth/register', {
        'username': username,
        'fullName': fullName,
        'phoneNumber': phoneNumber,
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
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          if (decoded['data'] is Map<String, dynamic>) {
            return User.fromJson(decoded['data'] as Map<String, dynamic>);
          }
          if (decoded['profile'] is Map<String, dynamic>) {
            return User.fromJson(decoded['profile'] as Map<String, dynamic>);
          }
          if (decoded['user'] is Map<String, dynamic>) {
            return User.fromJson(decoded['user'] as Map<String, dynamic>);
          }
          return User.fromJson(decoded);
        }
      }
      return null;
    } catch (e) {
      print('Get profile error: $e');
      return null;
    }
  }

  static Future<bool> updateProfile({
    required String fullName,
    required String username,
    required String phoneNumber,
  }) async {
    try {
      final response = await ApiClient.put('/profile', {
        'fullName': fullName,
        'username': username,
        'phoneNumber': phoneNumber,
      });

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Update profile error: $e');
      return false;
    }
  }

  static Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    try {
      final response = await ApiClient.put('/auth/change-password', {
        'oldPassword': currentPassword,
        'newPassword': newPassword,
        'confirmNewPassword': confirmNewPassword,
      });

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Change password error: $e');
      return false;
    }
  }

  static Future<OtpRequestResult> requestForgotPasswordOtp({
    required String phoneNumber,
  }) async {
    try {
      final response = await ApiClient.postWithoutToken(
        '/auth/forgot-password/request-otp',
        {'phoneNumber': phoneNumber},
      );
      final body = _tryParseBody(response.body);
      final success = response.statusCode == 200 || response.statusCode == 201;

      return OtpRequestResult(
        success: success,
        otpSessionId: body?['otpSessionId']?.toString(),
        message: body?['message']?.toString(),
      );
    } catch (e) {
      print('Request OTP error: $e');
      return const OtpRequestResult(success: false);
    }
  }

  static Future<OtpVerifyResult> verifyForgotPasswordOtp({
    required String phoneNumber,
    required String otpCode,
  }) async {
    try {
      final response = await ApiClient.postWithoutToken(
        '/auth/forgot-password/verify-otp',
        {'phoneNumber': phoneNumber, 'otpCode': otpCode},
      );
      final body = _tryParseBody(response.body);
      final success = response.statusCode == 200 || response.statusCode == 201;

      return OtpVerifyResult(
        success: success,
        resetToken: body?['resetToken']?.toString(),
        message: body?['message']?.toString(),
      );
    } catch (e) {
      print('Verify OTP error: $e');
      return const OtpVerifyResult(success: false);
    }
  }

  static Future<bool> resetPasswordWithOtpToken({
    required String resetToken,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    try {
      final response = await ApiClient.postWithoutToken(
        '/auth/forgot-password/reset-password',
        {
          'resetToken': resetToken,
          'newPassword': newPassword,
          'confirmNewPassword': confirmNewPassword,
        },
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Reset password with OTP token error: $e');
      return false;
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
