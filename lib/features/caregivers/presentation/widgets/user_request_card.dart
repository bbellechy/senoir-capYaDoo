import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';

/// การ์ดแสดงคำขอหรือการ้องของผู้ใช้งาน (สำหรับผู้ดูแล)
class UserRequestCard extends StatelessWidget {
  final String name;
  final String username;
  final bool isPending;
  final VoidCallback? onCancel;

  const UserRequestCard({
    super.key,
    required this.name,
    required this.username,
    this.isPending = false,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.whitelist,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.noonBorder, width: 1.5.w),
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
              color: AppColors.noon,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              color: AppColors.noonIcon,
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Sarabun',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Sarabun',
                    fontSize: 16.sp,
                    color: AppColors.textSub,
                  ),
                ),
                if (isPending) ...[
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14.sp,
                        color: AppColors.noonIcon,
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          'รอการยอมรับจากผู้ใช้งาน...',
                          style: TextStyle(
                            fontFamily: 'Sarabun',
                            fontSize: 14.sp,
                            color: AppColors.noonIcon,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // ปุ่ม
          if (isPending && onCancel != null) SizedBox(width: 8.w),
          if (isPending && onCancel != null)
            SizedBox(
              width: 80.w,
              height: 36.h,
              child: OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.blueEmpty,
                  foregroundColor: AppColors.textSub,
                  side: const BorderSide(color: AppColors.blueBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.close, size: 16.sp, color: AppColors.textSub),
                    SizedBox(width: 4.w),
                    Text(
                      'ยกเลิก',
                      style: TextStyle(
                        fontFamily: 'Sarabun',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
