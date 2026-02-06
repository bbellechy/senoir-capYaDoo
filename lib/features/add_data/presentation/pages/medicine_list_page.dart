import 'package:flutter/material.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:capyadoo/core/routing/app_router.dart';
import 'package:capyadoo/core/widgets/medicine_list_card.dart';
import 'package:capyadoo/core/services/medication_service.dart';
import 'package:capyadoo/core/services/auth_service.dart';
import 'package:capyadoo/core/model/user_medication.dart';

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
                      final med = _medicines[index];
                      String mealTimingTxt = med.intakeTiming == 'BEFORE_MEAL'
                          ? 'ก่อนอาหาร'
                          : med.intakeTiming == 'AFTER_MEAL'
                          ? 'หลังอาหาร'
                          : 'ทานทันที';

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
                              title: const Text('ยืนยันการลบ'),
                              content: const Text(
                                'คุณต้องการลบข้อมูลยานี้ใช่หรือไม่?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('ยกเลิก'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text(
                                    'ลบ',
                                    style: TextStyle(color: Colors.red),
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
