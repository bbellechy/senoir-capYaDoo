import 'dart:io';
import 'package:flutter/material.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:capyadoo/core/config/api_config.dart';
import 'package:capyadoo/core/model/user_medication.dart';
import 'package:capyadoo/core/model/medication_box.dart';
import 'package:capyadoo/core/model/care_models.dart';
import 'package:capyadoo/core/services/care_service.dart';
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
  List<UserMedication> _medications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMedications();
  }

  Future<void> _loadMedications() async {
    setState(() => _isLoading = true);
    try {
      // We fetch all medications for the patient and then filter by those in the box
      final allMeds = await CareService.getPatientMedications(
        widget.patient.patientId,
      );
      if (mounted) {
        setState(() {
          _medications = allMeds
              .where((m) => widget.box.medicationIds.contains(m.id))
              .toList();
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
                  'รายการยาในกล่อง (${_medications.length})',
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
            ),
            child: const Icon(Icons.inventory_2, size: 40, color: Colors.white),
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

  Widget _buildMedicationList() {
    if (_medications.isEmpty) {
      return Center(
        child: Text(
          'ไม่พบข้อมูลยาในกล่องนี้',
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: _medications.length,
      itemBuilder: (context, index) {
        final med = _medications[index];
        final resolvedPath = _resolveImagePath(med.imagePath);
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
          child: Row(
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
                      med.displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${med.dosage ?? "-"} ${med.unit ?? "-"}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
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
