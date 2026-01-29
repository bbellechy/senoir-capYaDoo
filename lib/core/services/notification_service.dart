import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:path_provider/path_provider.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    String timeZoneName = 'Asia/Bangkok';
    try {
      final dynamic result = await FlutterTimezone.getLocalTimezone();
      if (result != null) {
        final String resultStr = result.toString();
        if (!resultStr.contains('Instance of')) {
          timeZoneName = resultStr;
        }
      }
    } catch (e) {
      print('NotificationService: Error getting timezone, using default: $e');
    }

    try {
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      print('NotificationService: Local timezone set to $timeZoneName');
    } catch (e) {
      print('NotificationService: Location not found, falling back to Asia/Bangkok');
      tz.setLocalLocation(tz.getLocation('Asia/Bangkok'));
    }

    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'medication_channel_v2',
        'Medication Reminders',
        description: 'Notifications for medication reminders',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ),
    );

    if (androidPlugin != null) {
      await androidPlugin.requestExactAlarmsPermission();
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(settings);
  }

  // Convert image to ByteArrayAndroidBitmap (more reliable than file path)
  static Future<ByteArrayAndroidBitmap?> _loadImageAsBytes(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        print('NotificationService: Image file not found: $imagePath');
        return null;
      }

      final Uint8List bytes = await file.readAsBytes();
      print('NotificationService: Loaded image bytes: ${bytes.length} bytes');
      
      return ByteArrayAndroidBitmap(bytes);
    } catch (e) {
      print('NotificationService: Error loading image as bytes: $e');
      return null;
    }
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? imagePath,
  }) async {
    print('NotificationService: showNotification called');
    print('  ID: $id');
    print('  Title: $title');
    print('  Body: $body');
    print('  ImagePath: $imagePath');
    
    AndroidNotificationDetails androidDetails;

    if (imagePath != null) {
      final imageBytes = await _loadImageAsBytes(imagePath);
      
      if (imageBytes != null) {
        try {
          final BigPictureStyleInformation bigPicture = BigPictureStyleInformation(
            imageBytes,
            largeIcon: imageBytes,
            contentTitle: title,
            summaryText: body,
            hideExpandedLargeIcon: false,
          );

          androidDetails = AndroidNotificationDetails(
            'medication_channel_v2',
            'Medication Reminders',
            channelDescription: 'Notifications for medication reminders',
            importance: Importance.max,
            priority: Priority.high,
            styleInformation: bigPicture,
            largeIcon: imageBytes,
          );
          
          print('NotificationService: Using ByteArray big picture style');
        } catch (e) {
          print('NotificationService: Error creating big picture: $e');
          androidDetails = const AndroidNotificationDetails(
            'medication_channel_v2',
            'Medication Reminders',
            channelDescription: 'Notifications for medication reminders',
            importance: Importance.max,
            priority: Priority.high,
            largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          );
        }
      } else {
        print('NotificationService: Failed to load image bytes, using default');
        androidDetails = const AndroidNotificationDetails(
          'medication_channel_v2',
          'Medication Reminders',
          channelDescription: 'Notifications for medication reminders',
          importance: Importance.max,
          priority: Priority.high,
          largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        );
      }
    } else {
      print('NotificationService: No image path provided');
      androidDetails = const AndroidNotificationDetails(
        'medication_channel_v2',
        'Medication Reminders',
        channelDescription: 'Notifications for medication reminders',
        importance: Importance.max,
        priority: Priority.high,
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      );
    }

    final NotificationDetails details = NotificationDetails(android: androidDetails);

    try {
      await _notificationsPlugin.show(id, title, body, details);
      print('NotificationService: Notification shown successfully');
    } catch (e) {
      print('NotificationService: Error showing notification: $e');
    }
  }

  // Schedule notification - NOTE: ByteArray approach may not work well with scheduled notifications
  // So we'll save the image to a persistent location first
  static Future<String?> _saveImageToAppStorage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        print('NotificationService: Source image not found');
        return null;
      }

      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${directory.path}/notification_images');
      
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = imagePath.split('.').last.toLowerCase();
      final newPath = '${imagesDir.path}/med_$timestamp.$extension';
      
      await file.copy(newPath);
      
      if (await File(newPath).exists()) {
        print('NotificationService: Image saved to: $newPath');
        return newPath;
      }
      
      return null;
    } catch (e) {
      print('NotificationService: Error saving image: $e');
      return null;
    }
  }

  static Future<void> scheduleWeeklyNotification({
    required int id,
    required int day,
    required int hour,
    required int minute,
    required String title,
    required String body,
    String? imagePath,
  }) async {
    print('NotificationService: scheduleWeeklyNotification');
    print('  ID: $id, Day: $day, Time: $hour:$minute');
    print('  ImagePath: $imagePath');
    
    AndroidNotificationDetails androidDetails;

    if (imagePath != null && await File(imagePath).exists()) {
      // Save image permanently
      final savedPath = await _saveImageToAppStorage(imagePath);
      
      if (savedPath != null) {
        // Load image as bytes for notification
        final imageBytes = await _loadImageAsBytes(savedPath);
        
        if (imageBytes != null) {
          try {
            final BigPictureStyleInformation bigPicture = BigPictureStyleInformation(
              imageBytes,
              largeIcon: imageBytes,
              contentTitle: title,
              summaryText: body,
              hideExpandedLargeIcon: false,
            );

            androidDetails = AndroidNotificationDetails(
              'medication_channel_v2',
              'Medication Reminders',
              channelDescription: 'Notifications for medication reminders',
              importance: Importance.max,
              priority: Priority.high,
              styleInformation: bigPicture,
              largeIcon: imageBytes,
            );
            
            print('NotificationService: Scheduled with ByteArray image');
          } catch (e) {
            print('NotificationService: Error with ByteArray, using default: $e');
            androidDetails = const AndroidNotificationDetails(
              'medication_channel_v2',
              'Medication Reminders',
              channelDescription: 'Notifications for medication reminders',
              importance: Importance.max,
              priority: Priority.high,
              largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
            );
          }
        } else {
          print('NotificationService: Could not load image bytes');
          androidDetails = const AndroidNotificationDetails(
            'medication_channel_v2',
            'Medication Reminders',
            channelDescription: 'Notifications for medication reminders',
            importance: Importance.max,
            priority: Priority.high,
            largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          );
        }
      } else {
        print('NotificationService: Could not save image');
        androidDetails = const AndroidNotificationDetails(
          'medication_channel_v2',
          'Medication Reminders',
          channelDescription: 'Notifications for medication reminders',
          importance: Importance.max,
          priority: Priority.high,
          largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        );
      }
    } else {
      print('NotificationService: No valid image path');
      androidDetails = const AndroidNotificationDetails(
        'medication_channel_v2',
        'Medication Reminders',
        channelDescription: 'Notifications for medication reminders',
        importance: Importance.max,
        priority: Priority.high,
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      );
    }

    final NotificationDetails details = NotificationDetails(android: androidDetails);

    try {
      final scheduledTime = _nextInstanceOfDayAndTime(day, hour, minute);
      
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
      
      print('NotificationService: Successfully scheduled notification');
    } catch (e) {
      print('NotificationService: Error scheduling: $e');
    }
  }

  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  static Future<void> cancelAllForMedication(
    String medicationId, {
    int? baseId,
  }) async {
    final int base = (baseId ?? medicationId.hashCode.abs()) % 100000;

    for (int day = 0; day < 7; day++) {
      for (int time = 0; time < 4; time++) {
        final id = base * 100 + day * 10 + time;
        await _notificationsPlugin.cancel(id);
      }
    }
  }

  static Future<void> checkBatteryOptimization() async {
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final bool? isIgnoring = await androidPlugin?.areNotificationsEnabled();
    print('NotificationService: System notifications enabled: $isIgnoring');
  }

  static tz.TZDateTime _nextInstanceOfDayAndTime(
    int dayOfWeek,
    int hour,
    int minute,
  ) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    int daysUntilTarget = (dayOfWeek - now.weekday + 7) % 7;

    if (daysUntilTarget == 0 && scheduledDate.isBefore(now)) {
      daysUntilTarget = 7;
    }

    scheduledDate = scheduledDate.add(Duration(days: daysUntilTarget));
    return scheduledDate;
  }

  static Future<void> scheduleTestNotification({
    required String medicationName,
    String? imagePath,
  }) async {
    print('NotificationService: Test notification in 10 seconds');
    Future.delayed(const Duration(seconds: 10), () async {
      await showNotification(
        id: 999,
        title: 'ทดสอบการแจ้งเตือน',
        body: 'เตือนกินยา: $medicationName',
        imagePath: imagePath,
      );
    });
  }

  static Future<void> checkPermissions() async {
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    final bool? notiEnabled = await androidPlugin?.areNotificationsEnabled();
    print('NotificationService: Notifications Enabled = $notiEnabled');

    if (androidPlugin != null) {
      final exactAlarm = await androidPlugin.requestExactAlarmsPermission();
      print('NotificationService: Exact Alarms Granted = $exactAlarm');
    }
  }
}