import 'package:flutter/material.dart';
import 'package:capyadoo/core/model/medication_notification.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'dart:io';

class NotificationListItem extends StatelessWidget {
  final MedicationNotification notification;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;
  final bool isDeleteMode;
  final VoidCallback? onDelete;

  const NotificationListItem({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onToggle,
    this.isDeleteMode = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = notification.isEnabled;
    final iconColor = isEnabled ? AppColors.primaryBlue : AppColors.error;
    final iconBgColor = isEnabled
        ? AppColors.primaryBlue.withOpacity(0.1)
        : AppColors.error.withOpacity(0.1);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.blueBorder, width: 1.5),
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
          onTap: isDeleteMode ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (isDeleteMode) ...[
                  GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],

                // Icon or Image
                Container(
                  width: 64,
                  height: 64,
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
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 20,
                            color: AppColors.primaryBlue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            notification.times.isNotEmpty
                                ? notification.getFormattedTimes().first + ' น.'
                                : '',
                            style: TextStyle(
                              fontSize: 18,
                              color: AppColors.textSub,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        notification.getDayNames().join(', '),
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.textSub,
                        ),
                      ),
                    ],
                  ),
                ),

                if (!isDeleteMode) ...[
                  Switch(
                    value: isEnabled,
                    onChanged: onToggle,
                    activeColor: Colors.white,
                    activeTrackColor: AppColors.success,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: AppColors.textSublest,
                  ),
                ] else ...[
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 20,
                    color: AppColors.textSub,
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
