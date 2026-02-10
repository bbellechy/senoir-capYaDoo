import 'package:flutter/material.dart';

import 'package:capyadoo/features/notifications/presentation/pages/notification_demo_page.dart';
import 'package:capyadoo/features/notifications/presentation/pages/notification_list_page.dart';
import 'package:capyadoo/features/notifications/presentation/pages/add_notification_page.dart';
import 'package:capyadoo/features/notifications/presentation/pages/edit_notification_page.dart';
import 'package:capyadoo/features/tts/presentation/pages/tts_demo_page.dart';
import 'package:capyadoo/features/home/presentation/pages/home_page.dart';
import 'package:capyadoo/features/search/presentation/pages/search_page.dart';
import 'package:capyadoo/features/add_data/presentation/pages/add_data_page.dart';
import 'package:capyadoo/features/add_data/presentation/pages/add_medicine_page.dart';
import 'package:capyadoo/features/add_data/presentation/pages/add_symptom_page.dart';
import 'package:capyadoo/features/add_data/presentation/pages/medicine_list_page.dart';
import 'package:capyadoo/features/add_data/presentation/pages/symptom_list_page.dart';
import 'package:capyadoo/features/profile/presentation/pages/profile_page.dart';
import 'package:capyadoo/features/auth/presentation/pages/login_page.dart';
import 'package:capyadoo/features/auth/presentation/pages/register_page.dart';
import 'package:capyadoo/features/widget_showcase/widget_showcase_page.dart';
import 'package:capyadoo/features/caregivers/presentation/pages/caregivers_and_users_page.dart';
import 'package:capyadoo/core/layouts/main_layout.dart';
import 'package:capyadoo/core/model/medication_notification.dart';

class AppRouter {
  // Auth routes
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';

  // Main routes with bottom navigation
  static const String mainRoute = '/';
  static const String initialRoute = '/login';
  static const String homeRoute = '/home';
  static const String searchRoute = '/search';
  static const String addDataRoute = '/add-data';
  static const String medicineListRoute = '/medicine/list';
  static const String symptomListRoute = '/symptom/list';
  static const String addMedicineRoute = '/medicine/add';
  static const String addSymptomRoute = '/symptom/add';
  static const String notificationsRoute = '/notifications';
  static const String profileRoute = '/profile';
  static const String caregiversRoute = '/caregivers';

  // Notification routes
  static const String addNotificationRoute = '/notifications/add';
  static const String editNotificationRoute = '/notifications/edit';

  // Demo routes (legacy)
  static const String notificationDemoRoute = '/notifications/demo';
  static const String ttsDemoRoute = '/tts/demo';
  static const String widgetShowcaseRoute = '/widget';

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
      case mainRoute:
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
      case medicineListRoute:
        return MaterialPageRoute(
          builder: (_) => const MedicineListPage(),
          settings: settings,
        );
      case symptomListRoute:
        return MaterialPageRoute(
          builder: (_) => const SymptomListPage(),
          settings: settings,
        );
      case addMedicineRoute:
        final medicationId = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => AddMedicinePage(medicationId: medicationId),
          settings: settings,
        );
      case addSymptomRoute:
        return MaterialPageRoute(
          builder: (_) => const AddSymptomPage(),
          settings: settings,
        );
      case notificationsRoute:
        return MaterialPageRoute(
          builder: (_) => const NotificationListPage(),
          settings: settings,
        );
      case addNotificationRoute:
        return MaterialPageRoute(
          builder: (_) => const AddNotificationPage(),
          settings: settings,
        );
      case editNotificationRoute:
        final notification = settings.arguments as MedicationNotification?;
        if (notification == null) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Invalid notification data')),
            ),
            settings: settings,
          );
        }
        return MaterialPageRoute(
          builder: (_) => EditNotificationPage(notification: notification),
          settings: settings,
        );
      // case notificationDemoRoute:
      //   return MaterialPageRoute(
      //     builder: (_) => const NotificationDemoPage(),
      //     settings: settings,
      //   );
      case profileRoute:
        return MaterialPageRoute(
          builder: (_) => const ProfilePage(),
          settings: settings,
        );
      case caregiversRoute:
        return MaterialPageRoute(
          builder: (_) => const CaregiversAndUsersPage(),
          settings: settings,
        );
      case ttsDemoRoute:
        return MaterialPageRoute(
          builder: (_) => const TextToSpeechDemoPage(),
          settings: settings,
        );
      case widgetShowcaseRoute:
        return MaterialPageRoute(
          builder: (_) => const WidgetShowcasePage(),
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
