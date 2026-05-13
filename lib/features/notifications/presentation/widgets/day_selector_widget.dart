import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:capyadoo/core/constants/app_colors.dart';

class DaySelectorWidget extends StatefulWidget {
  final List<int> selectedDays;
  final Function(List<int>) onDaysChanged;

  const DaySelectorWidget({
    super.key,
    required this.selectedDays,
    required this.onDaysChanged,
  });

  @override
  State<DaySelectorWidget> createState() => _DaySelectorWidgetState();
}

class _DaySelectorWidgetState extends State<DaySelectorWidget> {
  late List<int> _selectedDays;

  static const List<Map<String, dynamic>> _days = [
    {'value': 1, 'label': 'จ'},
    {'value': 2, 'label': 'อ'},
    {'value': 3, 'label': 'พ'},
    {'value': 4, 'label': 'พฤ'},
    {'value': 5, 'label': 'ศ'},
    {'value': 6, 'label': 'ส'},
    {'value': 7, 'label': 'อา'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedDays = List.from(widget.selectedDays);
  }

  @override
  void didUpdateWidget(DaySelectorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDays != widget.selectedDays) {
      _selectedDays = List.from(widget.selectedDays);
    }
  }

  void _toggleDay(int day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
      _selectedDays.sort();
    });
    widget.onDaysChanged(_selectedDays);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _days.map((day) {
        final isSelected = _selectedDays.contains(day['value']);
        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: GestureDetector(
              onTap: () => _toggleDay(day['value']),
              child: Container(
                height: 40.h,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryBlue : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Center(
                  child: Text(
                    day['label'],
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.textSub,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
