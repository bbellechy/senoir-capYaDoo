import 'package:flutter/material.dart';

import 'package:capyadoo/features/notifications/presentation/pages/notification_demo_page.dart';
import 'package:capyadoo/features/tts/presentation/pages/tts_demo_page.dart';
import 'package:capyadoo/features/home/presentation/pages/home_page.dart';
import 'package:capyadoo/features/search/presentation/pages/search_page.dart';
import 'package:capyadoo/features/add_data/presentation/pages/add_data_page.dart';
import 'package:capyadoo/features/profile/presentation/pages/profile_page.dart';
import 'package:capyadoo/features/auth/presentation/pages/login_page.dart';
import 'package:capyadoo/features/auth/presentation/pages/register_page.dart';
import 'package:capyadoo/core/layouts/main_layout.dart';

class AppRouter {
  // Auth routes
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';

  // Main routes with bottom navigation
  static const String initialRoute = '/';
  static const String homeRoute = '/home';
  static const String searchRoute = '/search';
  static const String addDataRoute = '/add-data';
  static const String notificationsRoute = '/notifications';
  static const String profileRoute = '/profile';

  // Demo routes (legacy)
  static const String notificationDemoRoute = '/notifications/demo';
  static const String ttsDemoRoute = '/tts/demo';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case loginRoute:
        return MaterialPageRoute(
          builder: (_) => const LoginPage(),
          settings: settings,
        );
      case registerRoute:
        return MaterialPageRoute(
          builder: (_) => const RegisterPage(),
          settings: settings,
        );
      case initialRoute:
        return MaterialPageRoute(
          builder: (_) => const MainLayout(),
          settings: settings,
        );
      case homeRoute:
        return MaterialPageRoute(
          builder: (_) => const HomePage(),
          settings: settings,
        );
      case searchRoute:
        return MaterialPageRoute(
          builder: (_) => const SearchPage(),
          settings: settings,
        );
      case addDataRoute:
        return MaterialPageRoute(
          builder: (_) => const AddDataPage(),
          settings: settings,
        );
      case notificationsRoute:
      case notificationDemoRoute:
        return MaterialPageRoute(
          builder: (_) => const NotificationDemoPage(),
          settings: settings,
        );
      case profileRoute:
        return MaterialPageRoute(
          builder: (_) => const ProfilePage(),
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
