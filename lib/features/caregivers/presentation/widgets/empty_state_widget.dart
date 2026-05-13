import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:capyadoo/core/constants/app_colors.dart';

/// Widget แสดงเมื่อไม่มีข้อมูล
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final double width;
  final bool showBorder;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.buttonText,
    this.onButtonPressed,
    this.width = double.infinity,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: AppColors.whitelist,
        borderRadius: BorderRadius.circular(12.r),
        border: showBorder
            ? Border.all(color: AppColors.blueBorder, width: 1.5.w)
            : null,
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: buttonText != null ? 64.sp : 48.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: buttonText != null ? 16.h : 12.h),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Sarabun',
              fontSize: buttonText != null ? 18.sp : 16.sp,
              fontWeight: buttonText != null
                  ? FontWeight.w600
                  : FontWeight.normal,
              color: buttonText != null
                  ? AppColors.textPrimary
                  : AppColors.textSub,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: 'Sarabun',
              fontSize: buttonText != null ? 14.sp : 12.sp,
              color: AppColors.textSub,
            ),
            textAlign: TextAlign.center,
          ),
          if (buttonText != null && onButtonPressed != null) ...[
            SizedBox(height: 16.h),
            SizedBox(
              width: 200.w,
              height: 44.h,
              child: ElevatedButton(
                onPressed: onButtonPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_add, size: 20.sp),
                    SizedBox(width: 8.w),
                    Text(
                      buttonText!,
                      style: TextStyle(
                        fontFamily: 'Sarabun',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
