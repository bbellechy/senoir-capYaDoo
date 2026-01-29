import 'package:flutter/material.dart';
import 'package:capyadoo/core/model/medication_notification.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'dart:io';

class NotificationListItem extends StatelessWidget {
  final MedicationNotification notification;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;
  final bool isDeleteMode;
  final bool isSelected;
  final ValueChanged<bool?>? onSelectionChanged;

  const NotificationListItem({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onToggle,
    this.isDeleteMode = false,
    this.isSelected = false,
    this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = notification.isEnabled;
    final iconColor = isEnabled
        ? AppColors.primaryBlue
        : const Color(0xFFEF5350);
    final iconBgColor = isEnabled
        ? AppColors.primaryBlue.withOpacity(0.1)
        : const Color(0xFFEF5350).withOpacity(0.1);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDeleteMode
              ? () => onSelectionChanged?.call(!isSelected)
              : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (isDeleteMode) ...[
                  Checkbox(
                    value: isSelected,
                    onChanged: (value) => onSelectionChanged?.call(value),
                    activeColor: AppColors.primaryBlue,
                  ),
                  const SizedBox(width: 8),
                ],

                // Icon or Image
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: notification.imagePath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: (notification.imagePath!.startsWith('http')
                              ? Image.network(
                                  notification.imagePath!,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  File(notification.imagePath!),
                                  fit: BoxFit.cover,
                                )),
                        )
                      : Icon(
                          Icons.access_time_filled,
                          color: iconColor,
                          size: 24,
                        ),
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.medicationName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: AppColors.primaryBlue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            notification.times.isNotEmpty
                                ? notification.getFormattedTimes().first + ' น.'
                                : '',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        notification.getDayNames().join(', '),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                if (!isDeleteMode) ...[
                  Switch(
                    value: isEnabled,
                    onChanged: onToggle,
                    activeColor: Colors.white,
                    activeTrackColor: const Color(0xFF4CAF50),
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.grey[300],
                  ),
                ] else ...[
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
