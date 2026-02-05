import 'dart:io';
import 'package:flutter/material.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:capyadoo/core/widgets/app_time_chip.dart' as time_chip;

/// List card สำหรับรายการยา - มีรูปภาพ, หัวข้อ, รายละเอียด, time chips, ปุ่มแก้ไข/ลบ
class MedicineListCard extends StatelessWidget {
  final File? image;
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
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.offwhite,
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Medicine image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.dinner,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: image != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(image!, fit: BoxFit.cover),
                      )
                    : Icon(
                        Icons.medication,
                        size: 40,
                        color: AppColors.primaryBlue,
                      ),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Details
                    Text(
                      'ปริมาณ: $amount',
                      style: TextStyle(fontSize: 14, color: AppColors.textSub),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'จำนวนครั้ง: $frequency ครั้ง',
                      style: TextStyle(fontSize: 14, color: AppColors.textSub),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'รับประทาน: $mealTiming',
                      style: TextStyle(fontSize: 14, color: AppColors.textSub),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'หมดอายุ: $expiryDate',
                      style: TextStyle(fontSize: 14, color: AppColors.textSub),
                    ),
                    const SizedBox(height: 12),

                    // Time chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
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

              // Action buttons
              const SizedBox(width: 8),
              Row(
                children: [
                  if (onEdit != null)
                    _ActionButton(
                      icon: Icons.edit,
                      color: AppColors.textSub,
                      onTap: onEdit,
                    ),
                  if (onEdit != null && onDelete != null)
                    const SizedBox(width: 8),
                  if (onDelete != null)
                    _ActionButton(
                      icon: Icons.delete,
                      color: AppColors.error,
                      onTap: onDelete,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
