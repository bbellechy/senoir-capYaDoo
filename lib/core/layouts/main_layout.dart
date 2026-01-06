import 'package:flutter/material.dart';
import 'package:capyadoo/core/widgets/app_nav_bar.dart';
import 'package:capyadoo/features/home/presentation/pages/home_page.dart';
import 'package:capyadoo/features/search/presentation/pages/search_page.dart';
import 'package:capyadoo/features/add_data/presentation/pages/add_data_page.dart';
import 'package:capyadoo/features/notifications/presentation/pages/notification_demo_page.dart';
import 'package:capyadoo/features/profile/presentation/pages/profile_page.dart';

/// Layout หลักที่ใช้ Bottom Navigation Bar
class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = const [
      HomePage(), // 0: หน้าหลัก
      SearchPage(), // 1: ค้นหา
      AddDataPage(), // 2: เพิ่มข้อมูล
      NotificationDemoPage(), // 3: แจ้งเตือน
      ProfilePage(), // 4: โปรไฟล์
    ];
  }

  void _onNavBarTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: AppNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavBarTap,
      ),
    );
  }
}
