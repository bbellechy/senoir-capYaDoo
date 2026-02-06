import 'dart:convert';
import 'package:capyadoo/core/services/api_client.dart';
import 'package:capyadoo/core/model/medication_notification.dart';

class NotificationApiService {
  static const String _basePath = '/notifications';

  // Get all notifications
  static Future<List<MedicationNotification>> getNotifications() async {
    try {
      final response = await ApiClient.get(_basePath);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList
            .map((json) => MedicationNotification.fromJson(json))
            .toList();
      } else {
        print('Failed to load notifications: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  // Create a new notification
  static Future<MedicationNotification?> createNotification(
    MedicationNotification notification,
  ) async {
    try {
      final response = await ApiClient.post(_basePath, notification.toJson());

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        return MedicationNotification.fromJson(jsonResponse);
      } else {
        print('Failed to create notification: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error creating notification: $e');
      return null;
    }
  }

  // Update an existing notification
  static Future<MedicationNotification?> updateNotification(
    MedicationNotification notification,
  ) async {
    try {
      if (notification.id == null) {
        print('Cannot update notification without ID');
        return null;
      }

      final response = await ApiClient.put(
        '$_basePath/${notification.id}',
        notification.toJson(),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return MedicationNotification.fromJson(jsonResponse);
      } else {
        print('Failed to update notification: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error updating notification: $e');
      return null;
    }
  }

  // Delete a notification
  static Future<bool> deleteNotification(String id) async {
    try {
      final response = await ApiClient.delete('$_basePath/$id');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        print('Failed to delete notification: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error deleting notification: $e');
      return false;
    }
  }
}
