import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import 'medicine_confirmation_button.dart';

enum MedicineReminderStatus {
  pending, // รอยืนยัน
  taken, // ทานแล้ว
  overdue, // เกินกำหนด
  taken_late, // ทานล่าช้า
}

class MedicineReminderCard extends StatelessWidget {
  final String medicineName;
  final String dosage; // เช่น "1 เม็ด"
  final String? imagePath;
  final String? remainingQuantityText;
  final DateTime scheduledTime;
  final String? intakeTimingLabel;
  final MedicineReminderStatus status;
  final VoidCallback? onConfirm;
  final String pendingButtonText;

  const MedicineReminderCard({
    super.key,
    required this.medicineName,
    required this.dosage,
    this.imagePath,
    this.remainingQuantityText,
    required this.scheduledTime,
    this.intakeTimingLabel,
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
      case MedicineReminderStatus.taken_late:
        return MedicineConfirmationStatus.taken_late;
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

  Widget _buildMedicineImage() {
    final path = imagePath?.trim();
    if (path == null || path.isEmpty) {
      return _buildFallbackImage();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10.r),
      child: SizedBox(
        width: 44.w,
        height: 44.h,
        child: _isNetworkPath(path)
            ? Image.network(
                path,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildFallbackImage(),
              )
            : Image.file(
                File(path),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildFallbackImage(),
              ),
      ),
    );
  }

  Widget _buildFallbackImage() {
    return Container(
      width: 44.w,
      height: 44.h,
      decoration: BoxDecoration(
        color: AppColors.blueBorder.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Icon(Icons.medication, size: 22.sp, color: AppColors.textSub),
    );
  }

  @override
  Widget build(BuildContext context) {
    final normalizedTiming = intakeTimingLabel?.trim();
    final hasTimingLabel =
        normalizedTiming != null && normalizedTiming.isNotEmpty;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.whitelist,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.blueBorder, width: 1.5.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
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
                    _buildMedicineImage(),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            medicineName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Sarabun',
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            dosage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Sarabun',
                              fontSize: 16.sp,
                              color: AppColors.textSub,
                            ),
                          ),
                          if (remainingQuantityText != null) ...[
                            SizedBox(height: 2.h),
                            Text(
                              remainingQuantityText!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Sarabun',
                                fontSize: 14.sp,
                                color: AppColors.textSub,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Icon(
                      hasTimingLabel
                          ? Icons.restaurant_rounded
                          : Icons.access_time,
                      size: 18.sp,
                      color: AppColors.textSub,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      hasTimingLabel
                          ? normalizedTiming
                          : _formatTime(scheduledTime),
                      style: TextStyle(
                        fontFamily: 'Sarabun',
                        fontSize: 18.sp,
                        color: AppColors.textSub,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
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
