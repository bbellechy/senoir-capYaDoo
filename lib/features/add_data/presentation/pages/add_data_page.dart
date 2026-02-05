import 'dart:io';
import 'package:flutter/material.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:capyadoo/core/routing/app_router.dart';
import 'package:capyadoo/features/add_data/presentation/widgets/medicine_list_card.dart';
import 'package:capyadoo/features/add_data/presentation/widgets/symptom_list_card.dart';

class AddDataPage extends StatefulWidget {
  const AddDataPage({super.key});

  @override
  State<AddDataPage> createState() => _AddDataPageState();
}

class _AddDataPageState extends State<AddDataPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Sample medicine data
  final List<Map<String, dynamic>> _medicines = [
    {
      'image': null,
      'name': 'แก้อักเสบ',
      'amount': '1 เม็ด',
      'frequency': 2,
      'mealTiming': 'หลังอาหาร',
      'expiryDate': '30/10/2568',
      'mealTimes': ['เช้า', 'เย็น', 'ก่อนนอน'],
    },
    {
      'image': null,
      'name': 'ยาลดน้ำมูก',
      'amount': '1 เม็ด',
      'frequency': 3,
      'mealTiming': 'หลังอาหาร',
      'expiryDate': '30/10/2568',
      'mealTimes': ['เช้า', 'กลางวัน', 'เย็น'],
    },
    {
      'image': null,
      'name': 'ยาลดน้ำมูก',
      'amount': '1 เม็ด',
      'frequency': 3,
      'mealTiming': 'หลังอาหาร',
      'expiryDate': '30/10/2568',
      'mealTimes': ['เช้า', 'กลางวัน', 'เย็น'],
    },
    {
      'image': null,
      'name': 'แก้อักเสบ',
      'amount': '1 เม็ด',
      'frequency': 2,
      'mealTiming': 'หลังอาหาร',
      'expiryDate': '30/10/2568',
      'mealTimes': ['เช้า', 'เย็น'],
    },
    {
      'image': null,
      'name': 'ยาลดน้ำมูก',
      'amount': '1 เม็ด',
      'frequency': 3,
      'mealTiming': 'หลังอาหาร',
      'expiryDate': '30/10/2568',
      'mealTimes': ['เช้า', 'กลางวัน', 'เย็น'],
    },
  ];

  // Sample symptom data
  final List<Map<String, dynamic>> _symptoms = [
    {
      'level': 5,
      'title': 'แก้อักเสบ',
      'description': 'ปวดตรงที่ถอนฟัน',
      'dateTime': 'บันทึกเมื่อ 15:11 น.',
    },
    {
      'level': 4,
      'title': 'ยาลดน้ำมูก',
      'description': 'มีน้ำมูกเล็กน้อย',
      'dateTime': 'บันทึกเมื่อ 19:22 น.',
    },
    {
      'level': 9,
      'title': 'ยาคลายกล้ามเนื้อ',
      'description': 'ปวดกล้ามเนื้อมาก',
      'dateTime': 'บันทึกเมื่อ 14:30 น.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild to update header text
    });
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
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            _headerTitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48), // Balance the back button
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
                onPressed: () {
                  Navigator.pushNamed(context, AppRouter.addMedicineRoute);
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
          child: _medicines.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _medicines.length,
                  itemBuilder: (context, index) {
                    final medicine = _medicines[index];
                    return MedicineListCard(
                      image: medicine['image'],
                      name: medicine['name'],
                      amount: medicine['amount'],
                      frequency: medicine['frequency'],
                      mealTiming: medicine['mealTiming'],
                      expiryDate: medicine['expiryDate'],
                      mealTimes: List<String>.from(medicine['mealTimes']),
                      onEdit: () {
                        Navigator.pushNamed(
                          context,
                          AppRouter.addMedicineRoute,
                        );
                      },
                      onDelete: () {
                        setState(() {
                          _medicines.removeAt(index);
                        });
                      },
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
                onPressed: () {
                  Navigator.pushNamed(context, AppRouter.addSymptomRoute);
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
          child: _symptoms.isEmpty
              ? _buildEmptySymptomState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _symptoms.length,
                  itemBuilder: (context, index) {
                    final symptom = _symptoms[index];
                    return SymptomListCard(
                      level: symptom['level'],
                      title: symptom['title'],
                      description: symptom['description'],
                      dateTime: symptom['dateTime'],
                      onEdit: () {
                        Navigator.pushNamed(context, AppRouter.addSymptomRoute);
                      },
                      onDelete: () {
                        setState(() {
                          _symptoms.removeAt(index);
                        });
                      },
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
}
