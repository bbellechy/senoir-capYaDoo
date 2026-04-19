import 'dart:io';

import 'package:flutter/material.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:capyadoo/core/widgets/app_time_chip.dart' as time_chip;

/// List card แบบง่ายสำหรับรายการยา - มีไอคอน, ชื่อ, จำนวน, time chips, ปุ่มลบอย่างเดียว
class SimpleMedicineListCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final String? imagePath;
  final String name;
  final String amount;
  final List<String> mealTimes;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const SimpleMedicineListCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    this.imagePath,
    required this.name,
    required this.amount,
    required this.mealTimes,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.blueBorder, width: 1.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Icon
              _buildLeadingVisual(),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      amount,
                      style: TextStyle(fontSize: 16, color: AppColors.textSub),
                    ),
                    const SizedBox(height: 8),

                    // Time chips
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
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

              // Delete button
              if (onDelete != null)
                _ActionButton(
                  icon: Icons.delete_rounded,
                  color: AppColors.error,
                  onTap: onDelete,
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isNetworkPath(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  Widget _buildLeadingVisual() {
    final path = imagePath?.trim();
    if (path == null || path.isEmpty) {
      return _buildFallbackIcon();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 56,
        height: 56,
        child: _isNetworkPath(path)
            ? Image.network(
                path,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildFallbackIcon(),
              )
            : Image.file(
                File(path),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildFallbackIcon(),
              ),
      ),
    );
  }

  Widget _buildFallbackIcon() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: iconBackgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 28, color: iconColor),
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
