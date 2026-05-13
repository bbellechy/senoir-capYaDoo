import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:capyadoo/core/config/api_config.dart';
import 'package:capyadoo/core/model/daily_intake.dart';
import 'package:capyadoo/core/model/care_models.dart';
import 'package:capyadoo/core/services/care_service.dart';
import 'package:capyadoo/core/services/pill_box_service.dart';
import 'package:capyadoo/core/model/medication_box.dart';
import 'package:capyadoo/core/utils/intake_timing_label.dart';
import 'package:capyadoo/features/caregivers/presentation/widgets/patient_pill_box_detail_page.dart';
import 'package:capyadoo/features/home/presentation/widgets/medicine_reminder_card.dart';
import 'package:capyadoo/features/home/presentation/widgets/medicine_box_reminder_card.dart';
import 'package:intl/intl.dart';

class PatientDetailPage extends StatefulWidget {
  final Patient patient;
  const PatientDetailPage({super.key, required this.patient});

  @override
  State<PatientDetailPage> createState() => _PatientDetailPageState();
}

class _PatientDetailPageState extends State<PatientDetailPage> {
  DateTime _selectedDate = DateTime.now();
  static const double _dateItemExtent = 58;
  ScrollController? _dateScrollController;
  List<DailyIntake> _schedule = [];
  List<MedicationBox> _boxes = [];
  Map<String, List<Map<String, dynamic>>> _boxDailyMedications = {};
  final PillBoxService _pillBoxService = PillBoxService();
  bool _isLoading = true;
  int _loadSeq = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reloadForDate(_selectedDate);
    });
  }

  @override
  void dispose() {
    _dateScrollController?.dispose();
    super.dispose();
  }

  ScrollController _getDateScrollController(
    DateTime minDate,
    DateTime todayDate,
  ) {
    if (_dateScrollController != null) return _dateScrollController!;

    final todayIndex = todayDate.difference(minDate).inDays;
    final initialIndex = (todayIndex - 2).clamp(0, 1000000);
    _dateScrollController = ScrollController(
      initialScrollOffset: initialIndex * _dateItemExtent.w,
    );
    return _dateScrollController!;
  }

  Future<void> _reloadForDate(DateTime date) async {
    final int requestSeq = ++_loadSeq;
    if (mounted) {
      setState(() {
        _isLoading = true;
        _schedule = [];
        _boxes = [];
        _boxDailyMedications = {};
      });
    }

    try {
      final scheduleFuture = CareService.getPatientSchedule(
        widget.patient.patientId,
        date,
      );
      final boxesFuture = CareService.getPatientMedicationBoxes(
        widget.patient.patientId,
      );

      final data = await scheduleFuture;
      final boxes = await boxesFuture;
      final boxesSorted = List<MedicationBox>.from(boxes)
        ..sort(
          (a, b) => a.name.trim().toLowerCase().compareTo(
            b.name.trim().toLowerCase(),
          ),
        );

      if (!mounted || requestSeq != _loadSeq) return;

      // Load daily medications for each box (parallel for responsiveness)
      // Retry เมื่อได้รายการว่าง เพราะ backend บางครั้งสร้าง intake ช้า รอบแรกอาจคืนว่าง
      final Map<String, List<Map<String, dynamic>>> dailyByBoxId = {};
      const int maxAttempts = 3;
      const Duration retryDelay = Duration(milliseconds: 500);

      await Future.wait(
        boxesSorted.where((b) => b.id != null).map((box) async {
          List<Map<String, dynamic>> meds = [];
          for (int attempt = 1; attempt <= maxAttempts; attempt++) {
            if (!mounted || requestSeq != _loadSeq) return;
            meds = await _pillBoxService.getDailyMedicationsForBox(
              box.id!,
              date,
              userId: widget.patient.patientId,
            );
            if (meds.isNotEmpty) break;
            if (attempt < maxAttempts) await Future.delayed(retryDelay);
          }
          if (!mounted || requestSeq != _loadSeq) return;
          dailyByBoxId[box.id!] = meds;
        }),
      );

      if (!mounted || requestSeq != _loadSeq) return;

      setState(() {
        _schedule = data;
        _boxes = boxesSorted;
        _boxDailyMedications = dailyByBoxId;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || requestSeq != _loadSeq) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      body: Stack(
        children: [
          Container(
            height: 300.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40.r),
                bottomRight: Radius.circular(40.r),
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -40.w,
                  top: -40.h,
                  child: Container(
                    width: 180.w,
                    height: 180.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                ),
                Positioned(
                  left: -20.w,
                  bottom: -20.h,
                  child: Container(
                    width: 120.w,
                    height: 120.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () => _reloadForDate(_selectedDate),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    SizedBox(height: 20.h),
                    _buildDatePicker(),
                    SizedBox(height: 20.h),
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
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ข้อมูลการทานยาของ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontFamily: 'Sarabun',
                        ),
                      ),
                      Text(
                        widget.patient.fullName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28.sp,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Sarabun',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                    ],
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
    final now = DateTime.now();
    final todayDateOnly = DateTime(now.year, now.month, now.day);
    final minDate = DateTime(now.year, now.month - 1, now.day);
    final maxDate = DateTime(now.year, now.month + 1, now.day);
    final itemCount = maxDate.difference(minDate).inDays + 1;

    Future<void> openCalendar() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: minDate,
        lastDate: maxDate,
      );
      if (picked != null) {
        final dateOnly = DateTime(picked.year, picked.month, picked.day);
        setState(() {
          _selectedDate = dateOnly;
        });
        await _reloadForDate(dateOnly);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Text(
            thaiDateFormat.format(_selectedDate),
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          height: 80.h,
          child: Row(
            children: [
              SizedBox(width: 16.w),
              GestureDetector(
                onTap: openCalendar,
                child: Container(
                  width: 48.w,
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: const Icon(
                    Icons.calendar_today_outlined,
                    color: AppColors.primaryBlue,
                    size: 20.sp,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: ListView.builder(
                  controller: _getDateScrollController(minDate, todayDateOnly),
                  scrollDirection: Axis.horizontal,
                  itemCount: itemCount,
                  itemBuilder: (context, index) {
                    final date = minDate.add(Duration(days: index));
                    final dateOnly = DateTime(date.year, date.month, date.day);
                    final isSelected =
                        DateFormat('yyyy-MM-dd').format(dateOnly) ==
                        DateFormat('yyyy-MM-dd').format(_selectedDate);
                    final isFutureDate = dateOnly.isAfter(todayDateOnly);

                    return GestureDetector(
                      onTap: () async {
                        setState(() {
                          _selectedDate = dateOnly;
                        });
                        await _reloadForDate(dateOnly);
                      },
                      child: Center(
                        child: Container(
                          width: 50.w,
                          height: 50.h,
                          margin: EdgeInsets.symmetric(horizontal: 4.w),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : Colors.transparent,
                            shape: BoxShape.circle,
                            border: isFutureDate && !isSelected
                                ? Border.all(
                                    color: Colors.white.withOpacity(0.6),
                                    width: 2.w,
                                  )
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              '${date.day}',
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.primaryBlue
                                    : Colors.white,
                                fontSize: 18.sp,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(width: 16.w),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContentCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.offwhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40.r),
          topRight: Radius.circular(40.r),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
      child: Column(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else ...[
            _buildTimeSection(
              'เช้า',
              'morning',
              AppColors.morning,
              AppColors.morningBorder,
              AppColors.morningIcon,
              Icons.wb_sunny_outlined,
            ),
            SizedBox(height: 16.h),
            _buildTimeSection(
              'กลางวัน',
              'afternoon',
              AppColors.noon,
              AppColors.noonBorder,
              AppColors.noonIcon,
              Icons.wb_sunny,
            ),
            SizedBox(height: 16.h),
            _buildTimeSection(
              'เย็น',
              'evening',
              AppColors.dinner,
              AppColors.dinnerBorder,
              AppColors.primaryBlue,
              Icons.cloud_outlined,
            ),
            SizedBox(height: 16.h),
            _buildTimeSection(
              'ก่อนนอน',
              'night',
              AppColors.sleep,
              AppColors.sleepBorder,
              AppColors.sleepIcon,
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
    Color borderColor,
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
        color: bgColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: borderColor, width: 2.w),
      ),
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(icon, color: iconColor, size: 24.sp),
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20.sp,
                    ),
                  ),
                  Text(
                    '$totalCount รายการ',
                    style: TextStyle(
                      color: AppColors.textSub,
                      fontSize: 16.sp,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16.h),
          if (items.isEmpty && boxItems.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.medication_outlined,
                    color: AppColors.textSub,
                    size: 32.sp,
                  ),
                  SizedBox(height: 8.h),
                  const Text(
                    'ไม่มียาในช่วงนี้',
                    style: TextStyle(color: AppColors.textSub),
                  ),
                ],
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

        // แสดงกล่องเสมอ (แม้วันที่นั้น backend ยังไม่สร้าง intake เช่น วันในอนาคต)
        if (existingBox.isEmpty) {
          // ยังไม่มีกล่องนี้ใน result → เพิ่มใหม่พร้อมยาทั้งหมดในกล่อง (หรือรายการว่างถ้า API คืนมาเปล่า)
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
            final medRemainingRaw =
                med['remainingQuantity'] ?? medicationObj?['remainingQuantity'];
            final medRemaining = medRemainingRaw == null
                ? null
                : int.tryParse(medRemainingRaw.toString());

            return {
              'id': intakeId,
              'medicationName': medicationName,
              'scheduledTime': scheduledTime,
              'status': status,
              'dosage': med['dosage'] ?? 1,
              'unit': med['unit'] ?? 'เม็ด',
              'remainingQuantity': medRemaining,
            };
          }).toList();

          // ใช้ Set เพื่อป้องกันการแสดงยาซ้ำกัน
          final uniqueMeds = <String, Map<String, dynamic>>{};
          for (final med in allMeds) {
            final rawName = (med['medicationName'] as String? ?? '');
            final normName = rawName.trim().toLowerCase().replaceAll(
              RegExp(r'\s+'),
              ' ',
            );
            final key = '$normName|${med['scheduledTime']}';
            if (!uniqueMeds.containsKey(key)) {
              uniqueMeds[key] = med;
            }
          }

          final medsSorted = uniqueMeds.values.toList()
            ..sort((a, b) {
              final an = (a['medicationName'] as String? ?? '')
                  .trim()
                  .toLowerCase();
              final bn = (b['medicationName'] as String? ?? '')
                  .trim()
                  .toLowerCase();
              final byName = an.compareTo(bn);
              if (byName != 0) return byName;
              final at = (a['scheduledTime'] as String? ?? '');
              final bt = (b['scheduledTime'] as String? ?? '');
              return at.compareTo(bt);
            });

          result.add({'box': box, 'medications': medsSorted});
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

    // กล่องถูกทานแล้วถ้ามี intake ใดๆ ที่ status = TAKEN หรือ TAKEN_LATE
    final isTaken =
        statusesToCheck.isNotEmpty &&
        statusesToCheck.any((s) => s == 'TAKEN' || s == 'TAKEN_LATE');
    final hasLateIntake =
        statusesToCheck.isNotEmpty &&
        statusesToCheck.any((s) => s == 'TAKEN_LATE');
    final anyOverdue = statusesToCheck.any(
      (s) => s == 'OVERDUE' || s == 'MISSED',
    );
    final allPending =
        statusesToCheck.isEmpty || statusesToCheck.every((s) => s == 'PENDING');

    // Check overdue: if any item is already marked OVERDUE/MISSED, or if all are PENDING but time has passed.
    final isOverdue =
        anyOverdue || (allPending && _isTimePassed(formattedTime));

    final boxStatus = isTaken
        ? (hasLateIntake
              ? MedicineBoxReminderStatus.taken_late
              : MedicineBoxReminderStatus.taken)
        : (isOverdue
              ? MedicineBoxReminderStatus.overdue
              : MedicineBoxReminderStatus.pending);

    final groupedByName = <String, MedicineInBox>{};
    for (final med in medications) {
      final medName = med['medicationName'] as String? ?? 'ไม่ระบุชื่อ';
      final medDosage = med['dosage'] as num?;
      final medUnit = med['unit'] as String? ?? 'เม็ด';
      final remaining = med['remainingQuantity'] as int?;
      final medImagePath = _resolveImagePath(med['imagePath'] as String?);
      final dosageText = medDosage != null
          ? '$medDosage $medUnit'
          : '1 $medUnit';
      final fullDosageText = (remaining != null && remaining > 0)
          ? '$dosageText | เหลือ $remaining เม็ด'
          : dosageText;
      groupedByName[medName] = MedicineInBox(
        name: medName,
        dosage: fullDosageText,
        imagePath: medImagePath,
      );
    }

    return MedicineBoxReminderCard(
      boxName: box.name,
      boxImagePath: _resolveImagePath(box.imagePath),
      medicines: groupedByName.values.toList(),
      scheduledTime: _combineSelectedDateWithTime(formattedTime),
      intakeTimingLabel: toThaiIntakeTimingLabel(box.intakeTiming),
      status: boxStatus,
      onConfirm: null,
      pendingButtonText: 'รอทาน',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                PatientPillBoxDetailPage(box: box, patient: widget.patient),
          ),
        );
      },
    );
  }

  Widget _buildMedicationCard(DailyIntake item) {
    final bool isOverdue =
        item.status == IntakeStatus.OVERDUE ||
        item.status == IntakeStatus.MISSED ||
        (_isTimePassed(item.time) && item.status == IntakeStatus.PENDING);

    final reminderStatus = item.status == IntakeStatus.TAKEN
        ? MedicineReminderStatus.taken
        : (item.status == IntakeStatus.TAKEN_LATE
              ? MedicineReminderStatus.taken_late
              : (isOverdue
                    ? MedicineReminderStatus.overdue
                    : MedicineReminderStatus.pending));

    final dosageNumber = item.dosage;
    final dosageUnit = (item.unit == null || item.unit!.isEmpty)
        ? 'เม็ด'
        : item.unit!;
    final baseDosageText = dosageNumber != null
        ? '${dosageNumber.toString().replaceAll(RegExp(r'\.0$'), '')} $dosageUnit'
        : '1 $dosageUnit';
    final dosageText =
        (item.remainingQuantity != null && item.remainingQuantity! > 0)
        ? '($baseDosageText | เหลือ ${item.remainingQuantity} เม็ด)'
        : '($baseDosageText)';

    return MedicineReminderCard(
      medicineName: item.medicationName,
      dosage: dosageText,
      imagePath: _resolveImagePath(item.imagePath),
      scheduledTime: _combineSelectedDateWithTime(item.time),
      intakeTimingLabel: toThaiIntakeTimingLabel(item.intakeTiming),
      status: reminderStatus,
      onConfirm: null,
      pendingButtonText: 'รอทาน',
    );
  }

  DateTime _combineSelectedDateWithTime(String time) {
    final parts = time.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      hour,
      minute,
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
  // Now handles past dates: if the date is in the past, time always "passed"
  bool _isTimePassed(String time) {
    try {
      final now = DateTime.now();
      final selectedDateOnly = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );
      final todayOnly = DateTime(now.year, now.month, now.day);

      // If selected date is in the past, all scheduled times have passed
      if (selectedDateOnly.isBefore(todayOnly)) {
        return true;
      }

      // If selected date is in the future, no scheduled times have passed yet
      if (selectedDateOnly.isAfter(todayOnly)) {
        return false;
      }

      // If selected date is today, check the specific time
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
