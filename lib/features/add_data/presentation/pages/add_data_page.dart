import 'dart:io';
import 'package:flutter/material.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:capyadoo/core/routing/app_router.dart';
import 'package:capyadoo/core/widgets/medicine_list_card.dart';
import 'package:capyadoo/core/widgets/symptom_list_card.dart';
import 'package:capyadoo/core/services/medication_service.dart';
import 'package:capyadoo/core/services/symptom_service.dart';
import 'package:capyadoo/core/services/auth_service.dart';
import 'package:capyadoo/core/model/user_medication.dart';
import 'package:capyadoo/core/model/symptom_record.dart';
import 'add_medicine_page.dart';
import 'add_symptom_page.dart';

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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text('คุณตต้องการลบข้อมูลยานี้ใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await MedicationService.deleteMedication(id);
      if (success && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ลบข้อมูลยาสำเร็จ')));
        _loadData();
      }
    }
  }

  Future<void> _deleteSymptom(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text('คุณต้องการลบบันทึกอาการนี้ใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await SymptomService.deleteSymptom(id);
      if (success && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ลบบันทึกอาการสำเร็จ')));
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
            height: 175,
            decoration: const BoxDecoration(color: AppColors.primaryBlue),
            child: SafeArea(
              bottom: false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Top bar with back button and title
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 30,
                      right: 30,
                      bottom: 20,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _headerTitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Sarabun',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tabs
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      height: 40,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white,
                        dividerColor: Colors.transparent,
                        indicatorSize: TabBarIndicatorSize.label,
                        indicator: const UnderlineTabIndicator(
                          borderSide: BorderSide(color: Colors.white, width: 3),
                          insets: EdgeInsets.zero,
                        ),
                        labelStyle: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Sarabun',
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Sarabun',
                        ),
                        tabs: const [
                          Tab(text: 'ข้อมูลยา'),
                          Tab(text: 'บันทึกอาการ'),
                        ],
                      ),
                    ),
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
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'รายการยาทั้งหมด',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
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
                  children: const [
                    Text(
                      'เพิ่มข้อมูล',
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.add_circle,
                      color: AppColors.primaryBlue,
                      size: 24,
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
                  padding: const EdgeInsets.symmetric(horizontal: 24),
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
    return Center(
      child: Container(
        width: 380,
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.whitelist,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.blueBorder, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.medication, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'ยังไม่มีรายการยา',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textSub,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'เพิ่มยาเพื่อเริ่มต้นใช้งาน',
              style: TextStyle(fontSize: 14, color: AppColors.textSub),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSymptomTab() {
    return Column(
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'บันทึกอาการทั้งหมด',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
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
                  children: const [
                    Text(
                      'เพิ่มข้อมูล',
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.add_circle,
                      color: AppColors.primaryBlue,
                      size: 24,
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
                  padding: const EdgeInsets.symmetric(horizontal: 24),
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
    return Center(
      child: Container(
        width: 380,
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.whitelist,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.blueBorder, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'ยังไม่มีบันทึกอาการ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textSub,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'เริ่มบันทึกอาการเพื่อติดตามสุขภาพ',
              style: TextStyle(fontSize: 14, color: AppColors.textSub),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMealTiming(String? timing) {
    switch (timing) {
      case 'BEFORE_MEAL':
        return 'ก่อนอาหาร';
      case 'AFTER_MEAL':
        return 'หลังอาหาร';
      case 'WITH_MEAL':
        return 'ทานทันที';
      default:
        return timing ?? '-';
    }
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
