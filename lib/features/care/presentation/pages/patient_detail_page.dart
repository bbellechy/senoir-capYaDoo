import 'dart:io';
import 'package:flutter/material.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:capyadoo/core/config/api_config.dart';
import 'package:capyadoo/core/model/daily_intake.dart';
import 'package:capyadoo/core/model/care_models.dart';
import 'package:capyadoo/core/services/care_service.dart';
import 'package:capyadoo/core/services/pill_box_service.dart';
import 'package:capyadoo/core/model/medication_box.dart';
import 'package:capyadoo/features/care/presentation/pages/patient_pill_box_detail_page.dart';
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
  List<MedicationBox> _boxes = [];
  Map<String, List<Map<String, dynamic>>> _boxDailyMedications = {};
  final PillBoxService _pillBoxService = PillBoxService();
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
      await _loadBoxes();
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

  Future<void> _loadBoxes() async {
    try {
      final boxes = await CareService.getPatientMedicationBoxes(
        widget.patient.patientId,
      );
      if (mounted) {
        setState(() {
          _boxes = boxes;
        });
        // Load daily medications for each box
        // ใช้ patientId เป็น userId สำหรับ API call
        for (final box in boxes) {
          if (box.id != null) {
            final dailyMeds = await _pillBoxService.getDailyMedicationsForBox(
              box.id!,
              _selectedDate,
              userId: widget.patient.patientId,
            );
            if (mounted) {
              setState(() {
                _boxDailyMedications[box.id!] = dailyMeds;
              });
            }
          }
        }
      }
    } catch (e) {
      print('Error loading boxes: $e');
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

              Future<void> openCalendar() async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() {
                    _selectedDate = picked;
                  });
                  _loadSchedule();
                }
              }

              return GestureDetector(
                onTap: () async {
                  // index==0 เป็นปุ่มเปิดปฏิทิน (ไม่ใช่เลือกวัน)
                  if (index == 0) {
                    await openCalendar();
                    return;
                  }
                  setState(() => _selectedDate = date);
                  _loadSchedule();
                },
                child: Container(
                  width: 50,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.transparent,
                    shape: BoxShape.circle,
                    border: index == 0
                        ? Border.all(color: Colors.white.withOpacity(0.5))
                        : null,
                  ),
                  child: Center(
                    child: index == 0
                        ? const Icon(
                            Icons.calendar_today_outlined,
                            color: Colors.white,
                            size: 20,
                          )
                        : Text(
                            '${date.day}',
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.success
                                  : Colors.white,
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

  Widget _buildTimeSection(
    String title,
    String period,
    Color bgColor,
    Color iconColor,
    IconData icon,
  ) {
    final items = _getFilteredSchedule(period);
    // Get boxes for this period
    final periodMap = {
      'เช้า': 'MORNING',
      'กลางวัน': 'NOON',
      'เย็น': 'EVENING',
      'ก่อนนอน': 'BEDTIME',
      'morning': 'MORNING',
      'afternoon': 'NOON',
      'evening': 'EVENING',
      'night': 'BEDTIME',
    };
    final periodKey = periodMap[title] ?? periodMap[period] ?? '';
    final boxItems = _getBoxesForPeriod(periodKey);
    final totalCount = items.length + boxItems.length;

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
                '$totalCount รายการ',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (items.isEmpty && boxItems.isEmpty)
            Center(
              child: Text(
                'ไม่มีในรายการช่วงนี้',
                style: TextStyle(color: Colors.grey[400]),
              ),
            )
          else ...[
            ...items.map((item) => _buildMedicationCard(item)).toList(),
            ...boxItems
                .map(
                  (boxItem) => _buildBoxCard(
                    boxItem['box'] as MedicationBox,
                    boxItem['medications'] as List<Map<String, dynamic>>,
                    periodKey,
                  ),
                )
                .toList(),
          ],
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getBoxesForPeriod(String period) {
    final result = <Map<String, dynamic>>[];
    final selectedDateOnly = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    for (final box in _boxes) {
      // ไม่แสดงกล่องถ้าวันที่เลือกอยู่ก่อนวันที่สร้างกล่อง
      if (box.createdAt != null) {
        final createdDateOnly = DateTime(
          box.createdAt!.year,
          box.createdAt!.month,
          box.createdAt!.day,
        );
        if (selectedDateOnly.isBefore(createdDateOnly)) continue;
      }
      // แสดงกล่องในทุก period ที่ box มี (ไม่กรองยาตาม period)
      if (box.id != null && box.intakePeriods.contains(period)) {
        final dailyMeds = _boxDailyMedications[box.id] ?? [];

        // ตรวจสอบว่ามีกล่องนี้ใน result แล้วหรือยัง (เพื่อไม่ให้แสดงซ้ำ)
        final existingBox = result.firstWhere(
          (item) => (item['box'] as MedicationBox).id == box.id,
          orElse: () => {},
        );

        if (existingBox.isEmpty && dailyMeds.isNotEmpty) {
          // ยังไม่มีกล่องนี้ใน result → เพิ่มใหม่พร้อมยาทั้งหมดในกล่อง
          // ไม่กรองตาม period - แสดงยาทั้งหมดในกล่อง
          final allMeds = dailyMeds.map((med) {
            final medicationObj = med['medication'] as Map<String, dynamic>?;
            final medicationName =
                medicationObj?['name'] as String? ??
                med['medicationName'] as String? ??
                'ไม่ระบุชื่อ';
            final intakeTime =
                med['intakeTime'] as String? ??
                med['scheduledTime'] as String? ??
                '08:00';
            final scheduledTime = _formatTime(intakeTime);
            final statusRaw = med['status'] as String? ?? 'PENDING';
            final status = statusRaw.toUpperCase();
            final intakeId = med['id'] as String? ?? '';

            return {
              'id': intakeId,
              'medicationName': medicationName,
              'scheduledTime': scheduledTime,
              'status': status,
              'dosage': med['dosage'] ?? 1,
              'unit': med['unit'] ?? 'เม็ด',
            };
          }).toList();

          // ใช้ Set เพื่อป้องกันการแสดงยาซ้ำกัน
          final uniqueMeds = <String, Map<String, dynamic>>{};
          for (final med in allMeds) {
            final key = '${med['medicationName']}|${med['scheduledTime']}';
            if (!uniqueMeds.containsKey(key)) {
              uniqueMeds[key] = med;
            }
          }

          result.add({'box': box, 'medications': uniqueMeds.values.toList()});
        }
      }
    }
    return result;
  }

  String _formatTime(String timeStr) {
    if (timeStr.isEmpty) return '08:00';
    final parts = timeStr.split(':');
    if (parts.length >= 2) {
      return '${parts[0]}:${parts[1]}';
    }
    return timeStr;
  }

  Widget _buildBoxCard(
    MedicationBox box,
    List<Map<String, dynamic>> medications,
    String period,
  ) {
    final firstMed = medications.isNotEmpty ? medications.first : null;
    final timeStr =
        firstMed?['scheduledTime'] as String? ??
        firstMed?['intakeTime'] as String? ??
        '08:00';
    final formattedTime = _formatTime(timeStr);

    // ตรวจสอบสถานะที่ระดับกล่องเท่านั้น (ไม่ใช่รายการยาแต่ละตัว)
    // ตรวจสอบจาก intake ทั้งหมดของกล่องใน period นี้
    final allDailyMeds = _boxDailyMedications[box.id] ?? [];

    // กรอง intake ที่อยู่ใน period นี้
    final periodIntakes = allDailyMeds.where((med) {
      final intakeTime =
          med['intakeTime'] as String? ?? med['scheduledTime'] as String? ?? '';
      if (intakeTime.isEmpty) return false;

      // ตรวจสอบว่า intake นี้อยู่ใน period นี้หรือไม่
      final timeParts = intakeTime.split(':');
      if (timeParts.length >= 2) {
        final hour = int.tryParse(timeParts[0]) ?? 0;
        switch (period) {
          case 'MORNING':
            return hour >= 5 && hour < 11;
          case 'NOON':
            return hour >= 11 && hour < 16;
          case 'EVENING':
            return hour >= 16 && hour < 21;
          case 'BEDTIME':
            return hour >= 21 || hour < 5;
          default:
            return false;
        }
      }
      return false;
    }).toList();

    // ตรวจสอบสถานะของกล่อง: ถ้ามี intake ใดๆ ใน period นี้ที่ status = TAKEN แสดงว่ากล่องถูกทานแล้ว
    final periodStatuses = periodIntakes
        .map((m) => (m['status'] as String? ?? 'PENDING').toUpperCase())
        .toList();

    // ถ้าไม่มี intake ใน period นี้ ให้ใช้ข้อมูลทั้งหมดในกล่อง
    final statusesToCheck = periodStatuses.isNotEmpty
        ? periodStatuses
        : allDailyMeds
              .map((m) => (m['status'] as String? ?? 'PENDING').toUpperCase())
              .toList();

    // กล่องถูกทานแล้วถ้ามี intake ใดๆ ที่ status = TAKEN
    final isTaken =
        statusesToCheck.isNotEmpty && statusesToCheck.any((s) => s == 'TAKEN');
    final anyOverdue = statusesToCheck.any(
      (s) => s == 'OVERDUE' || s == 'MISSED',
    );
    final allPending =
        statusesToCheck.isEmpty || statusesToCheck.every((s) => s == 'PENDING');

    // ตรวจสอบ overdue: ถ้ามี OVERDUE/MISSED หรือทุกอัน PENDING และเวลาเลยแล้ว
    // แต่ไม่แสดง "เกินกำหนด" ถ้าไม่ใช่วันนี้ (แสดงเฉพาะวันนี้ที่เวลาเลยแล้ว)
    final today = DateTime.now();
    final isToday =
        _selectedDate.year == today.year &&
        _selectedDate.month == today.month &&
        _selectedDate.day == today.day;
    final isOverdue =
        anyOverdue || (allPending && isToday && _isTimePassed(formattedTime));

    return GestureDetector(
      onTap: () {
        // Navigate to patient pill box detail page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                PatientPillBoxDetailPage(box: box, patient: widget.patient),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
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
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    size: 20,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    box.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...(() {
              // Group by medication name to avoid showing the same medication multiple times
              // (e.g., MORNING/NOON/EVENING intakes are separate rows from API)
              final Map<String, Map<String, dynamic>> grouped = {};
              for (final med in medications) {
                final medName =
                    med['medicationName'] as String? ?? 'ไม่ระบุชื่อ';
                final medDosage = med['dosage'] as num?;
                final medUnit = med['unit'] as String? ?? 'เม็ด';
                final medStatus = med['status'] as String? ?? 'PENDING';
                final scheduledTime = med['scheduledTime'] as String? ?? '';

                final entry = grouped.putIfAbsent(medName, () {
                  return {
                    'medicationName': medName,
                    'dosage': medDosage,
                    'unit': medUnit,
                    'times': <String>{},
                    'statuses': <String>[],
                  };
                });

                (entry['times'] as Set<String>).add(scheduledTime);
                (entry['statuses'] as List<String>).add(medStatus);
              }

              return grouped.values.map((g) {
                final medName = g['medicationName'] as String;
                final medDosage = g['dosage'] as num?;
                final medUnit = g['unit'] as String? ?? 'เม็ด';
                // ผู้ดูแล: ไม่แสดงเวลา แสดงแค่ก่อนอาหาร/หลังอาหาร

                final dosageText = medDosage != null
                    ? '$medDosage $medUnit'
                    : '1 $medUnit';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.medication_outlined,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$medName ($dosageText)',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList();
            })(),
            const SizedBox(height: 8),
            Row(
              children: [
                if (_mealTimingLabel(box.intakeTiming).isNotEmpty) ...[
                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _mealTimingLabel(box.intakeTiming),
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isTaken
                        ? const Color(0xFF2ECC71)
                        : isOverdue
                        ? Colors.red
                        : Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: isTaken
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'ทานแล้ว',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : isOverdue
                      ? Text(
                          'เกินกำหนด',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.schedule, color: Colors.white, size: 18),
                            SizedBox(width: 4),
                            Text(
                              'รอทาน',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationCard(DailyIntake item) {
    final bool isTaken = item.status == IntakeStatus.TAKEN;
    final bool isNotTaken = item.status == IntakeStatus.NOT_TAKEN;
    final bool isMissed = item.status == IntakeStatus.MISSED;

    // Check if overdue: status is OVERDUE/MISSED OR (time has passed and status is PENDING and it's today)
    final today = DateTime.now();
    final isToday =
        _selectedDate.year == today.year &&
        _selectedDate.month == today.month &&
        _selectedDate.day == today.day;
    final bool isOverdue =
        item.status == IntakeStatus.OVERDUE ||
        item.status == IntakeStatus.MISSED ||
        (isToday &&
            _isTimePassed(item.time) &&
            item.status == IntakeStatus.PENDING);

    final resolvedPath = _resolveImagePath(item.imagePath);

    final bool isLowQuantity =
        item.remainingQuantity != null && item.remainingQuantity! < 7;

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
                if (_mealTimingLabel(item.intakeTiming).isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _mealTimingLabel(item.intakeTiming),
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ],
                if (item.remainingQuantity != null) ...[
                  const SizedBox(height: 4),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.medication_liquid,
                        size: 14,
                        color: isLowQuantity ? Colors.red : Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'เหลือ ${item.remainingQuantity} เม็ด',
                        style: TextStyle(
                          color: isLowQuantity ? Colors.red : Colors.grey[600],
                          fontSize: 13,
                          fontWeight: isLowQuantity
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (isTaken)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2ECC71),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.white,
                    size: 18,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'ทานแล้ว',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          else if (isNotTaken)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'ไม่กินยา',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else if (isMissed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.cancel_outlined, color: Colors.white, size: 18),
                  SizedBox(width: 4),
                  Text(
                    'Missed',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isOverdue ? Colors.red : Colors.orange,
                borderRadius: BorderRadius.circular(20),
              ),
              child: isOverdue
                  ? const Text(
                      'เกินกำหนด',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.schedule, color: Colors.white, size: 18),
                        SizedBox(width: 4),
                        Text(
                          'รอทาน',
                          style: TextStyle(
                            color: Colors.white,
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

  // Check if the scheduled time has passed
  bool _isTimePassed(String time) {
    try {
      final now = DateTime.now();
      final timeParts = time.split(':');
      if (timeParts.length >= 2) {
        final hour = int.tryParse(timeParts[0]) ?? 0;
        final minute = int.tryParse(timeParts[1]) ?? 0;
        final scheduleTime = DateTime(
          now.year,
          now.month,
          now.day,
          hour,
          minute,
        );
        return now.isAfter(scheduleTime);
      }
    } catch (e) {
      print('Error checking time passed: $e');
    }
    return false;
  }

  List<DailyIntake> _getFilteredSchedule(String period) {
    return _schedule.where((item) {
      if (item.periodKey != null && item.periodKey!.isNotEmpty) {
        final pk = item.periodKey!.toUpperCase();
        switch (period) {
          case 'morning':
            return pk == 'MORNING';
          case 'afternoon':
            return pk == 'NOON';
          case 'evening':
            return pk == 'EVENING';
          case 'night':
            return pk == 'BEDTIME';
          default:
            return false;
        }
      }

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
