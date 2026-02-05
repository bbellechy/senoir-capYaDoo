import 'package:flutter/material.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:capyadoo/core/routing/app_router.dart';
import 'package:capyadoo/features/add_data/presentation/widgets/symptom_list_card.dart';

class SymptomListPage extends StatefulWidget {
  const SymptomListPage({super.key});

  @override
  State<SymptomListPage> createState() => _SymptomListPageState();
}

class _SymptomListPageState extends State<SymptomListPage> {
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
                        'บันทึกอาการ',
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
                ? _buildEmptyState()
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
                          Navigator.pushNamed(
                            context,
                            AppRouter.addSymptomRoute,
                          );
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
