import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:capyadoo/core/constants/app_colors.dart';

class AppNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool isCaregiverMode;

  const AppNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.isCaregiverMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15.r,
            offset: Offset(0, -4.h),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 72.h, // Consistent height
          padding: EdgeInsets.symmetric(horizontal: 12.0.w),
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
                icon: Icons.add_rounded,
                selectedIcon: Icons.add_rounded,
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
    final primaryColor = isCaregiverMode
        ? AppColors.success
        : AppColors.primaryBlue;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 6.h),
          decoration: isSelected
              ? BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor.withOpacity(0.2),
                      primaryColor.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.1),
                      blurRadius: 10.r,
                      offset: Offset(0, 4.h),
                    ),
                  ],
                )
              : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? selectedIcon : icon,
                color: isSelected ? primaryColor : AppColors.textSub,
                size: 28.sp,
              ),
              SizedBox(height: 4.h),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? primaryColor : AppColors.textSub,
                  fontSize: 12.sp,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontFamily: 'Sarabun',
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
