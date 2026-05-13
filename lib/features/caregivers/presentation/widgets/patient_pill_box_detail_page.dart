import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:capyadoo/core/config/api_config.dart';
import 'package:capyadoo/core/model/medication_box.dart';
import 'package:capyadoo/core/model/care_models.dart';
import 'package:capyadoo/core/services/pill_box_service.dart';
import 'package:capyadoo/core/utils/intake_timing_label.dart';

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
      backgroundColor: AppColors.offwhite,
      body: Column(
        children: [
          _buildBoxHeader(),
          Padding(
            padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 12.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'รายการยาในกล่อง (${_groupedMedications.length})',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
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
    );
  }

  Widget _buildBoxHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 8.h, 24.w, 24.h),
      decoration: BoxDecoration(
        color: AppColors.success,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32.r),
          bottomRight: Radius.circular(32.r),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 88.w,
                    height: 88.h,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20.r),
                      image: _resolveImagePath(widget.box.imagePath) != null
                          ? DecorationImage(
                              image:
                                  _resolveImagePath(
                                    widget.box.imagePath,
                                  )!.startsWith('http')
                                  ? NetworkImage(
                                          _resolveImagePath(
                                            widget.box.imagePath,
                                          )!,
                                        )
                                        as ImageProvider
                                  : FileImage(
                                      File(
                                        _resolveImagePath(
                                          widget.box.imagePath,
                                        )!,
                                      ),
                                    ),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _resolveImagePath(widget.box.imagePath) == null
                        ? Icon(
                            Icons.inventory_2,
                            size: 44.sp,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.box.name,
                          style: TextStyle(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          widget.box.description ?? 'ไม่มีรายละเอียด',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
    final list = grouped.values.toList();
    list.sort((a, b) {
      final an = (a['medicationName'] as String? ?? '').trim().toLowerCase();
      final bn = (b['medicationName'] as String? ?? '').trim().toLowerCase();
      return an.compareTo(bn);
    });
    return list;
  }

  String _mealTimingLabel(String? intakeTiming) {
    return toThaiIntakeTimingLabel(intakeTiming) ?? '';
  }

  Widget _buildMedicationList() {
    if (_groupedMedications.isEmpty) {
      return Center(
        child: Text(
          _dailyMeds.isEmpty && !_isLoading
              ? 'ไม่พบข้อมูลยาในกล่องนี้'
              : 'กำลังโหลด...',
          style: TextStyle(color: Colors.grey[600], fontSize: 16.sp),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
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
          margin: EdgeInsets.only(bottom: 16.h),
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.blueBorder, width: 1.5.w),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10.r,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50.w,
                    height: 50.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12.r),
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
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$medName ($dosageText)',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (mealTiming.isNotEmpty) ...[
                          SizedBox(height: 4.h),
                          Text(
                            mealTiming,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13.sp,
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
