import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';

/// การ์ดแสดงรายชื่อผู้ใช้งาน (สำหรับผู้ดูแล)
class PatientCard extends StatelessWidget {
  final String name;
  final String username;
  final VoidCallback onViewData;
  final VoidCallback onDelete;

  const PatientCard({
    super.key,
    required this.name,
    required this.username,
    required this.onViewData,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
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
      child: Row(
        children: [
          // ไอคอนผู้ใช้
          Container(
            width: 48.w,
            height: 48.h,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              color: AppColors.primaryBlue,
              size: 28.sp,
            ),
          ),
          SizedBox(width: 12.w),

          // ข้อมูล
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontFamily: 'Sarabun',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  username,
                  style: TextStyle(
                    fontFamily: 'Sarabun',
                    fontSize: 16.sp,
                    color: AppColors.textSub,
                  ),
                ),
              ],
            ),
          ),

          // ปุ่มดูข้อมูล
          SizedBox(
            width: 90.w,
            height: 36.h,
            child: ElevatedButton(
              onPressed: onViewData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                padding: EdgeInsets.zero,
                elevation: 0,
              ),
              child: Text(
                'ดูข้อมูล',
                style: TextStyle(
                  fontFamily: 'Sarabun',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),

          // ปุ่มลบ
          IconButton(
            onPressed: onDelete,
            icon: Icon(
              Icons.delete_rounded,
              color: AppColors.error,
              size: 22.sp,
            ),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.error.withOpacity(0.1),
              fixedSize: Size(40.w, 40.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
