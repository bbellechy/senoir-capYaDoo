import 'package:flutter/material.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:capyadoo/core/widgets/app_button.dart';
import 'package:capyadoo/core/widgets/app_text_field.dart';
import 'package:capyadoo/core/model/medication_notification.dart';
import 'package:capyadoo/features/notifications/controller/notification_controller.dart';
import 'package:capyadoo/features/notifications/presentation/widgets/day_selector_widget.dart';
import 'package:capyadoo/features/notifications/presentation/widgets/time_selector_widget.dart';

class AddNotificationPage extends StatefulWidget {
  const AddNotificationPage({super.key});

  @override
  State<AddNotificationPage> createState() => _AddNotificationPageState();
}

class _AddNotificationPageState extends State<AddNotificationPage> {
  final TextEditingController _medicationNameController =
      TextEditingController();
  final NotificationController _controller = NotificationController();

  List<int> _selectedDays = [];
  List<String> _selectedTimes = [];
  bool _isSaving = false;

  @override
  void dispose() {
    _medicationNameController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveNotification() async {
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

    final notification = MedicationNotification(
      medicationName: _medicationNameController.text.trim(),
      days: _selectedDays,
      times: _selectedTimes,
      isEnabled: true,
    );

    final success = await _controller.addNotification(notification);

    setState(() {
      _isSaving = false;
    });

    if (success) {
      if (mounted) {
        Navigator.pop(context, true);
      }
    } else {
      _showError(_controller.error ?? 'ไม่สามารถบันทึกการแจ้งเตือนได้');
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
          'เพิ่มการแจ้งเตือน',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
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
                    onPressed: _saveNotification,
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
