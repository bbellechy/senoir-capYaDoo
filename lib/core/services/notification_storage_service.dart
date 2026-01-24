import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:capyadoo/core/model/medication_notification.dart';

class NotificationStorageService {
  static const _storage = FlutterSecureStorage();
  static const _notificationsKey = 'medication_notifications';

  // Load all notifications from local storage
  static Future<List<MedicationNotification>> loadNotifications() async {
    try {
      final String? jsonString = await _storage.read(key: _notificationsKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((json) => MedicationNotification.fromJson(json))
          .toList();
    } catch (e) {
      print('Error loading notifications: $e');
      return [];
    }
  }

  // Save all notifications to local storage
  static Future<void> saveNotifications(
    List<MedicationNotification> notifications,
  ) async {
    try {
      final jsonList = notifications.map((n) => n.toJson()).toList();
      final jsonString = json.encode(jsonList);
      await _storage.write(key: _notificationsKey, value: jsonString);
    } catch (e) {
      print('Error saving notifications: $e');
    }
  }

  // Add a new notification
  static Future<void> addNotification(
    MedicationNotification notification,
  ) async {
    final notifications = await loadNotifications();
    notifications.add(notification);
    await saveNotifications(notifications);
  }

  // Update an existing notification
  static Future<void> updateNotification(
    MedicationNotification notification,
  ) async {
    final notifications = await loadNotifications();
    final index = notifications.indexWhere((n) => n.id == notification.id);
    if (index != -1) {
      notifications[index] = notification;
      await saveNotifications(notifications);
    }
  }

  // Delete a notification
  static Future<void> deleteNotification(String id) async {
    final notifications = await loadNotifications();
    notifications.removeWhere((n) => n.id == id);
    await saveNotifications(notifications);
  }

  // Clear all notifications
  static Future<void> clearAll() async {
    await _storage.delete(key: _notificationsKey);
  }
}
