import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:capyadoo/core/constants/app_colors.dart';

Future<bool> showDeleteDialog(
  BuildContext context, {
  required String title,
  required String message,
  String cancelText = 'ยกเลิก',
  String confirmText = 'ลบ',
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        elevation: 0,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        child: SizedBox(
          width: 320.w,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 20.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning_rounded,
                      color: AppColors.error,
                      size: 30.sp,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          fontFamily: 'Sarabun',
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 18.h),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: AppColors.textSub,
                      height: 1.4,
                      fontFamily: 'Sarabun',
                    ),
                  ),
                ),
                SizedBox(height: 22.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: 96.w,
                      height: 40.h,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppColors.blueEmpty,
                          foregroundColor: AppColors.textSub,
                          side: const BorderSide(color: AppColors.blueBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: Text(
                          cancelText,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Sarabun',
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    SizedBox(
                      width: 72.w,
                      height: 40.h,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: Text(
                          confirmText,
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Sarabun',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  return result ?? false;
}
