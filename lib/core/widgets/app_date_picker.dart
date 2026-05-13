import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_rounded_date_picker/flutter_rounded_date_picker.dart';

class AppDatePicker extends StatelessWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime?>? onDateSelected;
  final String? label;
  final String? hint;
  final String? errorText;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool enabled;
  final DateFormat? dateFormat;
  final bool isRequired;

  const AppDatePicker({
    super.key,
    this.selectedDate,
    this.onDateSelected,
    this.label,
    this.hint,
    this.errorText,
    this.firstDate,
    this.lastDate,
    this.enabled = true,
    this.dateFormat,
    this.isRequired = true,
  });

  Future<void> _selectDate(BuildContext context) async {
    if (!enabled || onDateSelected == null) return;

    // Initialize Thai locale
    await initializeDateFormatting('th', null);

    final DateTime initialDate = selectedDate ?? DateTime.now();
    final DateTime first = firstDate ?? DateTime(1900);
    final DateTime last = lastDate ?? DateTime(2100);

    final DateTime? picked = await showRoundedDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: first,
      lastDate: last,
      locale: const Locale('th', 'TH'),
      era: EraMode.BUDDHIST_YEAR,
      theme: ThemeData(
        primaryColor: AppColors.primaryBlue,
        colorScheme: ColorScheme.light(
          primary: AppColors.primaryBlue,
          onPrimary: Colors.white,
          surface: Colors.white,
          onSurface: Colors.black,
        ),
      ),
      styleDatePicker: MaterialRoundedDatePickerStyle(
        // Year display style (when showing year selection)
        textStyleYearButton: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        // Day display in header (large number)
        textStyleDayButton: TextStyle(
          fontSize: 48.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        // Current day in calendar
        textStyleCurrentDayOnCalendar: TextStyle(
          fontSize: 14.sp,
          color: AppColors.primaryBlue,
          fontWeight: FontWeight.bold,
        ),
        // Regular days in calendar
        textStyleDayOnCalendar: TextStyle(
          fontSize: 14.sp,
          color: Colors.black,
        ),
        // Selected day in calendar
        textStyleDayOnCalendarSelected: TextStyle(
          fontSize: 14.sp,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        // Disabled days
        textStyleDayOnCalendarDisabled: TextStyle(
          fontSize: 14.sp,
          color: Colors.grey[400],
        ),
        // Month and year in header (above calendar)
        textStyleMonthYearHeader: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryBlue,
        ),
        // Weekday labels style
        textStyleDayHeader: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
          color: Colors.grey[700],
        ),
        // Padding and spacing
        paddingDatePicker: EdgeInsets.zero,
        paddingMonthHeader: EdgeInsets.symmetric(
          vertical: 12.h,
          horizontal: 16.w,
        ),
        paddingActionBar: EdgeInsets.all(16.r),
        paddingDateYearHeader: EdgeInsets.all(20.r),
        // Arrow styling
        sizeArrow: 24.sp,
        colorArrowNext: AppColors.primaryBlue,
        colorArrowPrevious: AppColors.primaryBlue,
        marginLeftArrowPrevious: 12.w,
        marginTopArrowPrevious: 12.h,
        marginTopArrowNext: 12.h,
        marginRightArrowNext: 12.w,
        // Button styling
        textStyleButtonAction: TextStyle(
          fontSize: 14.sp,
          color: AppColors.primaryBlue,
          fontWeight: FontWeight.w600,
        ),
        textStyleButtonPositive: TextStyle(
          fontSize: 14.sp,
          color: AppColors.primaryBlue,
          fontWeight: FontWeight.w600,
        ),
        textStyleButtonNegative: TextStyle(
          fontSize: 14.sp,
          color: Colors.grey,
          fontWeight: FontWeight.w600,
        ),
        // Selected date decoration
        decorationDateSelected: BoxDecoration(
          color: AppColors.primaryBlue,
          shape: BoxShape.circle,
        ),
        // Background colors
        backgroundPicker: Colors.white,
        backgroundActionBar: Colors.white,
        backgroundHeaderMonth: Colors.white,
      ),
    );

    if (picked != null) {
      onDateSelected!(picked);
    }
  }

  String _formatDate(DateTime date) {
    if (dateFormat != null) {
      return dateFormat!.format(date);
    }
    // Format Thai date: วันพุธที่ 21 มกราคม พ.ศ. 2569
    final thaiYear = date.year + 543;
    final format = DateFormat('EEEEที่ d MMMM', 'th');
    return '${format.format(date)} พ.ศ. $thaiYear';
  }

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
                    color: Colors.red,
                  ),
                ),
            ],
          ),
          SizedBox(height: 8.h),
        ],
        InkWell(
          onTap: enabled ? () => _selectDate(context) : null,
          borderRadius: BorderRadius.circular(8.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: enabled ? Colors.white : Colors.grey[100],
              border: Border.all(
                color: errorText != null ? Colors.red : AppColors.textSublest,
                width: errorText != null ? 1.5.w : 1.w,
              ),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: enabled ? AppColors.primaryBlue : Colors.grey,
                  size: 20.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    selectedDate != null
                        ? _formatDate(selectedDate!)
                        : hint ?? 'เลือกวันที่',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: selectedDate != null
                          ? AppColors.textPrimary
                          : AppColors.textSub,
                      fontFamily: 'Sarabun',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (errorText != null) ...[
          SizedBox(height: 4.h),
          Padding(
            padding: EdgeInsets.only(left: 16.w),
            child: Text(
              errorText!,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.red,
                fontFamily: 'Sarabun',
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class AppDateRangePicker extends StatelessWidget {
  final DateTimeRange? selectedRange;
  final ValueChanged<DateTimeRange?>? onRangeSelected;
  final String? label;
  final String? hint;
  final String? errorText;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool enabled;
  final DateFormat? dateFormat;

  const AppDateRangePicker({
    super.key,
    this.selectedRange,
    this.onRangeSelected,
    this.label,
    this.hint,
    this.errorText,
    this.firstDate,
    this.lastDate,
    this.enabled = true,
    this.dateFormat,
  });

  Future<void> _selectDateRange(BuildContext context) async {
    if (!enabled || onRangeSelected == null) return;

    // Initialize Thai locale
    await initializeDateFormatting('th', null);

    final DateTimeRange initialRange =
        selectedRange ??
        DateTimeRange(
          start: DateTime.now(),
          end: DateTime.now().add(const Duration(days: 7)),
        );

    final DateTime first = firstDate ?? DateTime(1900);
    final DateTime last = lastDate ?? DateTime(2100);

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: initialRange,
      firstDate: first,
      lastDate: last,
      locale: const Locale('th', 'TH'),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryBlue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onRangeSelected!(picked);
    }
  }

  String _formatDateRange(DateTimeRange range) {
    if (dateFormat != null) {
      return '${dateFormat!.format(range.start)} - ${dateFormat!.format(range.end)}';
    }
    // Format Thai date range: 21 มกราคม พ.ศ. 2569 - 28 มกราคม พ.ศ. 2569
    final startThaiYear = range.start.year + 543;
    final endThaiYear = range.end.year + 543;
    final format = DateFormat('d MMMM', 'th');
    return '${format.format(range.start)} พ.ศ. $startThaiYear - ${format.format(range.end)} พ.ศ. $endThaiYear';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              fontFamily: 'Sarabun',
            ),
          ),
          SizedBox(height: 8.h),
        ],
        InkWell(
          onTap: enabled ? () => _selectDateRange(context) : null,
          borderRadius: BorderRadius.circular(8.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: enabled ? Colors.white : Colors.grey[100],
              border: Border.all(
                color: errorText != null ? Colors.red : AppColors.textSublest,
                width: errorText != null ? 1.5.w : 1.w,
              ),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.date_range,
                  color: enabled ? AppColors.primaryBlue : Colors.grey,
                  size: 20.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    selectedRange != null
                        ? _formatDateRange(selectedRange!)
                        : hint ?? 'เลือกช่วงวันที่',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: selectedRange != null
                          ? AppColors.textPrimary
                          : AppColors.textSub,
                      fontFamily: 'Sarabun',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (errorText != null) ...[
          SizedBox(height: 4.h),
          Padding(
            padding: EdgeInsets.only(left: 16.w),
            child: Text(
              errorText!,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.red,
                fontFamily: 'Sarabun',
              ),
            ),
          ),
        ],
      ],
    );
  }
}
