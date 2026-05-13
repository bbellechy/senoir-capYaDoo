import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:capyadoo/core/constants/app_colors.dart';

class AppCheckbox extends StatelessWidget {
  final bool value;
  final String label;
  final ValueChanged<bool?>? onChanged;
  final Color? activeColor;
  final bool tristate;

  const AppCheckbox({
    super.key,
    required this.value,
    required this.label,
    this.onChanged,
    this.activeColor,
    this.tristate = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: Row(
          children: [
            SizedBox(
              width: 40.w,
              height: 40.h,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: activeColor ?? AppColors.primaryBlue,
                tristate: tristate,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.r)),
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

class AppCheckboxGroup extends StatelessWidget {
  final List<AppCheckboxOption> options;
  final List<String> selectedValues;
  final ValueChanged<List<String>>? onChanged;
  final Color? activeColor;
  final String? title;

  const AppCheckboxGroup({
    super.key,
    required this.options,
    required this.selectedValues,
    this.onChanged,
    this.activeColor,
    this.title,
  });

  void _handleCheckboxChanged(String value, bool? checked) {
    if (onChanged == null || checked == null) return;

    final newSelectedValues = List<String>.from(selectedValues);
    if (checked) {
      if (!newSelectedValues.contains(value)) {
        newSelectedValues.add(value);
      }
    } else {
      newSelectedValues.remove(value);
    }
    onChanged!(newSelectedValues);
  }

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
          (option) => AppCheckbox(
            value: selectedValues.contains(option.value),
            label: option.label,
            onChanged: (checked) =>
                _handleCheckboxChanged(option.value, checked),
            activeColor: activeColor,
          ),
        ),
      ],
    );
  }
}

class AppCheckboxOption {
  final String value;
  final String label;

  const AppCheckboxOption({required this.value, required this.label});
}
