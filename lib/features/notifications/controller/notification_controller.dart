import 'package:flutter/material.dart';
import 'package:capyadoo/core/model/medication_notification.dart';
import 'package:capyadoo/core/services/notification_service.dart';
import 'package:capyadoo/core/services/notification_storage_service.dart';
import 'package:capyadoo/features/notifications/data/notification_api_service.dart';
import 'package:capyadoo/core/services/pill_box_service.dart';
import 'package:capyadoo/core/services/search_master_medication_api.dart';
import 'package:capyadoo/core/services/medication_schedule_service.dart';
import 'package:capyadoo/core/model/daily_intake.dart';

class NotificationController extends ChangeNotifier {
  List<MedicationNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<MedicationNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load notifications from local storage and backend
  Future<void> loadNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Load from local storage first (for offline access)
      final localNotifications =
          await NotificationStorageService.loadNotifications();
      _notifications = _sortNotifications(localNotifications);
      notifyListeners();

      // Then try to sync with backend (optional)
      try {
        final backendNotifications =
            await NotificationApiService.getNotifications();
        if (backendNotifications.isNotEmpty) {
          // Merge logic: preserve local imagePath if backend doesn't have it
          final mergedNotifications = backendNotifications.map((backend) {
            final local = _notifications.firstWhere(
              (n) => n.id == backend.id,
              orElse: () => backend,
            );
            return backend.copyWith(
              imagePath: backend.imagePath ?? local.imagePath,
            );
          }).toList();

          _notifications = _sortNotifications(mergedNotifications);
          // Update local storage with merged data
          await NotificationStorageService.saveNotifications(_notifications);
          notifyListeners();
        }
      } catch (backendError) {
        // Backend error is not critical, we can work with local storage
        print('Backend sync failed (working offline): $backendError');
      }

      // Overdue check logic
      await _checkOverdueMedications();
    } catch (e) {
      _error = 'เกิดข้อผิดพลาดในการโหลดข้อมูล: $e';
      print('Error loading notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Check for medications that are late by > 15 minutes
  Future<void> _checkOverdueMedications() async {
    try {
      final now = DateTime.now();
      final todaySchedules = await MedicationScheduleService.getDailySchedule(
        now,
      );

      for (final schedule in todaySchedules) {
        if (schedule.status == IntakeStatus.PENDING) {
          final timeParts = schedule.time.split(':');
          if (timeParts.length >= 2) {
            final hour = int.tryParse(timeParts[0]) ?? 0;
            final minute = int.tryParse(timeParts[1]) ?? 0;
            final scheduleTime = DateTime(
              now.year,
              now.month,
              now.day,
              hour,
              minute,
            );

            // If current time has passed the scheduled time, mark as overdue immediately
            if (now.isAfter(scheduleTime)) {
              print(
                'Medication ${schedule.medicationName} is overdue. Updating status.',
              );
              await MedicationScheduleService.markAsOverdue(schedule.intakeId);
            }
          }
        }
      }
    } catch (e) {
      print('Error checking overdue medications: $e');
    }
  }

  // Helper to keep notifications sorted by ID (creation order)
  List<MedicationNotification> _sortNotifications(
    List<MedicationNotification> list,
  ) {
    final sortedList = List<MedicationNotification>.from(list);
    sortedList.sort((a, b) {
      if (a.id == null || b.id == null) return 0;
      return a.id!.compareTo(b.id!);
    });
    return sortedList;
  }

  // Add a new notification
  Future<bool> addNotification(MedicationNotification notification) async {
    try {
      MedicationNotification notificationToSave = notification;

      // Ensure image is saved permanently if it's a temporary/camera path
      if (notificationToSave.imagePath != null &&
          !notificationToSave.imagePath!.contains('notification_images')) {
        final permanentPath = await NotificationService.saveImageToAppStorage(
          notificationToSave.imagePath!,
        );
        if (permanentPath != null) {
          notificationToSave = notificationToSave.copyWith(
            imagePath: permanentPath,
          );
        }
      }

      // Logic to find image from Pill Box if not provided
      if (notificationToSave.imagePath == null) {
        try {
          final pillBoxService = PillBoxService();
          final boxes = await pillBoxService.getAllPillBoxes();

          String? foundImagePath;

          // Search for medication name in boxes
          // This is a heavy operation as we might need to fetch medication details
          // We iterate boxes, then IDs.
          outerLoop:
          for (final box in boxes) {
            if (box.medicationIds.isEmpty) continue;

            // Check each medication in the box
            for (final medId in box.medicationIds) {
              final med = await SearchMedicationApi.getById(medId);
              if (med != null) {
                // Check Thai or English name
                if (med.name.trim() == notification.medicationName.trim()) {
                  foundImagePath = box.imagePath;
                  break outerLoop;
                }
              }
            }
          }

          if (foundImagePath != null) {
            notificationToSave = notificationToSave.copyWith(
              imagePath: foundImagePath,
            );
          }
        } catch (e) {
          print('Error looking up pill box image: $e');
        }
      }

      // Try to send to backend first
      try {
        final createdNotification =
            await NotificationApiService.createNotification(notificationToSave);
        if (createdNotification != null) {
          // Preserve local imagePath if backend doesn't return it
          notificationToSave = createdNotification.copyWith(
            imagePath:
                createdNotification.imagePath ?? notificationToSave.imagePath,
          );
        }
      } catch (backendError) {
        // Backend failed, generate local ID
        print('Backend save failed, working offline: $backendError');
        notificationToSave = notification.copyWith(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
        );
      }

      // Save to local storage
      await NotificationStorageService.addNotification(notificationToSave);

      // Schedule local notifications
      await _scheduleNotification(notificationToSave);

      // Reload notifications
      await loadNotifications();
      return true;
    } catch (e) {
      _error = 'เกิดข้อผิดพลาด: $e';
      notifyListeners();
      print('Error adding notification: $e');
      return false;
    }
  }

  // Update an existing notification
  Future<bool> updateNotification(MedicationNotification notification) async {
    try {
      MedicationNotification notificationToUpdate = notification;

      // Ensure image is saved permanently if it's a new temporary/camera path
      if (notificationToUpdate.imagePath != null &&
          !notificationToUpdate.imagePath!.contains('notification_images') &&
          !notificationToUpdate.imagePath!.startsWith('http')) {
        final permanentPath = await NotificationService.saveImageToAppStorage(
          notificationToUpdate.imagePath!,
        );
        if (permanentPath != null) {
          notificationToUpdate = notificationToUpdate.copyWith(
            imagePath: permanentPath,
          );
        }
      }

      // Update on backend
      final updatedNotification =
          await NotificationApiService.updateNotification(notificationToUpdate);

      if (updatedNotification != null) {
        // Preserve local imagePath if backend doesn't return it
        final notificationToStore = updatedNotification.copyWith(
          imagePath:
              updatedNotification.imagePath ?? notificationToUpdate.imagePath,
        );

        // Update local storage
        await NotificationStorageService.updateNotification(
          notificationToStore,
        );

        // Cancel old notifications and schedule new ones
        if (notification.id != null) {
          await NotificationService.cancelAllForMedication(
            notification.id!,
            baseId: notification.baseNotificationId,
          );
        }

        // Only schedule if enabled
        if (updatedNotification.isEnabled) {
          await _scheduleNotification(notificationToStore);
        }

        // Reload notifications
        await loadNotifications();
        return true;
      } else {
        _error = 'ไม่สามารถอัปเดตการแจ้งเตือนได้';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'เกิดข้อผิดพลาด: $e';
      notifyListeners();
      print('Error updating notification: $e');
      return false;
    }
  }

  // Delete a notification
  Future<bool> deleteNotification(String id) async {
    try {
      // Delete from backend
      final success = await NotificationApiService.deleteNotification(id);

      if (success) {
        // Find notification to get its baseNotificationId before deleting
        final notification = _notifications.firstWhere(
          (n) => n.id == id,
          orElse: () => MedicationNotification(
            id: id,
            medicationName: '',
            days: [],
            times: [],
          ),
        );

        // Delete from local storage
        await NotificationStorageService.deleteNotification(id);

        // Cancel scheduled notifications
        await NotificationService.cancelAllForMedication(
          id,
          baseId: notification.baseNotificationId,
        );

        // Reload notifications
        await loadNotifications();
        return true;
      } else {
        _error = 'ไม่สามารถลบการแจ้งเตือนได้';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'เกิดข้อผิดพลาด: $e';
      notifyListeners();
      print('Error deleting notification: $e');
      return false;
    }
  }

  // Toggle notification enabled/disabled
  Future<void> toggleNotification(MedicationNotification notification) async {
    final updated = notification.copyWith(isEnabled: !notification.isEnabled);

    // Update local state immediately for better UI response
    final index = _notifications.indexWhere((n) => n.id == notification.id);
    if (index != -1) {
      _notifications[index] = updated;
      notifyListeners();
    }

    // Rely on updateNotification to handle backend sync and scheduling/cancellation
    await updateNotification(updated);
  }

  // Schedule notification using NotificationService
  Future<void> _scheduleNotification(
    MedicationNotification notification,
  ) async {
    if (!notification.isEnabled || notification.id == null) return;

    // Schedule for each day and time combination
    for (int i = 0; i < notification.days.length; i++) {
      for (int j = 0; j < notification.times.length; j++) {
        final day = notification.days[i];
        final time = notification.times[j];

        // Generate unique notification ID (Synced logic with NotificationService)
        final notificationId = _generateNotificationId(notification, i, j);

        // Parse time
        final timeParts = time.split(':');
        if (timeParts.length < 2) continue;

        final hour = int.tryParse(timeParts[0]) ?? 0;
        final minute = int.tryParse(timeParts[1]) ?? 0;

        // Schedule weekly notification via NotificationService
        await NotificationService.scheduleWeeklyNotification(
          id: notificationId,
          day: day,
          hour: hour,
          minute: minute,
          title: 'เตือนกินยา',
          body: notification.medicationName,
          imagePath: notification.imagePath,
          intakeId: notification
              .id, // Using notification ID as intake ID for now, or use a more specific one if available
        );
      }
    }
  }

  // Generate unique notification ID from medication ID and indices
  int _generateNotificationId(
    MedicationNotification notification,
    int dayIndex,
    int timeIndex,
  ) {
    // Priority: use backend-provided base ID if available
    final baseId =
        notification.baseNotificationId ??
        notification.id?.hashCode.abs() ??
        DateTime.now().millisecondsSinceEpoch % 100000;

    return (baseId % 100000) * 100 + dayIndex * 10 + timeIndex;
  }
}
