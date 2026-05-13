import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:capyadoo/core/constants/app_colors.dart';

class AppRadioButton<T> extends StatelessWidget {
  final T value;
  final T? groupValue;
  final String label;
  final ValueChanged<T?>? onChanged;
  final Color? activeColor;

  const AppRadioButton({
    super.key,
    required this.value,
    required this.groupValue,
    required this.label,
    this.onChanged,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onChanged != null ? () => onChanged!(value) : null,
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: Row(
          children: [
            SizedBox(
              width: 40.w,
              height: 40.h,
              child: Radio<T>(
                value: value,
                groupValue: groupValue,
                onChanged: onChanged,
                activeColor: activeColor ?? AppColors.primaryBlue,
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Sarabun',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppRadioGroup<T> extends StatelessWidget {
  final T? groupValue;
  final List<AppRadioOption<T>> options;
  final ValueChanged<T?>? onChanged;
  final Color? activeColor;
  final String? title;

  const AppRadioGroup({
    super.key,
    required this.groupValue,
    required this.options,
    this.onChanged,
    this.activeColor,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              fontFamily: 'Sarabun',
            ),
          ),
          SizedBox(height: 12.h),
        ],
        ...options.map(
          (option) => AppRadioButton<T>(
            value: option.value,
            groupValue: groupValue,
            label: option.label,
            onChanged: onChanged,
            activeColor: activeColor,
          ),
        ),
      ],
    );
  }
}

class AppRadioOption<T> {
  final T value;
  final String label;

  const AppRadioOption({required this.value, required this.label});
}
