import 'dart:io';

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
  final String? imagePath;

  const MedicineInBox({
    required this.name,
    required this.dosage,
    this.imagePath,
  });
}

class MedicineBoxReminderCard extends StatelessWidget {
  final String boxName;
  final String? boxImagePath;
  final List<MedicineInBox> medicines;
  final DateTime scheduledTime;
  final String? intakeTimingLabel;
  final MedicineBoxReminderStatus status;
  final VoidCallback? onConfirm;
  final VoidCallback? onTap;
  final String pendingButtonText;

  const MedicineBoxReminderCard({
    super.key,
    required this.boxName,
    this.boxImagePath,
    required this.medicines,
    required this.scheduledTime,
    this.intakeTimingLabel,
    required this.status,
    this.onConfirm,
    this.onTap,
    this.pendingButtonText = 'ยืนยันการทาน',
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

  bool _isNetworkPath(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  Widget _buildImage(
    String? path, {
    double size = 40,
    IconData fallbackIcon = Icons.medication,
  }) {
    final imagePath = path?.trim();

    if (imagePath == null || imagePath.isEmpty) {
      return _buildFallbackImage(size: size, icon: fallbackIcon);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: size,
        height: size,
        child: _isNetworkPath(imagePath)
            ? Image.network(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _buildFallbackImage(size: size, icon: fallbackIcon),
              )
            : Image.file(
                File(imagePath),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _buildFallbackImage(size: size, icon: fallbackIcon),
              ),
      ),
    );
  }

  Widget _buildFallbackImage({required double size, required IconData icon}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.blueBorder.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: size * 0.52, color: AppColors.textSub),
    );
  }

  @override
  Widget build(BuildContext context) {
    final normalizedTiming = intakeTimingLabel?.trim();
    final hasTimingLabel =
        normalizedTiming != null && normalizedTiming.isNotEmpty;

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
                  _buildImage(
                    boxImagePath,
                    size: 40,
                    fallbackIcon: Icons.inventory_2,
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
                    pendingText: pendingButtonText,
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
                      const SizedBox(width: 4),
                      _buildImage(medicine.imagePath, size: 28),
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
                  Icon(
                    hasTimingLabel
                        ? Icons.restaurant_rounded
                        : Icons.access_time,
                    size: 18,
                    color: AppColors.textSub,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    hasTimingLabel
                        ? normalizedTiming
                        : _formatTime(scheduledTime),
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
