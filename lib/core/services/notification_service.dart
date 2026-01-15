import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
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
}
