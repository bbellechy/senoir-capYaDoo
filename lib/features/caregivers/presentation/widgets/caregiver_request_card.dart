import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';

/// การ์ดแสดงคำขอจากผู้ดูแล
class CaregiverRequestCard extends StatelessWidget {
  final String name;
  final String username;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const CaregiverRequestCard({
    super.key,
    required this.name,
    required this.username,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFFFA726), width: 1.5.w),
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
              color: const Color(0xFFFFA726).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person, color: const Color(0xFFFFA726), size: 28.sp),
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
                SizedBox(height: 4.h),
                Text(
                  'ขอเข้าถึงข้อมูลของคุณ',
                  style: TextStyle(
                    fontFamily: 'Sarabun',
                    fontSize: 14.sp,
                    color: AppColors.noonIcon,
                  ),
                ),
              ],
            ),
          ),

          // ปุ่ม
          Column(
            children: [
              SizedBox(
                width: 80.w,
                height: 36.h,
                child: ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    padding: EdgeInsets.zero,
                    elevation: 0,
                  ),
                  child: Text(
                    'ยอมรับ',
                    style: TextStyle(
                      fontFamily: 'Sarabun',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              SizedBox(
                width: 80.w,
                height: 36.h,
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: Text(
                    'ปฏิเสธ',
                    style: TextStyle(
                      fontFamily: 'Sarabun',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
