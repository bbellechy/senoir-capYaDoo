import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:capyadoo/core/services/notification_service.dart';

Future<void> bootstrap(Future<void> Function() runAppCallback) async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.init();

  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }

  await runAppCallback();
}
