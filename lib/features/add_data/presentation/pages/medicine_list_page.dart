import 'dart:io';
import 'package:flutter/material.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:capyadoo/core/routing/app_router.dart';
import 'package:capyadoo/core/widgets/medicine_list_card.dart';

class MedicineListPage extends StatefulWidget {
  const MedicineListPage({super.key});

  @override
  State<MedicineListPage> createState() => _MedicineListPageState();
}

class _MedicineListPageState extends State<MedicineListPage> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          Container(
            height: 120,
            decoration: const BoxDecoration(color: AppColors.primaryBlue),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'รายการยา',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Sarabun',
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),
            ),
          ),

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
      ),
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
}
