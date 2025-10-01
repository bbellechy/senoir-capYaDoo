import 'package:flutter/material.dart';

import '../../features/notifications/presentation/pages/notification_demo_page.dart';
import '../../features/tts/presentation/pages/tts_demo_page.dart';

class AppRouter {
  static const String initialRoute = '/notifications/demo';
  static const String ttsDemoRoute = '/tts/demo';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case initialRoute:
        return MaterialPageRoute(
          builder: (_) => const NotificationDemoPage(),
          settings: settings,
        );
      case ttsDemoRoute:
        return MaterialPageRoute(
          builder: (_) => const TextToSpeechDemoPage(),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Route not found'))),
          settings: settings,
        );
    }
  }
}
