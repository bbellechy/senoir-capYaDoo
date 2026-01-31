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
      print(
        'NotificationService: Location not found, falling back to Asia/Bangkok',
      );
      tz.setLocalLocation(tz.getLocation('Asia/Bangkok'));
    }

    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

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

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationAction(response);
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  @pragma('vm:entry-point')
  static void notificationTapBackground(NotificationResponse response) {
    _handleNotificationAction(response);
  }

  static Future<void> _handleNotificationAction(
    NotificationResponse response,
  ) async {
    print('NotificationService: Handling action: ${response.actionId}');
    if (response.actionId == 'taken') {
      final String? payload = response.payload;
      if (payload != null) {
        print('NotificationService: Marking as taken for payload: $payload');
        // Actual API call logic would go here
      }
    } else if (response.actionId == 'not_taken') {
      print('NotificationService: User marked as not taken yet');
    }
  }

  static Future<ByteArrayAndroidBitmap?> _loadImageAsBytes(
    String imagePath,
  ) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) return null;
      final Uint8List bytes = await file.readAsBytes();
      return ByteArrayAndroidBitmap(bytes);
    } catch (e) {
      print('NotificationService: Error loading image: $e');
      return null;
    }
  }

  static List<AndroidNotificationAction> _getActions() {
    return [
      const AndroidNotificationAction(
        'taken',
        'Taken',
        showsUserInterface: true,
      ),
      const AndroidNotificationAction(
        'not_taken',
        'Not Taken Yet',
        showsUserInterface: false,
      ),
    ];
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? imagePath,
    String? payload,
  }) async {
    AndroidNotificationDetails androidDetails;

    if (imagePath != null) {
      final imageBytes = await _loadImageAsBytes(imagePath);
      if (imageBytes != null) {
        androidDetails = AndroidNotificationDetails(
          'medication_channel_v2',
          'Medication Reminders',
          channelDescription: 'Notifications for medication reminders',
          importance: Importance.max,
          priority: Priority.high,
          styleInformation: BigPictureStyleInformation(
            imageBytes,
            largeIcon: imageBytes,
            contentTitle: title,
            summaryText: body,
          ),
          largeIcon: imageBytes,
          actions: _getActions(),
        );
      } else {
        // Fallback: Text only if image missing
        androidDetails = AndroidNotificationDetails(
          'medication_channel_v2',
          'Medication Reminders',
          channelDescription: 'Notifications for medication reminders',
          importance: Importance.max,
          priority: Priority.high,
          actions: _getActions(),
        );
      }
    } else {
      androidDetails = AndroidNotificationDetails(
        'medication_channel_v2',
        'Medication Reminders',
        channelDescription: 'Notifications for medication reminders',
        importance: Importance.max,
        priority: Priority.high,
        actions: _getActions(),
      );
    }

    await _notificationsPlugin.show(
      id,
      title,
      body,
      NotificationDetails(android: androidDetails),
      payload: payload,
    );
  }

  static Future<String?> saveImageToAppStorage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) return null;

      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${directory.path}/notification_images');
      if (!await imagesDir.exists()) await imagesDir.create(recursive: true);

      final newPath =
          '${imagesDir.path}/med_${DateTime.now().millisecondsSinceEpoch}.${imagePath.split('.').last}';
      await file.copy(newPath);
      return newPath;
    } catch (e) {
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
    AndroidNotificationDetails androidDetails;
    String? finalImagePath = imagePath;

    // Only save if it's not already in permanent storage and is a local file
    if (imagePath != null &&
        await File(imagePath).exists() &&
        !imagePath.contains('notification_images')) {
      final savedPath = await saveImageToAppStorage(imagePath);
      if (savedPath != null) finalImagePath = savedPath;
    }

    if (finalImagePath != null) {
      final imageBytes = await _loadImageAsBytes(finalImagePath);
      if (imageBytes != null) {
        androidDetails = AndroidNotificationDetails(
          'medication_channel_v2',
          'Medication Reminders',
          channelDescription: 'Notifications for medication reminders',
          importance: Importance.max,
          priority: Priority.high,
          styleInformation: BigPictureStyleInformation(
            imageBytes,
            largeIcon: imageBytes,
            contentTitle: title,
            summaryText: body,
          ),
          largeIcon: imageBytes,
          actions: _getActions(),
        );
      } else {
        // Fallback: Text only if image missing
        androidDetails = AndroidNotificationDetails(
          'medication_channel_v2',
          'Medication Reminders',
          channelDescription: 'Notifications for medication reminders',
          importance: Importance.max,
          priority: Priority.high,
          actions: _getActions(),
        );
      }
    } else {
      androidDetails = AndroidNotificationDetails(
        'medication_channel_v2',
        'Medication Reminders',
        channelDescription: 'Notifications for medication reminders',
        importance: Importance.max,
        priority: Priority.high,
        actions: _getActions(),
      );
    }

    final scheduledTime = _nextInstanceOfDayAndTime(day, hour, minute);
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledTime,
      NotificationDetails(android: androidDetails),
      payload: '$id|$day|$hour|$minute',
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  static Future<void> cancelNotification(int id) async =>
      await _notificationsPlugin.cancel(id);

  static Future<void> checkBatteryOptimization() async {
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final bool? isIgnoring = await androidPlugin?.areNotificationsEnabled();
    print('NotificationService: System notifications enabled: $isIgnoring');
  }

  static Future<void> cancelAllForMedication(
    String medicationId, {
    int? baseId,
  }) async {
    final int base = (baseId ?? medicationId.hashCode.abs()) % 100000;
    for (int day = 0; day < 7; day++) {
      for (int time = 0; time < 4; time++) {
        await _notificationsPlugin.cancel(base * 100 + day * 10 + time);
      }
    }
  }

  static tz.TZDateTime _nextInstanceOfDayAndTime(
    int dayOfWeek,
    int hour,
    int minute,
  ) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    int daysUntilTarget = (dayOfWeek - now.weekday + 7) % 7;
    if (daysUntilTarget == 0 && scheduledDate.isBefore(now))
      daysUntilTarget = 7;
    return scheduledDate.add(Duration(days: daysUntilTarget));
  }

  static Future<void> scheduleTestNotification({
    required String medicationName,
    String? imagePath,
  }) async {
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
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null)
      await androidPlugin.requestExactAlarmsPermission();
  }
}
