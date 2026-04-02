import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'medicine_confirmation_button.dart';

enum MedicineBoxReminderStatus {
  pending, // รอยืนยัน
  taken, // ทานแล้ว
  overdue, // เกินกำหนด
}

class MedicineInBox {
  final String name;
  final String dosage;

  const MedicineInBox({required this.name, required this.dosage});
}

class MedicineBoxReminderCard extends StatelessWidget {
  final String boxName;
  final List<MedicineInBox> medicines;
  final DateTime scheduledTime;
  final MedicineBoxReminderStatus status;
  final VoidCallback? onConfirm;
  final VoidCallback? onTap;

  const MedicineBoxReminderCard({
    super.key,
    required this.boxName,
    required this.medicines,
    required this.scheduledTime,
    required this.status,
    this.onConfirm,
    this.onTap,
  });

  // ตรวจสอบว่าเลยเวลาหรือไม่
  bool get _isOverdue {
    return DateTime.now().isAfter(scheduledTime) &&
        status == MedicineBoxReminderStatus.pending;
  }

  // กำหนด effective status โดยพิจารณาจากเวลา
  MedicineBoxReminderStatus get _effectiveStatus {
    if (status == MedicineBoxReminderStatus.pending && _isOverdue) {
      return MedicineBoxReminderStatus.overdue;
    }
    return status;
  }

  // แปลง MedicineBoxReminderStatus เป็น MedicineConfirmationStatus
  MedicineConfirmationStatus _getConfirmationStatus() {
    final effectiveStatus = _effectiveStatus;
    switch (effectiveStatus) {
      case MedicineBoxReminderStatus.pending:
        return MedicineConfirmationStatus.pending;
      case MedicineBoxReminderStatus.taken:
        return MedicineConfirmationStatus.taken;
      case MedicineBoxReminderStatus.overdue:
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header - ชื่อกล่องยา
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.inventory_2,
                      size: 24,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      boxName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Sarabun',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  MedicineConfirmationButton(
                    status: _getConfirmationStatus(),
                    onConfirm: onConfirm,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // รายการยาในกล่อง
              ...medicines.map(
                (medicine) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.medication,
                        size: 16,
                        color: AppColors.textSub,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              medicine.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Sarabun',
                                fontSize: 18,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '(${medicine.dosage})',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Sarabun',
                                fontSize: 16,
                                color: AppColors.textSub,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // เวลาและปุ่ม
              Row(
                children: [
                  const SizedBox(width: 12),
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
                  const Spacer(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
