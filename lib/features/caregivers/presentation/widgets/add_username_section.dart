import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:capyadoo/core/widgets/speech_to_text_field.dart';

/// ส่วนเพิ่มผู้ใช้งาน (สำหรับผู้ดูแล)
class AddUserSection extends StatelessWidget {
  final TextEditingController controller;
  final Future<void> Function() onSearch;

  const AddUserSection({
    super.key,
    required this.controller,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                Icons.person_add,
                color: AppColors.primaryBlue,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'เพิ่มผู้ใช้งานที่ต้องการดูแล',
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
          Text(
            'Username ของผู้ใช้งานที่ต้องการดูแล',
            style: TextStyle(
              fontFamily: 'Sarabun',
              fontSize: 20.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50.h,
                  child: SpeechToTextField(
                    controller: controller,
                    onSearch: onSearch,
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: 'กรอก Username ของผู้ใช้งาน',
                        hintStyle: const TextStyle(
                          fontFamily: 'Sarabun',
                          color: AppColors.textSub,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: const BorderSide(
                            color: AppColors.blueBorder,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: const BorderSide(
                            color: AppColors.blueBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: BorderSide(
                            color: AppColors.primaryBlue,
                            width: 2.w,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                      ),
                      style: TextStyle(
                        fontFamily: 'Sarabun',
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              SizedBox(
                width: 100.w,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: () => onSearch(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    elevation: 0,
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search, size: 16.sp, color: Colors.white),
                      SizedBox(width: 4.w),
                      Text(
                        'ค้นหา',
                        style: TextStyle(
                          fontFamily: 'Sarabun',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
