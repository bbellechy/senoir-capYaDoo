import 'package:flutter/material.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:capyadoo/core/routing/app_router.dart';
import 'package:capyadoo/core/widgets/symptom_list_card.dart';
import 'package:capyadoo/core/services/symptom_service.dart';
import 'package:capyadoo/core/services/auth_service.dart';
import 'package:capyadoo/core/model/symptom_record.dart';
import 'package:intl/intl.dart';

class SymptomListPage extends StatefulWidget {
  const SymptomListPage({super.key});

  @override
  State<SymptomListPage> createState() => _SymptomListPageState();
}

class _SymptomListPageState extends State<SymptomListPage> {
  List<SymptomRecord> _symptoms = [];
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
        final data = await SymptomService.getUserSymptoms(profile.id);
        if (mounted) {
          setState(() {
            _symptoms = data;
          });
        }
      }
    } catch (e) {
      print('Error loading symptoms: $e');
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
            height: 160,
            decoration: const BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  Positioned(
                    right: -50,
                    top: -50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -30,
                    bottom: -30,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ),
                  Padding(
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
                ],
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
                  onPressed: () async {
                    final result = await Navigator.pushNamed(
                      context,
                      AppRouter.addSymptomRoute,
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

          // Symptom list or empty state
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _symptoms.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _symptoms.length,
                    itemBuilder: (context, index) {
                      final symptom = _symptoms[index];
                      String timeStr =
                          'บันทึกเมื่อ ${symptom.time.substring(0, symptom.time.length >= 5 ? 5 : symptom.time.length)} น.';
                      if (symptom.date.isNotEmpty) {
                        try {
                          final dt = DateTime.parse(
                            '${symptom.date} ${symptom.time}',
                          );
                          timeStr =
                              'บันทึกเมื่อ ${DateFormat('dd/MM/yyyy HH:mm').format(dt)} น.';
                        } catch (_) {}
                      }

                      final level = symptom.severityLevel.clamp(1, 10);

                      return SymptomListCard(
                        level: level,
                        title: (symptom.symptom?.trim().isNotEmpty ?? false)
                            ? symptom.symptom!
                            : (symptom.medicationName.trim().isNotEmpty
                                  ? symptom.medicationName
                                  : 'ไม่ระบุอาการ'),
                        description: symptom.medicationName,
                        dateTime: timeStr,
                        onEdit: () async {
                          final result = await Navigator.pushNamed(
                            context,
                            AppRouter.addSymptomRoute,
                            arguments: symptom,
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
                                'คุณต้องการลบบันทึกอาการนี้ใช่หรือไม่?',
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

                          if (confirm == true && symptom.id != null) {
                            final success = await SymptomService.deleteSymptom(
                              symptom.id!,
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
