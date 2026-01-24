import 'package:flutter/material.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:capyadoo/core/widgets/app_button.dart';
import 'package:capyadoo/core/widgets/app_text_field.dart';
import 'package:capyadoo/core/model/medication_notification.dart';
import 'package:capyadoo/features/notifications/controller/notification_controller.dart';
import 'package:capyadoo/features/notifications/presentation/widgets/day_selector_widget.dart';
import 'package:capyadoo/features/notifications/presentation/widgets/time_selector_widget.dart';

class EditNotificationPage extends StatefulWidget {
  final MedicationNotification notification;

  const EditNotificationPage({super.key, required this.notification});

  @override
  State<EditNotificationPage> createState() => _EditNotificationPageState();
}

class _EditNotificationPageState extends State<EditNotificationPage> {
  late TextEditingController _medicationNameController;
  final NotificationController _controller = NotificationController();

  late List<int> _selectedDays;
  late List<String> _selectedTimes;
  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _medicationNameController = TextEditingController(
      text: widget.notification.medicationName,
    );
    _selectedDays = List.from(widget.notification.days);
    _selectedTimes = List.from(widget.notification.times);
  }

  @override
  void dispose() {
    _medicationNameController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _updateNotification() async {
    // Validate inputs
    if (_medicationNameController.text.trim().isEmpty) {
      _showError('กรุณาระบุชื่อยา');
      return;
    }

    if (_selectedDays.isEmpty) {
      _showError('กรุณาเลือกวันที่ต้องการแจ้งเตือน');
      return;
    }

    if (_selectedTimes.isEmpty) {
      _showError('กรุณาเลือกเวลาที่ต้องการแจ้งเตือน');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final updatedNotification = widget.notification.copyWith(
      medicationName: _medicationNameController.text.trim(),
      days: _selectedDays,
      times: _selectedTimes,
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
      appBar: AppBar(
        title: const Text(
          'แก้ไขการแจ้งเตือน',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Medication name input
            AppTextField(
              controller: _medicationNameController,
              label: 'ชื่อยา *',
              hint: 'ระบุชื่อยา',
              prefixIcon: const Icon(Icons.medication),
            ),
            const SizedBox(height: 24),

            // Day selector
            const Text(
              'วัน *',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            DaySelectorWidget(
              selectedDays: _selectedDays,
              onDaysChanged: (days) {
                setState(() {
                  _selectedDays = days;
                });
              },
            ),
            const SizedBox(height: 24),

            // Time selector
            const Text(
              'เวลา *',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TimeSelectorWidget(
              selectedTimes: _selectedTimes,
              onTimesChanged: (times) {
                setState(() {
                  _selectedTimes = times;
                });
              },
            ),
            const SizedBox(height: 32),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'ยกเลิก',
                    onPressed: () => Navigator.pop(context),
                    isOutlined: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppButton(
                    text: 'บันทึก',
                    onPressed: _updateNotification,
                    isLoading: _isSaving,
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
