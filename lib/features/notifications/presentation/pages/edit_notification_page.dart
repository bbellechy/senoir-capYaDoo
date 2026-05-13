import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:capyadoo/core/model/medication_notification.dart';
import 'package:capyadoo/features/notifications/controller/notification_controller.dart';
import 'package:capyadoo/features/notifications/presentation/widgets/day_selector_widget.dart';
import 'package:capyadoo/features/notifications/presentation/widgets/pill_selection_widget.dart';
import 'package:image_picker/image_picker.dart';

class EditNotificationPage extends StatefulWidget {
  final MedicationNotification notification;

  const EditNotificationPage({super.key, required this.notification});

  @override
  State<EditNotificationPage> createState() => _EditNotificationPageState();
}

class _EditNotificationPageState extends State<EditNotificationPage> {
  final NotificationController _controller = NotificationController();

  late String? _medicationName;
  late String? _imagePath;
  late List<int> _selectedDays;
  late String? _selectedTime;
  bool _isSaving = false;
  bool _isDeleting = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 300,
        maxHeight: 300,
        imageQuality: 60,
      );

      if (image != null) {
        setState(() {
          _imagePath = image.path;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _showImageSourceSelector() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(
                Icons.camera_alt,
                color: AppColors.primaryBlue,
                size: 24.sp,
              ),
              title: Text('ถ่ายภาพ', style: TextStyle(fontSize: 16.sp)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.photo_library,
                color: AppColors.primaryBlue,
                size: 24.sp,
              ),
              title: Text('เลือกจากอัลบั้ม', style: TextStyle(fontSize: 16.sp)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _medicationName = widget.notification.medicationName;
    _imagePath = widget.notification.imagePath;
    _selectedDays = List.from(widget.notification.days);
    if (widget.notification.times.isNotEmpty) {
      _selectedTime = widget.notification.times.first;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final TimeOfDay initialTime = _selectedTime != null
        ? TimeOfDay(
            hour: int.parse(_selectedTime!.split(':')[0]),
            minute: int.parse(_selectedTime!.split(':')[1]),
          )
        : TimeOfDay.now();

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      initialEntryMode: TimePickerEntryMode.input,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: AppColors.primaryBlue,
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryBlue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00';
      });
    }
  }

  Future<void> _updateNotification() async {
    if (_medicationName == null || _medicationName!.isEmpty) {
      _showError('กรุณาเลือกยาหรือกล่องยา');
      return;
    }

    if (_selectedTime == null) {
      _showError('กรุณาเลือกเวลาที่ต้องการแจ้งเตือน');
      return;
    }

    if (_selectedDays.isEmpty) {
      _showError('กรุณาเลือกวันที่ต้องการแจ้งเตือน');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final updatedNotification = widget.notification.copyWith(
      medicationName: _medicationName!,
      days: _selectedDays,
      times: [_selectedTime!],
      imagePath: _imagePath,
    );

    final success = await _controller.updateNotification(updatedNotification);

    if (!mounted) return;
    setState(() {
      _isSaving = false;
    });

    if (success) {
      Navigator.pop(context, true);
    } else {
      _showError(_controller.error ?? 'ไม่สามารถอัปเดตการแจ้งเตือนได้');
    }
  }

  Future<void> _deleteNotification() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text('คุณต้องการลบการแจ้งเตือนนี้ใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (widget.notification.id == null) {
      _showError('ไม่สามารถลบการแจ้งเตือนได้');
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    final success = await _controller.deleteNotification(
      widget.notification.id!,
    );

    if (!mounted) return;
    setState(() {
      _isDeleting = false;
    });

    if (success) {
      Navigator.pop(context, true);
    } else {
      _showError(_controller.error ?? 'ไม่สามารถลบการแจ้งเตือนได้');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(fontFamily: 'Sarabun', fontSize: 14.sp),
        ),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            height: 160.h,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32.r),
                bottomRight: Radius.circular(32.r),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  Positioned(
                    right: -50.w,
                    top: -50.h,
                    child: Container(
                      width: 200.w,
                      height: 200.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -30.w,
                    bottom: -30.h,
                    child: Container(
                      width: 140.w,
                      height: 140.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                          left: 30.w,
                          right: 30.w,
                          bottom: 20.h,
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.arrow_back_ios,
                                color: Colors.white,
                                size: 24.sp,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                             Expanded(
                              child: Text(
                                'แก้ไขการแจ้งเตือน',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'แก้ไขรูปภาพยา (ถ่ายภาพหรือเลือกจากอัลบั้ม)',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  GestureDetector(
                    onTap: _showImageSourceSelector,
                    child: Container(
                      width: double.infinity,
                      height: 180.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: Colors.grey[300]!, width: 1.w),
                        image: _imagePath != null
                            ? DecorationImage(
                                image: _imagePath!.startsWith('http')
                                    ? NetworkImage(_imagePath!) as ImageProvider
                                    : FileImage(File(_imagePath!)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _imagePath == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo_outlined,
                                  size: 48.sp,
                                  color: Colors.grey[400],
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  'แตะเพื่อเพิ่มรูปภาพ',
                                  style: TextStyle(color: Colors.grey[500], fontSize: 14.sp),
                                ),
                              ],
                            )
                          : Align(
                              alignment: Alignment.bottomRight,
                              child: Container(
                                margin: const EdgeInsets.all(12),
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 20.sp,
                                ),
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  PillSelectionWidget(
                    initialValue: _medicationName,
                    onSelected: (name, _) {
                      setState(() {
                        _medicationName = name;
                      });
                    },
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    'เวลา *',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  GestureDetector(
                    onTap: _selectTime,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.grey[300]!, width: 1.w),
                      ),
                      child: Text(
                        _selectedTime != null
                            ? '${_selectedTime!.split(':')[0]}:${_selectedTime!.split(':')[1]} น.'
                            : 'ตั้งเวลา',
                        style: TextStyle(
                          color: _selectedTime != null
                              ? Colors.black87
                              : Colors.grey[500],
                          fontSize: 16.sp,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    'วันที่ต้องการแจ้งเตือน',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  DaySelectorWidget(
                    selectedDays: _selectedDays,
                    onDaysChanged: (days) {
                      setState(() {
                        _selectedDays = days;
                      });
                    },
                  ),
                  SizedBox(height: 48.h),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50.h,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey[600],
                              side: BorderSide(color: Colors.grey[300]!, width: 1.w),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              backgroundColor: Colors.grey[200],
                            ),
                            child: Text(
                              'ยกเลิก',
                              style: TextStyle(fontSize: 16.sp),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: SizedBox(
                          height: 50.h,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _updateNotification,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            child: _isSaving
                                ? SizedBox(
                                    width: 20.w,
                                    height: 20.h,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.w,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'บันทึก',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
