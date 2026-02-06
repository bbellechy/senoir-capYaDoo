import 'dart:io';
import 'package:flutter/material.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:capyadoo/core/config/api_config.dart';
import 'package:capyadoo/core/model/daily_intake.dart';
import 'package:capyadoo/core/model/care_models.dart';
import 'package:capyadoo/core/services/care_service.dart';
import 'package:capyadoo/features/care/presentation/pages/patient_pill_box_list_page.dart';
import 'package:intl/intl.dart';

class PatientDetailPage extends StatefulWidget {
  final Patient patient;
  const PatientDetailPage({super.key, required this.patient});

  @override
  State<PatientDetailPage> createState() => _PatientDetailPageState();
}

class _PatientDetailPageState extends State<PatientDetailPage> {
  DateTime _selectedDate = DateTime.now();
  List<DailyIntake> _schedule = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    setState(() => _isLoading = true);
    try {
      final data = await CareService.getPatientSchedule(
        widget.patient.patientId,
        _selectedDate,
      );
      if (mounted) {
        setState(() {
          _schedule = data;
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
      body: Stack(
        children: [
          Container(
            height: 300,
            decoration: const BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadSchedule,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildDatePicker(),
                    const SizedBox(height: 20),
                    _buildContentCard(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: const Icon(Icons.person, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ข้อมูลการทานยาของ',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  widget.patient.fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    final thaiDateFormat = DateFormat('EEEE, d MMMM yyyy', 'th_TH');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            thaiDateFormat.format(_selectedDate),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 14,
            itemBuilder: (context, index) {
              final date = DateTime.now()
                  .subtract(Duration(days: DateTime.now().weekday - 1))
                  .add(Duration(days: index));
              final isSelected =
                  DateFormat('yyyy-MM-dd').format(date) ==
                  DateFormat('yyyy-MM-dd').format(_selectedDate);

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedDate = date);
                  _loadSchedule();
                },
                child: Container(
                  width: 50,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        color: isSelected ? AppColors.success : Colors.white,
                        fontSize: 18,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContentCard() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          // Pills Box Button
          _buildPillBoxButton(),
          const SizedBox(height: 32),

          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else ...[
            _buildTimeSection(
              'เช้า',
              'morning',
              const Color(0xFFFFF9C4),
              const Color(0xFFFBC02D),
              Icons.wb_sunny_outlined,
            ),
            const SizedBox(height: 16),
            _buildTimeSection(
              'กลางวัน',
              'afternoon',
              const Color(0xFFFFE0B2),
              const Color(0xFFF57C00),
              Icons.wb_sunny,
            ),
            const SizedBox(height: 16),
            _buildTimeSection(
              'เย็น',
              'evening',
              const Color(0xFFE1F5FE),
              const Color(0xFF0288D1),
              Icons.cloud_outlined,
            ),
            const SizedBox(height: 16),
            _buildTimeSection(
              'ก่อนนอน',
              'night',
              const Color(0xFFEDE7F6),
              const Color(0xFF673AB7),
              Icons.nightlight_round_outlined,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPillBoxButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PatientPillBoxListPage(patient: widget.patient),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFE3F2FD),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                color: Color(0xFF2196F3),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'กล่องยาของผู้ป่วย',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSection(
    String title,
    String period,
    Color bgColor,
    Color iconColor,
    IconData icon,
  ) {
    final items = _getFilteredSchedule(period);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.4),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const Spacer(),
              Text(
                '${items.length} รายการ',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            Center(
              child: Text(
                'ไม่มีในรายการช่วงนี้',
                style: TextStyle(color: Colors.grey[400]),
              ),
            )
          else
            ...items.map((item) => _buildMedicationCard(item)).toList(),
        ],
      ),
    );
  }

  Widget _buildMedicationCard(DailyIntake item) {
    final bool isTaken = item.status == IntakeStatus.TAKEN;
    final resolvedPath = _resolveImagePath(item.imagePath);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
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
                ? Icon(
                    Icons.medication_outlined,
                    color: Colors.grey[400],
                    size: 24,
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.medicationName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${item.time.substring(0, 5)} น.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isTaken)
            const Chip(
              label: Text(
                'ทานแล้ว',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              backgroundColor: AppColors.success,
            )
          else
            Chip(
              label: Text(
                'ยังไม่ทาน',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              backgroundColor: Colors.grey[200],
            ),
        ],
      ),
    );
  }

  List<DailyIntake> _getFilteredSchedule(String period) {
    return _schedule.where((item) {
      final hour = int.parse(item.time.split(':')[0]);
      switch (period) {
        case 'morning':
          return hour >= 5 && hour < 11;
        case 'afternoon':
          return hour >= 11 && hour < 16;
        case 'evening':
          return hour >= 16 && hour < 21;
        case 'night':
          return hour >= 21 || hour < 5;
        default:
          return false;
      }
    }).toList();
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
