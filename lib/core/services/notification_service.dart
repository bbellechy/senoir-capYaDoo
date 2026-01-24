import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // Initialize timezone database
    tz.initializeTimeZones();

    // Get the device's timezone with a fallback
    String timeZoneName = 'Asia/Bangkok'; // Default for Thailand
    try {
      final dynamic result = await FlutterTimezone.getLocalTimezone();
      if (result != null) {
        // Try to get a string representation.
        final String resultStr = result.toString();
        // Check if it's a valid-looking timezone name (no "Instance of")
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
        'NotificationService: Location not found ($timeZoneName), falling back to Asia/Bangkok',
      );
      tz.setLocalLocation(tz.getLocation('Asia/Bangkok'));
    }

    // Android-specific: Create channel and request exact alarm permission
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

    await _notificationsPlugin.initialize(settings);
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'default_channel',
          'Default',
          channelDescription: 'Default channel for notifications',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(id, title, body, details);
  }

  static Future<void> showBigPictureNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    final BigPictureStyleInformation bigPicture = BigPictureStyleInformation(
      const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      contentTitle: title,
      htmlFormatContentTitle: true,
      summaryText: body,
      htmlFormatSummaryText: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        'image_channel_id',
        'Image Notifications',
        channelDescription: 'Notification with image and text',
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: bigPicture,
      ),
    );

    await _notificationsPlugin.show(id, title, body, details);
  }

  // Schedule a weekly notification
  static Future<void> scheduleWeeklyNotification({
    required int id,
    required int day, // 1=Monday, 7=Sunday
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'medication_channel_v2',
          'Medication Reminders',
          channelDescription: 'Notifications for medication reminders',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

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
      print(
        'Scheduled notification ID $id for day $day at $hour:$minute (Local: $scheduledTime)',
      );
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  // Cancel a specific notification
  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  // Cancel all notifications for a medication
  static Future<void> cancelAllForMedication(
    String medicationId, {
    int? baseId,
  }) async {
    // Priority: use backend-provided base ID if available
    final int base = (baseId ?? medicationId.hashCode.abs()) % 100000;

    // REDUCED RANGE: Cancel 7 days * 4 slots = 28 calls (instead of 70)
    // Most medications aren't taken more than 4 times a day.
    for (int day = 0; day < 7; day++) {
      for (int time = 0; time < 4; time++) {
        final id = base * 100 + day * 10 + time;
        await _notificationsPlugin.cancel(id);
      }
    }
  }

  // Generate unique notification ID from medication ID and indices (Synced with Controller)
  static int _generateNotificationId(
    String medicationId,
    int dayIndex,
    int timeIndex,
  ) {
    // Ensure we use the exact same logic as the controller
    final baseId = medicationId.hashCode.abs() % 100000;
    return baseId * 100 + dayIndex * 10 + timeIndex;
  }

  // Check if battery optimization is likely to block notifications
  static Future<void> checkBatteryOptimization() async {
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final bool? isIgnoring = await androidPlugin
        ?.areNotificationsEnabled(); // Rough check
    print('NotificationService: System notifications enabled: $isIgnoring');
  }

  // Calculate next instance of a specific day and time
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

    // Calculate days until target day
    // IMPORTANT: dayOfWeek is from model (1=Mon, 7=Sun)
    // now.weekday is (1=Mon, 7=Sun). This mapping matches.
    int daysUntilTarget = (dayOfWeek - now.weekday + 7) % 7;

    // If it's today but time has passed, schedule for next week
    if (daysUntilTarget == 0 && scheduledDate.isBefore(now)) {
      daysUntilTarget = 7;
    }

    scheduledDate = scheduledDate.add(Duration(days: daysUntilTarget));

    // Log for debugging
    print(
      'NotificationService: Calculated next instance of day $dayOfWeek at $hour:$minute -> $scheduledDate',
    );

    return scheduledDate;
  }

  // Test notification - schedules a notification 10 seconds from now
  static Future<void> scheduleTestNotification({
    required String medicationName,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'medication_channel_v2',
          'Medication Reminders',
          channelDescription: 'Notifications for medication reminders',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    // Schedule 10 seconds from now
    // final scheduledTime = DateTime.now().add(const Duration(seconds: 10));

    // 1. Try to schedule using exact alarm (main method)
    /*
    await _notificationsPlugin.zonedSchedule(
      999, // Test notification ID
      'ทดสอบการแจ้งเตือน (AlarmManager)',
      'เตือนกินยา: $medicationName',
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
    */

    // 2. SIMPLER TEST: Use Future.delayed to bypass AlarmManager complexity for now.
    // If this works, then Permissions/Channels are fine, and the issue is AlarmManager.
    print('NotificationService: Starting 10s countdown for test...');
    Future.delayed(const Duration(seconds: 10), () async {
      print('NotificationService: Firing delayed test notification NOW');
      await _notificationsPlugin.show(
        999,
        'ทดสอบ (Delayed)',
        'เตือนกินยา: $medicationName',
        details,
      );
    });
  }

  // Schedule a test notification 1 minute from now using AlarmManager (ZonedSchedule)
  static Future<void> scheduleOneMinuteTest() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'medication_channel_v2',
          'Medication Reminders',
          channelDescription: 'Notifications for medication reminders',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    final scheduledTime = tz.TZDateTime.now(
      tz.local,
    ).add(const Duration(minutes: 1));

    print('NotificationService: Scheduling 1-minute test for $scheduledTime');

    await _notificationsPlugin.zonedSchedule(
      888, // Different ID for test
      'ทดสอบ Alarm Manager (1 นาที)',
      'ถ้าเห็นข้อความนี้แสดงว่า Alarm ทำงานปกติ!',
      scheduledTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // Check and print permissions
  static Future<void> checkPermissions() async {
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    final bool? notiEnabled = await androidPlugin?.areNotificationsEnabled();
    print(
      'NotificationService: PERMISSION CHECK: Notifications Enabled = $notiEnabled',
    );

    // Check exact alarm permission (only available on Android 12+)
    // Note: The plugin doesn't have a direct "checkExactAlarm" bool return in all versions,
    // but requestExactAlarmsPermission returns bool.
    // For debugging, we'll try to request it again and see the result.
    if (androidPlugin != null) {
      final exactAlarm = await androidPlugin.requestExactAlarmsPermission();
      print(
        'NotificationService: PERMISSION CHECK: Exact Alarms Granted = $exactAlarm',
      );
    }
  }
}
