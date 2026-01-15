import 'package:flutter/material.dart';
import 'package:capyadoo/core/constants/app_colors.dart';

class AppNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AppNavBar({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                label: 'หน้าหลัก',
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.search_outlined,
                selectedIcon: Icons.search,
                label: 'ค้นหา',
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.add_circle_outline,
                selectedIcon: Icons.add_circle,
                label: 'เพิ่มข้อมูล',
              ),
              _buildNavItem(
                index: 3,
                icon: Icons.notifications_outlined,
                selectedIcon: Icons.notifications,
                label: 'แจ้งเตือน',
              ),
              _buildNavItem(
                index: 4,
                icon: Icons.person_outline,
                selectedIcon: Icons.person,
                label: 'โปรไฟล์',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
  }) {
    final isSelected = currentIndex == index;

    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 64,
        height: 56,
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        decoration: isSelected
            ? BoxDecoration(
                color: AppColors.subBlue,
                borderRadius: BorderRadius.circular(8),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              color: isSelected ? AppColors.primaryBlue : AppColors.textSub,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primaryBlue : AppColors.textSub,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
