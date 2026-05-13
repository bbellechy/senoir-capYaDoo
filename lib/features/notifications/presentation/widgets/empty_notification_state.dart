import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:capyadoo/core/widgets/app_button.dart';

class EmptyNotificationState extends StatelessWidget {
  final VoidCallback onAddPressed;

  const EmptyNotificationState({super.key, required this.onAddPressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_outlined,
              size: 100.sp,
              color: Colors.grey[400],
            ),
            SizedBox(height: 24.h),
            Text(
              'ยังไม่มีการแจ้งเตือน',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'เพิ่มการแจ้งเตือนเพื่อให้แน่ใจว่าคุณไม่พลาดยา',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 32.h),
            AppButton(
              text: 'เพิ่มการแจ้งเตือน',
              onPressed: onAddPressed,
              icon: Icon(Icons.add, color: Colors.white, size: 24.sp),
            ),
          ],
        ),
      ),
    );
  }
}
