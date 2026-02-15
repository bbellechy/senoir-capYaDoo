import 'dart:io';
import 'package:flutter/material.dart';
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(
                Icons.camera_alt,
                color: AppColors.primaryBlue,
              ),
              title: const Text('ถ่ายภาพ'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: AppColors.primaryBlue,
              ),
              title: const Text('เลือกจากอัลบั้ม'),
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

    setState(() {
      _isSaving = false;
    });

    if (success) {
      if (mounted) {
        Navigator.pop(context, true);
      }
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

    setState(() {
      _isDeleting = false;
    });

    if (success) {
      if (mounted) {
        Navigator.pop(context, true);
      }
    } else {
      _showError(_controller.error ?? 'ไม่สามารถลบการแจ้งเตือนได้');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'แก้ไขการแจ้งเตือน',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: _isDeleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.delete),
            onPressed: _isDeleting ? null : _deleteNotification,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TOP CAPTURE SECTION
            const Text(
              'แก้ไขรูปภาพยา (ถ่ายภาพหรือเลือกจากอัลบั้ม)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _showImageSourceSelector,
              child: Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[300]!),
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
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'แตะเพื่อเพิ่มรูปภาพ',
                            style: TextStyle(color: Colors.grey[500]),
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
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // Medication Selection
            PillSelectionWidget(
              initialValue: _medicationName,
              onSelected: (name, _) {
                setState(() {
                  _medicationName = name;
                });
              },
            ),
            const SizedBox(height: 24),

            // Time Selector
            Text(
              'เวลา *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _selectTime,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  _selectedTime != null
                      ? '${_selectedTime!.split(':')[0]}:${_selectedTime!.split(':')[1]} น.'
                      : 'ตั้งเวลา',
                  style: TextStyle(
                    color: _selectedTime != null
                        ? Colors.black87
                        : Colors.grey[500],
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Day Selector
            Text(
              'วันที่ต้องการแจ้งเตือน',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            DaySelectorWidget(
              selectedDays: _selectedDays,
              onDaysChanged: (days) {
                setState(() {
                  _selectedDays = days;
                });
              },
            ),
            const SizedBox(height: 48),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.grey[200],
                      ),
                      child: const Text(
                        'ยกเลิก',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _updateNotification,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'บันทึก',
                              style: TextStyle(
                                fontSize: 16,
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
    );
  }
}
