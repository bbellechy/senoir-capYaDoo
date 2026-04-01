import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:capyadoo/core/services/medication_schedule_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _phoneNotificationEnabledKey =
      'phone_notifications_enabled';

  static const int _flagInsistent = 4;

  static Future<bool> isPhoneNotificationsEnabled() async {
    final value = await _storage.read(key: _phoneNotificationEnabledKey);
    // Default to enabled for first-time users.
    if (value == null) return true;
    return value == 'true';
  }

  static Future<void> setPhoneNotificationsEnabled(bool enabled) async {
    await _storage.write(
      key: _phoneNotificationEnabledKey,
      value: enabled.toString(),
    );
  }

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
        'alarm_channel_v1',
        'Alarm Notifications',
        description: 'Notifications for alarms and reminders',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('alarm_sound'),
        enableVibration: true,
        enableLights: true,
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
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Bangkok'));
    } catch (e) {
      print('NotificationService: Background timezone fallback: $e');
    }
    _handleNotificationAction(response);
  }

  @pragma('vm:entry-point')
  static Future<void> _handleNotificationAction(
    NotificationResponse response,
  ) async {
    try {
      print(
        'NotificationService: Handling action: ${response.actionId}, payload: ${response.payload}',
      );
      if (response.actionId == 'stop') {
        final String? payload = response.payload;
        if (payload != null) {
          print('NotificationService: Stop requested for payload: $payload');
          final parts = payload.split('|');
          if (parts.length >= 5) {
            final intakeId = parts[4];
            if (intakeId.isNotEmpty && intakeId != 'null') {
              try {
                final success = await MedicationScheduleService.markAsTaken(
                  intakeId,
                );
                print('NotificationService: Intake marker result: $success');
              } catch (e) {
                print('NotificationService: Error marking as taken: $e');
              }
            }
            final id = int.tryParse(parts[0]) ?? 0;
            await _notificationsPlugin.cancel(id);
          }
        }
      } else if (response.actionId == 'snooze') {
        final String? payload = response.payload;
        if (payload == null || payload.isEmpty) {
          return;
        }
        final parts = payload.split('|');
        if (parts.length < 5) {
          return;
        }
        final id = int.tryParse(parts[0]) ?? 0;

        final snoozeTime = tz.TZDateTime.now(
          tz.local,
        ).add(const Duration(minutes: 10));

        await _notificationsPlugin.zonedSchedule(
          id + 2000,
          'เตือนใหม่: เตือนกินยา',
          'รบกวนรับประทานยาที่คุณตั้งค่าไว้ (เลื่อนมา 10 นาที)',
          snoozeTime,
          NotificationDetails(
            android: _getAlarmAndroidDetails(
              'เตือนใหม่: เตือนกินยา',
              'รบกวนรับประทานยาที่คุณตั้งค่าไว้ (เลื่อนมา 10 นาที)',
            ),
          ),
          payload: payload,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );

        await _notificationsPlugin.cancel(id);
        print('NotificationService: Snoozed successfully. Canceled ID: $id');
      }
    } catch (e, stack) {
      print('NotificationService: _handleNotificationAction error: $e');
      print('NotificationService: stack: $stack');
    }
  }

  // Simplified image loader returning bytes.
  // This is what the user said "used to work" (before crash issues).
  // With resized images (512x512), this IS the correct way.
  static Future<ByteArrayAndroidBitmap?> _loadImage(String imagePath) async {
    print('NotificationService: Loading image from $imagePath');
    try {
      if (imagePath.startsWith('http')) {
        final response = await http.get(Uri.parse(imagePath));
        if (response.statusCode == 200) {
          return ByteArrayAndroidBitmap(response.bodyBytes);
        }
        return null;
      }

      final file = File(imagePath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        print(
          'NotificationService: Loaded image ${bytes.length} bytes from $imagePath',
        );
        return ByteArrayAndroidBitmap(bytes);
      } else {
        print('NotificationService: File not found at $imagePath');
        return null;
      }
    } catch (e) {
      print('NotificationService: Error loading image: $e');
      return null;
    }
  }

  // This function is REQUIRED by NotificationController
  static Future<String?> saveImageToAppStorage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) return null;

      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${directory.path}/notification_images');
      if (!await imagesDir.exists()) await imagesDir.create(recursive: true);

      String extension = 'jpg';
      if (imagePath.contains('.')) {
        extension = imagePath.split('.').last;
      }

      final newPath =
          '${imagesDir.path}/med_${DateTime.now().millisecondsSinceEpoch}.$extension';
      await file.copy(newPath);
      print('NotificationService: Image saved to $newPath');
      return newPath;
    } catch (e) {
      print('NotificationService: Error saving image: $e');
      return null;
    }
  }

  // This function is REQUIRED by _getAlarmAndroidDetails
  static List<AndroidNotificationAction> _getActions() {
    return [
      const AndroidNotificationAction(
        'stop',
        'หยุด (Stop)',
        showsUserInterface: true,
      ),
      const AndroidNotificationAction(
        'snooze',
        'เตือนใหม่ในอีก 10 นาที (Snooze)',
        showsUserInterface: true,
      ),
    ];
  }

  static AndroidNotificationDetails _getAlarmAndroidDetails(
    String title,
    String body, {
    ByteArrayAndroidBitmap? image,
  }) {
    return AndroidNotificationDetails(
      'alarm_channel_v1',
      'Alarm Notifications',
      channelDescription: 'Notifications for alarms and reminders',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      category: AndroidNotificationCategory.alarm,
      ongoing: true,
      autoCancel: false,
      sound: const RawResourceAndroidNotificationSound('alarm_sound'),
      additionalFlags: Int32List.fromList([_flagInsistent]),
      styleInformation: image != null
          ? BigPictureStyleInformation(
              image,
              contentTitle: title,
              summaryText: body,
            )
          : null,
      largeIcon: image,
      actions: _getActions(),
    );
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? imagePath,
    String? payload,
  }) async {
    if (!await isPhoneNotificationsEnabled()) {
      print('NotificationService: Skipped showNotification (disabled by user)');
      return;
    }

    final image = imagePath != null ? await _loadImage(imagePath) : null;
    final androidDetails = _getAlarmAndroidDetails(title, body, image: image);

    await _notificationsPlugin.show(
      id,
      title,
      body,
      NotificationDetails(android: androidDetails),
      payload: payload,
    );
  }

  static Future<void> scheduleWeeklyNotification({
    required int id,
    required int day,
    required int hour,
    required int minute,
    required String title,
    required String body,
    String? imagePath,
    String? intakeId, // Pass intakeId for confirmation logic
  }) async {
    if (!await isPhoneNotificationsEnabled()) {
      print(
        'NotificationService: Skipped scheduleWeeklyNotification (disabled by user)',
      );
      return;
    }

    // Simplified: Just use the provided path.
    // The Controller already ensures the image is saved to app storage.
    // And _loadImage will handle reading it.
    final image = imagePath != null ? await _loadImage(imagePath) : null;
    final androidDetails = _getAlarmAndroidDetails(title, body, image: image);

    final scheduledTime = _nextInstanceOfDayAndTime(day, hour, minute);
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledTime,
      NotificationDetails(android: androidDetails),
      payload: '$id|$day|$hour|$minute|$intakeId', // Expanded payload
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
    print('NotificationService: All notifications canceled');
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
    if (!await isPhoneNotificationsEnabled()) {
      print(
        'NotificationService: Skipped scheduleTestNotification (disabled by user)',
      );
      return;
    }

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
