import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:capyadoo/core/routing/app_router.dart';
import 'package:capyadoo/core/widgets/medicine_list_card.dart';
import 'package:capyadoo/core/services/medication_service.dart';
import 'package:capyadoo/core/services/auth_service.dart';
import 'package:capyadoo/core/model/user_medication.dart';
import 'package:capyadoo/core/utils/intake_timing_label.dart';

class MedicineListPage extends StatefulWidget {
  const MedicineListPage({super.key});

  @override
  State<MedicineListPage> createState() => _MedicineListPageState();
}

class _MedicineListPageState extends State<MedicineListPage> {
  List<UserMedication> _medicines = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final profile = await AuthService.getProfile();
      if (profile != null) {
        final data = await MedicationService.getUserMedications(profile.id);
        if (mounted) {
          setState(() {
            _medicines = data;
          });
        }
      }
    } catch (e) {
      print('Error loading medicines: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          Container(
            height: 160.h,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32.r),
                bottomRight: Radius.circular(32.r),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  Positioned(
                    right: -50.w,
                    top: -50.h,
                    child: Container(
                      width: 200.w,
                      height: 200.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -30.w,
                    bottom: -30.h,
                    child: Container(
                      width: 140.w,
                      height: 140.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                            size: 24.sp,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            'รายการยา',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32.sp,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Sarabun',
                            ),
                          ),
                        ),
                        SizedBox(width: 48.w), // Balance the back button
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Section header
          Padding(
            padding: EdgeInsets.all(24.r),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'รายการยาทั้งหมด',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Sarabun',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final result = await Navigator.pushNamed(
                      context,
                      AppRouter.addMedicineRoute,
                    );
                    if (result == true) {
                      _loadData();
                    }
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'เพิ่มข้อมูล',
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Sarabun',
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Icon(
                        Icons.add_circle,
                        color: AppColors.primaryBlue,
                        size: 20.sp,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Medicine list or empty state
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _medicines.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    itemCount: _medicines.length,
                    itemBuilder: (context, index) {
                      final med = _medicines[index];
                      final mealTimingTxt =
                          toThaiIntakeTimingLabel(med.intakeTiming) ?? '-';

                      List<String> mealTimes = (med.intakePeriods ?? []).map((
                        t,
                      ) {
                        switch (t) {
                          case 'MORNING':
                            return 'เช้า';
                          case 'NOON':
                            return 'กลางวัน';
                          case 'EVENING':
                            return 'เย็น';
                          case 'BEDTIME':
                            return 'ก่อนนอน';
                          default:
                            return t;
                        }
                      }).toList();

                      return MedicineListCard(
                        imagePath: med.imagePath,
                        name: med.name,
                        amount: '${med.dosage ?? "-"} ${med.unit ?? "-"}',
                        frequency: med.timesPerDay ?? 0,
                        mealTiming: mealTimingTxt,
                        expiryDate: med.expiryDate ?? '-',
                        mealTimes: mealTimes,
                        onEdit: () async {
                          final result = await Navigator.pushNamed(
                            context,
                            AppRouter.addMedicineRoute,
                            arguments: med.id,
                          );
                          if (result == true) {
                            _loadData();
                          }
                        },
                        onDelete: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('ยืนยันการลบ', style: TextStyle(fontSize: 18.sp)),
                              content: Text(
                                'คุณต้องการลบข้อมูลยานี้ใช่หรือไม่?',
                                style: TextStyle(fontSize: 16.sp),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: Text('ยกเลิก', style: TextStyle(fontSize: 16.sp)),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text(
                                    'ลบ',
                                    style: TextStyle(color: Colors.red, fontSize: 16.sp),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            final success =
                                await MedicationService.deleteMedication(
                                  med.id!,
                                );
                            if (success) {
                              _loadData();
                            }
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        width: 380.w,
        margin: EdgeInsets.symmetric(horizontal: 24.w),
        padding: EdgeInsets.symmetric(vertical: 48.h, horizontal: 24.w),
        decoration: BoxDecoration(
          color: AppColors.whitelist,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.blueBorder, width: 1.w),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.medication, size: 80.sp, color: Colors.grey[400]),
            SizedBox(height: 16.h),
            Text(
              'ยังไม่มีรายการยา',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textSub,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'เพิ่มยาเพื่อเริ่มต้นใช้งาน',
              style: TextStyle(fontSize: 14.sp, color: AppColors.textSub),
            ),
          ],
        ),
      ),
    );
  }
}
