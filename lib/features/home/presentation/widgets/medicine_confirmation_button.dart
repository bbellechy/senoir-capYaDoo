import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';

enum MedicineConfirmationStatus { pending, taken, overdue, taken_late }

class MedicineConfirmationButton extends StatelessWidget {
  final MedicineConfirmationStatus status;
  final VoidCallback? onConfirm;
  final String pendingText;

  const MedicineConfirmationButton({
    super.key,
    required this.status,
    this.onConfirm,
    this.pendingText = 'ยืนยันการทาน',
  });

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case MedicineConfirmationStatus.pending:
        if (pendingText == 'รอทาน') {
          final waitingPill = Container(
            height: 40.h,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              color: AppColors.warning,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.access_time, color: Colors.white, size: 18.sp),
                SizedBox(width: 6.w),
                Text(
                  'รอทาน',
                  style: TextStyle(
                    fontFamily: 'Sarabun',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          );

          if (onConfirm == null) {
            return waitingPill;
          }

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onConfirm,
              borderRadius: BorderRadius.circular(20.r),
              child: waitingPill,
            ),
          );
        }

        return SizedBox(
          height: 40.h,
          child: ElevatedButton(
            onPressed: onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: AppColors.whitelist,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              elevation: 0,
            ),
            child: Text(
              pendingText,
              style: TextStyle(
                fontFamily: 'Sarabun',
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );

      case MedicineConfirmationStatus.taken:
        return Container(
          height: 40.h,
          padding: EdgeInsets.symmetric(horizontal: 18.w),
          decoration: BoxDecoration(
            color: AppColors.success,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 18.sp,
              ),
              SizedBox(width: 6.w),
              Text(
                'ทานแล้ว',
                style: TextStyle(
                  fontFamily: 'Sarabun',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );

      case MedicineConfirmationStatus.overdue:
        final overduePill = Container(
          height: 40.h,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            color: AppColors.red,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Center(
            child: Text(
              'เกินกำหนด',
              style: TextStyle(
                fontFamily: 'Sarabun',
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        );

        if (onConfirm == null) {
          return overduePill;
        }

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onConfirm,
            borderRadius: BorderRadius.circular(12.r),
            child: overduePill,
          ),
        );

      case MedicineConfirmationStatus.taken_late:
        return Container(
          height: 40.h,
          padding: EdgeInsets.symmetric(horizontal: 18.w),
          decoration: BoxDecoration(
            color: AppColors.noonIcon,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 18.sp),
              SizedBox(width: 6.w),
              Text(
                'ทานล่าช้า',
                style: TextStyle(
                  fontFamily: 'Sarabun',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
    }
  }
}
