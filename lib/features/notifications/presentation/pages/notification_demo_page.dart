import 'package:flutter/material.dart';

import 'package:capyadoo/core/services/notification_service.dart';
import 'package:capyadoo/core/routing/app_router.dart';

class NotificationDemoPage extends StatelessWidget {
  const NotificationDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Local Notification Demo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
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
                  await NotificationService.scheduleTestNotification(
                    medicationName: 'ทดสอบ (10 วินาที)',
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('กำลังจองแจ้งเตือนในอีก 10 วินาที...'),
                    ),
                  );
                },
                child: const Text('ทดสอบจองเวลา (10 วินาทีข้างหน้า)'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  // Test functionality of AlarmManager specifically
                  await NotificationService.scheduleOneMinuteTest();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('กำลังจอง Alarm Manager อีก 1 นาที...'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('ทดสอบ Alarm Manager (1 นาที)'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await NotificationService.checkPermissions();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('ตรวจสอบ Permission แล้ว (ดูใน Log)'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                child: const Text('เช็ค Permission/Battery'),
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
      ),
    );
  }
}
