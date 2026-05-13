import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:capyadoo/core/constants/app_colors.dart';

/// List card สำหรับกล่องยา - มีไอคอน, ชื่อ, จำนวนรายการยา, ปุ่มแก้ไข/ลบ
class MedicineBoxListCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final String? imagePath;
  final String name;
  final int medicineCount;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const MedicineBoxListCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    this.imagePath,
    required this.name,
    required this.medicineCount,
    this.onEdit,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.blueBorder, width: 1.w),
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
            children: [
              // Icon
              _buildLeadingVisual(),
              SizedBox(width: 16.w),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(
                          Icons.medication,
                          size: 16.sp,
                          color: AppColors.textSub,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '$medicineCount รายการยา',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: AppColors.textSub,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action buttons
              if (onEdit != null)
                _ActionButton(
                  icon: Icons.create_rounded,
                  color: AppColors.textSub,
                  onTap: onEdit,
                ),
              if (onEdit != null && onDelete != null) SizedBox(width: 8.w),
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
      borderRadius: BorderRadius.circular(12.r),
      child: SizedBox(
        width: 64.w,
        height: 64.h,
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
      width: 64.w,
      height: 64.h,
      decoration: BoxDecoration(
        color: iconBackgroundColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Icon(icon, size: 32.sp, color: iconColor),
    );
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
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        width: 36.w,
        height: 36.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: AppColors.blueBorder, width: 1.w),
        ),
        child: Icon(icon, size: 20.sp, color: color),
      ),
    );
  }
}
