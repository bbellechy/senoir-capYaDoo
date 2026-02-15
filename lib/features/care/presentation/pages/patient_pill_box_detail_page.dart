import 'dart:io';
import 'package:flutter/material.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:capyadoo/core/config/api_config.dart';
import 'package:capyadoo/core/model/medication_box.dart';
import 'package:capyadoo/core/model/care_models.dart';
import 'package:capyadoo/core/services/pill_box_service.dart';
import 'package:capyadoo/core/widgets/app_nav_bar.dart';
import 'package:capyadoo/core/services/page_navigation_service.dart';

class PatientPillBoxDetailPage extends StatefulWidget {
  final MedicationBox box;
  final Patient patient;

  const PatientPillBoxDetailPage({
    super.key,
    required this.box,
    required this.patient,
  });

  @override
  State<PatientPillBoxDetailPage> createState() =>
      _PatientPillBoxDetailPageState();
}

class _PatientPillBoxDetailPageState extends State<PatientPillBoxDetailPage> {
  List<Map<String, dynamic>> _dailyMeds = [];
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  final PillBoxService _pillBoxService = PillBoxService();

  @override
  void initState() {
    super.initState();
    _loadMedications();
  }

  Future<void> _loadMedications() async {
    setState(() => _isLoading = true);
    try {
      if (widget.box.id == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final dailyMeds = await _pillBoxService.getDailyMedicationsForBox(
        widget.box.id!,
        _selectedDate,
        userId: widget.patient.patientId,
      );
      if (mounted) {
        setState(() {
          _dailyMeds = dailyMeds;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      appBar: AppBar(
        title: Text(widget.box.name),
        backgroundColor: AppColors.success,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildBoxHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Row(
              children: [
                const Icon(
                  Icons.medication,
                  color: AppColors.success,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  'รายการยาในกล่อง (${_groupedMedications.length})',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildMedicationList(),
          ),
        ],
      ),
      bottomNavigationBar: AppNavBar(currentIndex: 0, onTap: _onNavBarTap),
    );
  }

  void _onNavBarTap(int index) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    PageNavigationService().setIndex(index);
  }

  Widget _buildBoxHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.success,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              image: _resolveImagePath(widget.box.imagePath) != null
                  ? DecorationImage(
                      image:
                          _resolveImagePath(
                            widget.box.imagePath,
                          )!.startsWith('http')
                          ? NetworkImage(
                                  _resolveImagePath(widget.box.imagePath)!,
                                )
                                as ImageProvider
                          : FileImage(
                              File(_resolveImagePath(widget.box.imagePath)!),
                            ),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _resolveImagePath(widget.box.imagePath) == null
                ? const Icon(Icons.inventory_2, size: 40, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.box.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.box.description ?? 'ไม่มีรายละเอียด',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// รวมรายการจาก API เป็นกลุ่มตามชื่อยา (ผู้ดูแลไม่แสดงเวลา แสดงแค่ก่อนอาหาร/หลังอาหาร)
  List<Map<String, dynamic>> get _groupedMedications {
    final Map<String, Map<String, dynamic>> grouped = {};
    for (final med in _dailyMeds) {
      final medicationObj = med['medication'] as Map<String, dynamic>?;
      final name =
          medicationObj?['name'] as String? ??
          med['medicationName'] as String? ??
          'ไม่ระบุชื่อ';
      final status = (med['status'] as String? ?? 'PENDING').toUpperCase();
      final dosage = med['dosage'];
      final unit = med['unit'] as String? ?? 'เม็ด';
      final imagePath = medicationObj?['imagePath'] as String?;

      grouped.putIfAbsent(name, () {
        return {
          'medicationName': name,
          'dosage': dosage,
          'unit': unit,
          'statuses': <String>[],
          'imagePath': imagePath,
        };
      });
      final entry = grouped[name]!;
      (entry['statuses'] as List<String>).add(status);
    }
    return grouped.values.toList();
  }

  String _mealTimingLabel(String? intakeTiming) {
    if (intakeTiming == null || intakeTiming.isEmpty) return '';
    switch (intakeTiming.toUpperCase()) {
      case 'BEFORE_MEAL':
        return 'ก่อนอาหาร';
      case 'AFTER_MEAL':
        return 'หลังอาหาร';
      default:
        return '';
    }
  }

  Widget _buildMedicationList() {
    if (_groupedMedications.isEmpty) {
      return Center(
        child: Text(
          _dailyMeds.isEmpty && !_isLoading
              ? 'ไม่พบข้อมูลยาในกล่องนี้'
              : 'กำลังโหลด...',
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: _groupedMedications.length,
      itemBuilder: (context, index) {
        final g = _groupedMedications[index];
        final medName = g['medicationName'] as String;
        final dosage = g['dosage'];
        final unit = g['unit'] as String? ?? 'เม็ด';
        final resolvedPath = _resolveImagePath(g['imagePath'] as String?);
        final dosageText = dosage != null ? '$dosage $unit' : '1 $unit';
        final mealTiming = _mealTimingLabel(widget.box.intakeTiming);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                      image: resolvedPath != null && resolvedPath.isNotEmpty
                          ? DecorationImage(
                              image: resolvedPath.startsWith('http')
                                  ? NetworkImage(resolvedPath) as ImageProvider
                                  : FileImage(File(resolvedPath)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: resolvedPath == null || resolvedPath.isEmpty
                        ? const Icon(Icons.medication, color: AppColors.success)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$medName ($dosageText)',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (mealTiming.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            mealTiming,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String? _resolveImagePath(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;

    // Check if it's an absolute local path
    if (path.contains(':') ||
        path.startsWith('/') ||
        path.contains('Documents/') ||
        path.contains('data/user/')) {
      return path;
    }

    if (path.startsWith('uploads/')) {
      return '${ApiConfig.baseUrl}/$path';
    }

    return '${ApiConfig.baseUrl}/$path';
  }
}
