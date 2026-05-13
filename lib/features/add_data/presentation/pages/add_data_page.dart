import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:capyadoo/core/routing/app_router.dart';
import 'package:capyadoo/core/widgets/medicine_list_card.dart';
import 'package:capyadoo/core/widgets/symptom_list_card.dart';
import 'package:capyadoo/core/widgets/delete_dialog.dart';
import 'package:capyadoo/core/services/medication_service.dart';
import 'package:capyadoo/core/services/symptom_service.dart';
import 'package:capyadoo/core/services/auth_service.dart';
import 'package:capyadoo/core/model/user_medication.dart';
import 'package:capyadoo/core/model/symptom_record.dart';
import 'package:capyadoo/core/utils/intake_timing_label.dart';
import 'add_medicine_page.dart';
import 'add_symptom_page.dart';
import 'package:capyadoo/core/widgets/app_empty_card.dart';

class AddDataPage extends StatefulWidget {
  const AddDataPage({super.key});

  @override
  State<AddDataPage> createState() => _AddDataPageState();
}

class _AddDataPageState extends State<AddDataPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<UserMedication> _medicines = [];
  List<SymptomRecord> _symptoms = [];
  bool _isLoading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild to update header text
    });
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final profile = await AuthService.getProfile();
      if (profile != null) {
        _userId = profile.id;
        final medicines = await MedicationService.getUserMedications(_userId!);
        final symptoms = await SymptomService.getUserSymptoms(_userId!);
        setState(() {
          _medicines = medicines;
          _symptoms = symptoms;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteMedicine(String id) async {
    final confirmed = await showDeleteDialog(
      context,
      title: 'ยืนยันการลบ',
      message:
          'คุณแน่ใจหรือไม่ว่าต้องการลบข้อมูลนี้ ?\nการดำเนินการนี้ไม่สามารถย้อนกลับได้',
    );

    if (confirmed == true) {
      final success = await MedicationService.deleteMedication(id);
      if (success && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(
              'ลบข้อมูลยาสำเร็จ',
              style: TextStyle(fontFamily: 'Sarabun', fontSize: 14.sp),
            ),
          ),
        );
        _loadData();
      }
    }
  }

  Future<void> _deleteSymptom(String id) async {
    final confirmed = await showDeleteDialog(
      context,
      title: 'ยืนยันการลบ',
      message:
          'คุณแน่ใจหรือไม่ว่าต้องการลบข้อมูลนี้ ?\nการดำเนินการนี้ไม่สามารถย้อนกลับได้',
    );

    if (confirmed == true) {
      final success = await SymptomService.deleteSymptom(id);
      if (success && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(
              'ลบบันทึกอาการสำเร็จ',
              style: TextStyle(fontFamily: 'Sarabun', fontSize: 14.sp),
            ),
          ),
        );
        _loadData();
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _headerTitle {
    return _tabController.index == 0 ? 'รายการยา' : 'บันทึกอาการ';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header with tabs
          Container(
            height: 175.h,
            width: double.infinity,
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
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        child: Text(
                          _headerTitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36.sp,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Sarabun',
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: TabBar(
                          controller: _tabController,
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.white70,
                          dividerColor: Colors.transparent,
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.white, width: 2.w),
                            ),
                          ),
                          labelStyle: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Sarabun',
                          ),
                          unselectedLabelStyle: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'Sarabun',
                          ),
                          tabs: const [
                            Tab(text: 'เพิ่มข้อมูลยา'),
                            Tab(text: 'บันทึกอาการ'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildMedicineTab(), _buildSymptomTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineTab() {
    return Column(
      children: [
        // Section header
        Padding(
          padding: EdgeInsets.all(24.r),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'รายการยาทั้งหมด',
                style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w600),
              ),
              TextButton(
                onPressed: () async {
                  final result = await Navigator.pushNamed(
                    context,
                    AppRouter.addMedicineRoute,
                  );
                  if (result == true) _loadData();
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'เพิ่มข้อมูล',
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Icon(
                      Icons.add_circle,
                      color: AppColors.primaryBlue,
                      size: 24.sp,
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
                    final medicine = _medicines[index];
                    return MedicineListCard(
                      imagePath: medicine.imagePath,
                      name: medicine.name,
                      amount: '${medicine.dosage} ${medicine.unit}',
                      frequency: medicine.timesPerDay ?? 0,
                      mealTiming: _formatMealTiming(medicine.intakeTiming),
                      expiryDate: medicine.expiryDate?.split('T')[0] ?? '-',
                      mealTimes:
                          medicine.intakePeriods
                              ?.map((p) => _formatIntakePeriod(p))
                              .toList() ??
                          [],
                      onEdit: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AddMedicinePage(medicationId: medicine.id),
                          ),
                        );
                        if (result == true) _loadData();
                      },
                      onDelete: () => _deleteMedicine(medicine.id!),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
      child: Align(
        alignment: Alignment.topCenter,
        child: AppEmptyCard(
          title: 'ยังไม่มีรายการยา',
          subtitle: 'เพิ่มยาเพื่อเริ่มต้นใช้งาน',
          iconColor: AppColors.textSublest,
          borderColor: AppColors.blueBorder,
          borderRadius: 10.r,
          borderWidth: 2.w,
        ),
      ),
    );
  }

  Widget _buildSymptomTab() {
    return Column(
      children: [
        // Section header
        Padding(
          padding: EdgeInsets.all(24.r),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'บันทึกอาการทั้งหมด',
                style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w600),
              ),
              TextButton(
                onPressed: () async {
                  final result = await Navigator.pushNamed(
                    context,
                    AppRouter.addSymptomRoute,
                  );
                  if (result == true) _loadData();
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'เพิ่มข้อมูล',
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Icon(
                      Icons.add_circle,
                      color: AppColors.primaryBlue,
                      size: 24.sp,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Symptom list or empty state
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _symptoms.isEmpty
              ? _buildEmptySymptomState()
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  itemCount: _symptoms.length,
                  itemBuilder: (context, index) {
                    final symptom = _symptoms[index];
                    return SymptomListCard(
                      level: symptom.severityLevel,
                      title: symptom.medicationName,
                      description: symptom.symptom ?? '',
                      dateTime: '${symptom.date} ${symptom.time}',
                      onEdit: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AddSymptomPage(symptomId: symptom.id),
                          ),
                        );
                        if (result == true) _loadData();
                      },
                      onDelete: () => _deleteSymptom(symptom.id!),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptySymptomState() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
      child: Align(
        alignment: Alignment.topCenter,
        child: AppEmptyCard(
          icon: Icons.assignment_outlined,
          title: 'ยังไม่มีบันทึกอาการ',
          subtitle: 'เริ่มบันทึกอาการเพื่อติดตามสุขภาพ',
          iconColor: AppColors.textSublest,
          borderColor: AppColors.blueBorder,
          borderRadius: 10.r,
          borderWidth: 2.w,
        ),
      ),
    );
  }

  String _formatMealTiming(String? timing) {
    return toThaiIntakeTimingLabel(timing) ?? timing ?? '-';
  }

  String _formatIntakePeriod(String period) {
    switch (period) {
      case 'MORNING':
        return 'เช้า';
      case 'NOON':
        return 'กลางวัน';
      case 'EVENING':
        return 'เย็น';
      case 'BEDTIME':
        return 'ก่อนนอน';
      default:
        return period;
    }
  }
}
