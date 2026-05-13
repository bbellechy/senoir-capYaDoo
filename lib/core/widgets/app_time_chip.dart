import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:capyadoo/core/constants/app_colors.dart';

enum TimeOfDay { morning, noon, evening, bedtime }

class AppTimeChip extends StatelessWidget {
  final TimeOfDay timeOfDay;
  final VoidCallback? onTap;
  final double? width;

  const AppTimeChip({
    super.key,
    required this.timeOfDay,
    this.onTap,
    this.width,
  });

  String get _label {
    switch (timeOfDay) {
      case TimeOfDay.morning:
        return 'เช้า';
      case TimeOfDay.noon:
        return 'กลางวัน';
      case TimeOfDay.evening:
        return 'เย็น';
      case TimeOfDay.bedtime:
        return 'ก่อนนอน';
    }
  }

  Color get _backgroundColor {
    switch (timeOfDay) {
      case TimeOfDay.morning:
        return AppColors.morning;
      case TimeOfDay.noon:
        return AppColors.noon;
      case TimeOfDay.evening:
        return AppColors.dinner;
      case TimeOfDay.bedtime:
        return AppColors.sleep;
    }
  }

  Color get _borderColor {
    switch (timeOfDay) {
      case TimeOfDay.morning:
        return AppColors.morningBorder;
      case TimeOfDay.noon:
        return AppColors.noonBorder;
      case TimeOfDay.evening:
        return AppColors.dinnerBorder;
      case TimeOfDay.bedtime:
        return AppColors.sleepBorder;
    }
  }

  Color get _textColor {
    switch (timeOfDay) {
      case TimeOfDay.morning:
        return AppColors.primaryYellow;
      case TimeOfDay.noon:
        return AppColors.noonIcon;
      case TimeOfDay.evening:
        return AppColors.primaryBlue;
      case TimeOfDay.bedtime:
        return AppColors.sleepIcon;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        width: width?.w ?? 72.w,
        height: 24.h,
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: _borderColor, width: 1.5.w),
        ),
        child: Center(
          child: Text(
            _label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: _textColor,
              fontFamily: 'Sarabun',
            ),
          ),
        ),
      ),
    );
  }
}
