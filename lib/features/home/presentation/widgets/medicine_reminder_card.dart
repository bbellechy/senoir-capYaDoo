import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'medicine_confirmation_button.dart';

enum MedicineReminderStatus {
  pending, // รอยืนยัน
  taken, // ทานแล้ว
  overdue, // เกินกำหนด
}

class MedicineReminderCard extends StatelessWidget {
  final String medicineName;
  final String dosage; // เช่น "1 เม็ด"
  final String? remainingQuantityText;
  final DateTime scheduledTime;
  final MedicineReminderStatus status;
  final VoidCallback? onConfirm;
  final String pendingButtonText;

  const MedicineReminderCard({
    super.key,
    required this.medicineName,
    required this.dosage,
    this.remainingQuantityText,
    required this.scheduledTime,
    required this.status,
    this.onConfirm,
    this.pendingButtonText = 'ยืนยันการทาน',
  });

  // ตรวจสอบว่าเลยเวลาหรือไม่
  bool get _isOverdue {
    return DateTime.now().isAfter(scheduledTime) &&
        status == MedicineReminderStatus.pending;
  }

  // กำหนด effective status โดยพิจารณาจากเวลา
  MedicineReminderStatus get _effectiveStatus {
    if (status == MedicineReminderStatus.pending && _isOverdue) {
      return MedicineReminderStatus.overdue;
    }
    return status;
  }

  // แปลง MedicineReminderStatus เป็น MedicineConfirmationStatus
  MedicineConfirmationStatus _getConfirmationStatus() {
    final effectiveStatus = _effectiveStatus;
    switch (effectiveStatus) {
      case MedicineReminderStatus.pending:
        return MedicineConfirmationStatus.pending;
      case MedicineReminderStatus.taken:
        return MedicineConfirmationStatus.taken;
      case MedicineReminderStatus.overdue:
        return MedicineConfirmationStatus.overdue;
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute น.';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.whitelist,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.blueBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // ข้อมูลยา
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            medicineName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Sarabun',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dosage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Sarabun',
                              fontSize: 16,
                              color: AppColors.textSub,
                            ),
                          ),
                          if (remainingQuantityText != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              remainingQuantityText!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Sarabun',
                                fontSize: 14,
                                color: AppColors.textSub,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 18,
                      color: AppColors.textSub,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(scheduledTime),
                      style: const TextStyle(
                        fontFamily: 'Sarabun',
                        fontSize: 18,
                        color: AppColors.textSub,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // ปุ่ม action
          MedicineConfirmationButton(
            status: _getConfirmationStatus(),
            onConfirm: onConfirm,
            pendingText: pendingButtonText,
          ),
        ],
      ),
    );
  }
}
