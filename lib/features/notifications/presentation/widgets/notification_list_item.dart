import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.blueBorder, width: 1.5.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDeleteMode ? null : onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: Row(
              children: [
                if (isDeleteMode) ...[
                  GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      width: 40.w,
                      height: 40.h,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                ],

                // Icon or Image
                Container(
                  width: 64.w,
                  height: 64.h,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: notification.imagePath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12.r),
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
                          Icons.medication_rounded,
                          color: iconColor,
                          size: 32.sp,
                        ),
                ),
                SizedBox(width: 16.w),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.medicationName,
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 20.sp,
                            color: AppColors.primaryBlue,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            notification.times.isNotEmpty
                                ? notification.getFormattedTimes().first + ' น.'
                                : '',
                            style: TextStyle(
                              fontSize: 18.sp,
                              color: AppColors.textSub,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        notification.getDayNames().join(', '),
                        style: TextStyle(
                          fontSize: 18.sp,
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
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 20.sp,
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
