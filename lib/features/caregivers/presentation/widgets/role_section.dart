import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:capyadoo/core/constants/app_colors.dart';

/// แสดงบทบาทของผู้ใช้งาน (ผู้ใช้งาน, ผู้ดูแล)
class RoleSection extends StatelessWidget {
  final bool isCaregiver;

  const RoleSection({super.key, required this.isCaregiver});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ดูข้อมูลยาของผู้ป่วยในความดูแล',
          style: TextStyle(
            fontFamily: 'Sarabun',
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.all(16.r),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.person,
                    color: AppColors.textPrimary,
                    size: 24.sp,
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    'บทบาทของคุณ',
                    style: TextStyle(
                      fontFamily: 'Sarabun',
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  _buildRoleChip('ผู้ใช้งาน', AppColors.primaryBlue),
                  if (isCaregiver) ...[
                    SizedBox(width: 8.w),
                    _buildRoleChip('ผู้ดูแล', const Color(0xFF4CAF50)),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoleChip(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Sarabun',
          fontSize: 16.sp,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }
}
