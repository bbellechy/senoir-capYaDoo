import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:capyadoo/core/constants/app_colors.dart';

class AppEmptyCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? icon;
  final VoidCallback? onAddPressed;
  final Color? iconColor;
  final Color? borderColor;
  final double? borderRadius;
  final double? borderWidth;

  const AppEmptyCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon,
    this.onAddPressed,
    this.iconColor,
    this.borderColor,
    this.borderRadius,
    this.borderWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 40.h, horizontal: 24.w),
      decoration: BoxDecoration(
        color: AppColors.whitelist,
        borderRadius: BorderRadius.circular(borderRadius ?? 24.r),
        border: Border.all(
          color: borderColor ?? AppColors.blueBorder,
          width: borderWidth ?? 1.w,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon ?? Icons.medication_liquid_outlined,
            size: 80.sp,
            color: iconColor ?? AppColors.textSublest,
          ),
          SizedBox(height: 24.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textSub,
              fontFamily: 'Sarabun',
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16.sp,
              color: AppColors.textSub,
              fontFamily: 'Sarabun',
            ),
            textAlign: TextAlign.center,
          ),
          if (onAddPressed != null) ...[
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: onAddPressed,
              icon: Icon(Icons.add, color: Colors.white, size: 20.sp),
              label: Text(
                'เพิ่มข้อมูล',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Sarabun',
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                padding: EdgeInsets.symmetric(
                  horizontal: 24.w,
                  vertical: 12.h,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
