import 'package:flutter/material.dart';

import 'package:capyadoo/core/services/notification_service.dart';
import 'package:capyadoo/core/routing/app_router.dart';

class NotificationDemoPage extends StatelessWidget {
  const NotificationDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Local Notification Demo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                await NotificationService.showNotification(
                  id: 0,
                  title: 'แจ้งเตือนปกติ',
                  body: 'นี่คือข้อความจากการทดสอบ Flutter 🚀',
                );
              },
              child: const Text('กดเพื่อแจ้งเตือนข้อความปกติ'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await NotificationService.showBigPictureNotification(
                  id: 1,
                  title: 'ข่าวด่วน ⚡',
                  body: 'รายละเอียดข่าวพร้อมรูปภาพ',
                );
              },
              child: const Text('กดเพื่อแจ้งเตือนพร้อมรูปภาพ'),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRouter.ttsDemoRoute);
              },
              child: const Text('ไปหน้า Text-to-Speech Demo'),
            ),
          ],
        ),
      ),
    );
  }
}
