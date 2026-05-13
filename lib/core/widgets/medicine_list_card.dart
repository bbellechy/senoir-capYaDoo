import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:capyadoo/core/config/api_config.dart';
import 'package:capyadoo/core/widgets/app_time_chip.dart' as time_chip;

/// List card สำหรับรายการยา - มีรูปภาพ, หัวข้อ, รายละเอียด, time chips, ปุ่มแก้ไข/ลบ
class MedicineListCard extends StatelessWidget {
  final File? image;
  final String? imagePath;
  final String name;
  final String amount;
  final int frequency;
  final String mealTiming;
  final String expiryDate;
  final List<String> mealTimes;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const MedicineListCard({
    super.key,
    this.image,
    this.imagePath,
    required this.name,
    required this.amount,
    required this.frequency,
    required this.mealTiming,
    required this.expiryDate,
    required this.mealTimes,
    this.onEdit,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Medicine image
              Container(
                width: 80.w,
                height: 80.h,
                decoration: BoxDecoration(
                  color: AppColors.dinner,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: _buildImage(),
              ),
              SizedBox(width: 16.w),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + Action buttons
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Sarabun',
                            ),
                          ),
                        ),
                        if (onEdit != null || onDelete != null)
                          SizedBox(width: 8.w),
                        if (onEdit != null)
                          _ActionButton(
                            icon: Icons.create_rounded,
                            color: AppColors.textSub,
                            onTap: onEdit,
                          ),
                        if (onEdit != null && onDelete != null)
                          SizedBox(width: 8.w),
                        if (onDelete != null)
                          _ActionButton(
                            icon: Icons.delete_rounded,
                            color: AppColors.error,
                            onTap: onDelete,
                          ),
                      ],
                    ),
                    SizedBox(height: 8.h),

                    // Details
                    Text(
                      'ปริมาณ: $amount',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: AppColors.textSub,
                        fontFamily: 'Sarabun',
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'จำนวนครั้ง: $frequency ครั้ง',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: AppColors.textSub,
                        fontFamily: 'Sarabun',
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'รับประทาน: $mealTiming',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: AppColors.textSub,
                        fontFamily: 'Sarabun',
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'หมดอายุ: $expiryDate',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: AppColors.textSub,
                        fontFamily: 'Sarabun',
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // Time chips
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: mealTimes.map((mealTime) {
                        final timeOfDay = _getTimeOfDay(mealTime);
                        if (timeOfDay != null) {
                          return time_chip.AppTimeChip(timeOfDay: timeOfDay);
                        }
                        return const SizedBox.shrink();
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildImage() {
    final resolvedPath = _resolveImagePath(imagePath);
    if (resolvedPath != null && resolvedPath.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: resolvedPath.startsWith('http')
            ? Image.network(
                resolvedPath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image),
              )
            : Image.file(
                File(resolvedPath),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image),
              ),
      );
    } else if (image != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(image!, fit: BoxFit.cover),
      );
    }
    return Icon(Icons.medication, size: 40, color: AppColors.primaryBlue);
  }

  String? _resolveImagePath(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;

    final normalizedPath = path.replaceAll('\\', '/');
    if (normalizedPath.contains(':') ||
        normalizedPath.startsWith('/') ||
        normalizedPath.contains('Documents/') ||
        normalizedPath.contains('data/user/')) {
      return path;
    }

    if (normalizedPath.startsWith('uploads/')) {
      return '${ApiConfig.baseUrl}/$normalizedPath';
    }

    return '${ApiConfig.baseUrl}/$normalizedPath';
  }

  time_chip.TimeOfDay? _getTimeOfDay(String mealTime) {
    switch (mealTime) {
      case 'เช้า':
        return time_chip.TimeOfDay.morning;
      case 'กลางวัน':
        return time_chip.TimeOfDay.noon;
      case 'เย็น':
        return time_chip.TimeOfDay.evening;
      case 'ก่อนนอน':
        return time_chip.TimeOfDay.bedtime;
      default:
        return null;
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.blueBorder, width: 1),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}
