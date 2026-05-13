import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:capyadoo/core/constants/app_colors.dart';

class AppSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double>? onChanged;
  final double min;
  final double max;
  final int? divisions;
  final String? label;
  final String? minLabel;
  final String? maxLabel;
  final bool enabled;
  final bool showValue;
  final bool isRequired;

  const AppSlider({
    super.key,
    required this.value,
    this.onChanged,
    this.min = 1.0,
    this.max = 10.0,
    this.divisions,
    this.label,
    this.minLabel,
    this.maxLabel,
    this.enabled = true,
    this.showValue = true,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Row(
            children: [
              Text(
                label!,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Sarabun',
                ),
              ),
              if (isRequired)
                Text(
                  ' *',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                    fontFamily: 'Sarabun',
                  ),
                ),
            ],
          ),
          SizedBox(height: 8.h),
        ],
        Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: AppColors.offwhite,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            children: [
              if (showValue)
                Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                    fontFamily: 'Sarabun',
                  ),
                ),
              if (showValue) SizedBox(height: 8.h),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.primaryBlue,
                  inactiveTrackColor: Colors.grey[300],
                  thumbColor: AppColors.primaryBlue,
                  overlayColor: AppColors.primaryBlue.withOpacity(0.2),
                  trackHeight: 6.0.h,
                  thumbShape: RoundSliderThumbShape(
                    enabledThumbRadius: 16.0.r,
                  ),
                  overlayShape: RoundSliderOverlayShape(
                    overlayRadius: 28.0.r,
                  ),
                  valueIndicatorColor: AppColors.primaryBlue,
                  valueIndicatorTextStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontFamily: 'Sarabun',
                  ),
                ),
                child: Slider(
                  value: value,
                  min: min,
                  max: max,
                  divisions: divisions ?? (max - min).toInt(),
                  onChanged: enabled ? onChanged : null,
                ),
              ),
              if (minLabel != null || maxLabel != null)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        minLabel ?? '',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Sarabun',
                        ),
                      ),
                      Text(
                        maxLabel ?? '',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Sarabun',
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class AppRangeSlider extends StatelessWidget {
  final RangeValues values;
  final ValueChanged<RangeValues>? onChanged;
  final double min;
  final double max;
  final int? divisions;
  final String? label;
  final String? minLabel;
  final String? maxLabel;
  final bool enabled;
  final bool showValues;
  final bool isRequired;

  const AppRangeSlider({
    super.key,
    required this.values,
    this.onChanged,
    this.min = 0.0,
    this.max = 100.0,
    this.divisions,
    this.label,
    this.minLabel,
    this.maxLabel,
    this.enabled = true,
    this.showValues = true,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Row(
            children: [
              Text(
                label!,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Sarabun',
                ),
              ),
              if (isRequired)
                Text(
                  ' *',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                    fontFamily: 'Sarabun',
                  ),
                ),
            ],
          ),
          SizedBox(height: 8.h),
        ],
        Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            children: [
              if (showValues)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      values.start.toInt().toString(),
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                        fontFamily: 'Sarabun',
                      ),
                    ),
                    Text(
                      ' - ',
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Sarabun',
                      ),
                    ),
                    Text(
                      values.end.toInt().toString(),
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                        fontFamily: 'Sarabun',
                      ),
                    ),
                  ],
                ),
              if (showValues) SizedBox(height: 8.h),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.primaryBlue,
                  inactiveTrackColor: Colors.grey[300],
                  thumbColor: AppColors.primaryBlue,
                  overlayColor: AppColors.primaryBlue.withOpacity(0.2),
                  trackHeight: 6.0.h,
                  thumbShape: RoundSliderThumbShape(
                    enabledThumbRadius: 16.0.r,
                  ),
                  overlayShape: RoundSliderOverlayShape(
                    overlayRadius: 28.0.r,
                  ),
                  rangeThumbShape: RoundRangeSliderThumbShape(
                    enabledThumbRadius: 16.0.r,
                  ),
                  valueIndicatorColor: AppColors.primaryBlue,
                  valueIndicatorTextStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontFamily: 'Sarabun',
                  ),
                ),
                child: RangeSlider(
                  values: values,
                  min: min,
                  max: max,
                  divisions: divisions ?? (max - min).toInt(),
                  onChanged: enabled ? onChanged : null,
                ),
              ),
              if (minLabel != null || maxLabel != null)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        minLabel ?? '',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Sarabun',
                        ),
                      ),
                      Text(
                        maxLabel ?? '',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Sarabun',
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
