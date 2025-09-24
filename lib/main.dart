import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
        InitializationSettings(android: androidInitSettings);

    await flutterLocalNotificationsPlugin.initialize(initSettings);

    // 🔹 ขอ permission สำหรับ Android 13+
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  /// Notification แบบข้อความปกติ
  Future<void> _showNotification() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'default_channel_id',
      'Default Notifications',
      channelDescription: 'Basic notification channel',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      0,
      'แจ้งเตือนปกติ',
      'นี่คือข้อความจากการทดสอบ Flutter 🚀',
      platformDetails,
    );
  }

  /// Notification แบบ Big Picture (มีรูป + ข้อความ)
  Future<void> _showBigPictureNotification() async {
    final bigPicture = BigPictureStyleInformation(
      const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      contentTitle: 'ข่าวด่วน ⚡',
      htmlFormatContentTitle: true,
      summaryText: 'รายละเอียดข่าวพร้อมรูปภาพ',
      htmlFormatSummaryText: true,
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'image_channel_id',
        'Image Notifications',
        channelDescription: 'Notification with image and text',
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: bigPicture,
      ),
    );

    await flutterLocalNotificationsPlugin.show(
      1,
      'แจ้งเตือนพร้อมรูป',
      'ลองใช้ BigPictureStyle ดูสิครับ 🎨',
      platformDetails,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notification Demo',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Local Notification Demo'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _showNotification,
                child: const Text('กดเพื่อแจ้งเตือนข้อความปกติ'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _showBigPictureNotification,
                child: const Text('กดเพื่อแจ้งเตือนพร้อมรูปภาพ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
