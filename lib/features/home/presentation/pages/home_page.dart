import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:capyadoo/core/model/daily_intake.dart';
import 'package:capyadoo/core/services/medication_schedule_service.dart';
import 'package:capyadoo/core/model/user.dart';
import 'package:capyadoo/core/providers/auth_provider.dart';
import 'package:capyadoo/features/pillbox/presentation/pages/pill_box_list_page.dart';
import 'package:capyadoo/features/pillbox/presentation/pages/pill_box_detail_page.dart';
import 'package:capyadoo/core/services/pill_box_service.dart';
import 'package:capyadoo/core/model/medication_box.dart';
import 'package:capyadoo/core/services/page_navigation_service.dart';
import 'package:capyadoo/core/utils/intake_timing_label.dart';
import 'package:capyadoo/core/widgets/confirm_intake_dialog.dart';
import 'package:capyadoo/features/home/presentation/widgets/medicine_box_reminder_card.dart';
import 'package:capyadoo/features/home/presentation/widgets/medicine_reminder_card.dart';
import 'package:capyadoo/features/caregivers/presentation/pages/caregivers_and_users_page.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime _selectedDate = DateTime.now();
  static const double _dateItemExtent = 58;
  ScrollController? _dateScrollController;
  List<DailyIntake> _schedule = [];
  List<MedicationBox> _boxes = [];
  Map<String, List<Map<String, dynamic>>> _boxDailyMedications = {};
  final PillBoxService _pillBoxService = PillBoxService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('th_TH', null);
    // เลื่อนโหลดข้อมูลไปหลัง build เสร็จ เพื่อไม่ให้ notifyListeners() ถูกเรียกระหว่าง build
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
    // HomePage อยู่ใน IndexedStack → ต้อง reload เมื่อกลับมาเป็นแท็บที่ active อีกครั้ง
    PageNavigationService().currentIndex.addListener(_onTabIndexChanged);
  }

  @override
  void dispose() {
    PageNavigationService().currentIndex.removeListener(_onTabIndexChanged);
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
      initialScrollOffset: initialIndex * _dateItemExtent,
    );
    return _dateScrollController!;
  }

  void _onTabIndexChanged() {
    if (!mounted) return;
    if (PageNavigationService().currentIndex.value == 0) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    if (auth.user == null) {
      await auth.loadProfile();
      if (!mounted) return;
      if (context.read<AuthProvider>().user == null) {
        _handleLogout();
        return;
      }
    }
    await _loadSchedule(showLoading: false);
    await _checkOverdueStatus(); // Check for late medications
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadBoxes() async {
    try {
      final boxes = await _pillBoxService.getAllPillBoxes();
      boxes.sort(
        (a, b) =>
            a.name.trim().toLowerCase().compareTo(b.name.trim().toLowerCase()),
      );
      print('Loaded ${boxes.length} boxes');
      if (mounted) {
        setState(() {
          _boxes = boxes;
        });
        // Load daily medications for each box
        for (final box in boxes) {
          if (box.id != null) {
            print('Loading daily medications for box: ${box.name} (${box.id})');
            print('Box intakePeriods: ${box.intakePeriods}');
            final dailyMeds = await _pillBoxService.getDailyMedicationsForBox(
              box.id!,
              _selectedDate,
            );
            print(
              'Loaded ${dailyMeds.length} daily medications for box ${box.name}',
            );
            if (dailyMeds.isNotEmpty) {
              print('Sample medication: ${dailyMeds.first}');
            }
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

  Future<void> _checkOverdueStatus() async {
    try {
      bool hasChanges = false;

      // 1. Check master medications schedule
      for (final item in _schedule) {
        // Check items with valid UUID intakeId (from backend)
        if (item.status == IntakeStatus.PENDING &&
            !item.intakeId.contains('_') &&
            item.intakeId.isNotEmpty) {
          if (_isTimePassedForSelectedDate(item.time)) {
            await MedicationScheduleService.markAsOverdue(item.intakeId);
            hasChanges = true;
          }
        }
      }

      // 2. Check medication boxes daily medications
      for (final boxId in _boxDailyMedications.keys) {
        final meds = _boxDailyMedications[boxId]!;
        for (final med in meds) {
          final status = (med['status'] as String? ?? 'PENDING').toUpperCase();
          final intakeId = med['id'] as String? ?? '';

          if (status == 'PENDING' && intakeId.isNotEmpty) {
            final intakeTime =
                med['intakeTime'] as String? ??
                med['scheduledTime'] as String? ??
                '';
            if (intakeTime.isNotEmpty &&
                _isTimePassedForSelectedDate(intakeTime)) {
              await MedicationScheduleService.markAsOverdue(intakeId);
              hasChanges = true;
            }
          }
        }
      }

      // Reload if any changes might have happened
      if (hasChanges) {
        await _loadSchedule(showLoading: false);
      }
    } catch (e) {
      print('Error checking overdue status: $e');
    }
  }

  Future<void> _handleLogout() async {
    await context.read<AuthProvider>().logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _loadSchedule({bool showLoading = true}) async {
    if (showLoading) setState(() => _isLoading = true);
    try {
      final data = await MedicationScheduleService.getDailySchedule(
        _selectedDate,
      );
      if (mounted) {
        setState(() {
          _schedule = data;
          if (!showLoading) _isLoading = false;
        });
      }
      // Reload boxes for the new date
      await _loadBoxes();
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isSelectedDateToday() {
    final fmt = DateFormat('yyyy-MM-dd');
    return fmt.format(_selectedDate) == fmt.format(DateTime.now());
  }

  bool _isSelectedDateTodayOrPast() {
    final now = DateTime.now();
    final selectedDateOnly = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final todayOnly = DateTime(now.year, now.month, now.day);
    return !selectedDateOnly.isAfter(todayOnly);
  }

  Future<void> _markAsTaken(
    String intakeId,
    String name, {
    bool isLate = false,
  }) async {
    if (intakeId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ข้อมูลไม่ถูกต้อง (Missing ID)'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Pass the name to show in the snackbar
    final result = await MedicationScheduleService.markAsTakenWithResponse(
      intakeId,
    );

    if (result.success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isLate
                  ? 'บันทึกว่า $name ทานล่าช้าแล้ว'
                  : 'บันทึกการทาน $name เรียบร้อยแล้ว',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        // อัพเดทข้อมูลจากหลังบ้านเพื่อให้ UI ตรงกันเสมอ (แก้ปัญหา refresh แล้วกลับเป็นค่าเดิม)
        await _loadSchedule(showLoading: false);
      }
    } else {
      if (mounted) {
        final extraMsg =
            (result.message != null && result.message!.trim().isNotEmpty)
            ? ' - ${result.message}'
            : '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.statusCode == 403
                  ? 'ไม่มีสิทธิ์ดำเนินการ (403)$extraMsg'
                  : 'ไม่สามารถบันทึกข้อมูลได้ (Status: ${result.statusCode})$extraMsg',
            ),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'ลองใหม่',
              textColor: Colors.white,
              onPressed: () => _markAsTaken(intakeId, name, isLate: isLate),
            ),
          ),
        );
      }
    }
  }

  Future<void> _confirmAndMarkAsTaken(
    DailyIntake item, {
    bool isLate = false,
  }) async {
    final confirmed = await showConfirmIntakeDialog(
      context,
      title: isLate ? 'ยืนยันการทานยาย้อนหลัง' : 'ยืนยันการทานยา',
      message: isLate
          ? 'คุณต้องการบันทึกการทานยาย้อนหลังสำหรับรายการที่เกินกำหนดนี้ใช่หรือไม่'
          : 'คุณต้องการที่จะยืนยันการทานยาตัวนี้ใช่หรือไม่',
    );

    if (!confirmed || !mounted) {
      return;
    }

    await _markAsTakenSmart(item, isLate: isLate);
  }

  Future<void> _markAsTakenSmart(
    DailyIntake item, {
    bool isLate = false,
  }) async {
    // ยืนยันการทานธรรมดาได้เฉพาะวันนี้; ส่วนทานล่าช้ากดได้เสมอเมื่อเกินกำหนด
    if (!isLate && !_isSelectedDateToday()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ยืนยันได้เฉพาะรายการของวันนี้เท่านั้น'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // ถ้าเป็น id แบบ generated (medId_date_time) ให้พยายาม resolve UUID จาก backend ก่อน
    String intakeId = item.intakeId;

    if (intakeId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ข้อมูลไม่ถูกต้อง (Missing ID)'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (intakeId.contains('_')) {
      final medicationId = item.medicationId;
      final resolved = await MedicationScheduleService.resolveBackendIntakeId(
        medicationId: medicationId,
        medicationName: item.medicationName,
        date: _selectedDate,
        time: item.time,
      );
      if (resolved != null && resolved.isNotEmpty) {
        intakeId = resolved;
      }
    }

    // ถ้ายัง resolve ไม่ได้ ให้แจ้งผู้ใช้ (ไม่ต้อง reload เพราะยังไม่มี intake ในระบบ)
    if (intakeId.contains('_')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ระบบยังไม่สร้างรายการวันนี้ กรุณาลองใหม่อีกครั้ง'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    await _markAsTaken(intakeId, item.medicationName, isLate: isLate);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile & Logo Header
            _buildHeader(user),

            // Date Picker Section
            _buildDatePicker(),
            const SizedBox(height: 12),

            // Main Content Card (always fills to bottom)
            Expanded(child: _buildContentCard()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(User? user) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'สวัสดี',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontFamily: 'Sarabun',
                  ),
                ),
                Text(
                  user?.fullName ?? '...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Sarabun',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Image.asset(
            'assets/images/logo-white-png.png',
            height: 120,
            width: 120,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.image_not_supported,
                  color: Colors.white,
                ),
              );
            },
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
        setState(() {
          _selectedDate = DateTime(picked.year, picked.month, picked.day);
        });
        _loadData();
      }
    }

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
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: Row(
            children: [
              const SizedBox(width: 16),
              GestureDetector(
                onTap: openCalendar,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.calendar_today_outlined,
                    color: AppColors.primaryBlue,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),
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
                      onTap: () {
                        setState(() {
                          _selectedDate = dateOnly;
                        });
                        _loadData();
                      },
                      child: Center(
                        child: Container(
                          width: 50,
                          height: 50,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : Colors.transparent,
                            shape: BoxShape.circle,
                            border: isFutureDate && !isSelected
                                ? Border.all(
                                    color: Colors.white.withOpacity(0.6),
                                    width: 2,
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
                                fontSize: 18,
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
              const SizedBox(width: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContentCard() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.offwhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildTopButton(
                    'กล่องยา',
                    Icons.shopping_bag_outlined,
                    AppColors.dinner,
                    AppColors.primaryBlue,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PillBoxListPage(),
                      ),
                    ).then((_) => _loadData()),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTopButton(
                    'ผู้ดูแล',
                    Icons.people_outline,
                    AppColors.dinner,
                    AppColors.primaryBlue,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CaregiversAndUsersPage(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                children: [
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else ...[
                    _buildTimeSection(
                      'เช้า',
                      '${_getFilteredSchedule("morning").length} รายการ',
                      AppColors.morning,
                      AppColors.morningBorder,
                      AppColors.morningIcon,
                      Icons.wb_sunny_outlined,
                      _getFilteredSchedule('morning'),
                    ),
                    const SizedBox(height: 16),
                    _buildTimeSection(
                      'กลางวัน',
                      '${_getFilteredSchedule("afternoon").length} รายการ',
                      AppColors.noon,
                      AppColors.noonBorder,
                      AppColors.noonIcon,
                      Icons.wb_sunny,
                      _getFilteredSchedule('afternoon'),
                    ),
                    const SizedBox(height: 16),
                    _buildTimeSection(
                      'เย็น',
                      '${_getFilteredSchedule("evening").length} รายการ',
                      AppColors.dinner,
                      AppColors.dinnerBorder,
                      AppColors.primaryBlue,
                      Icons.cloud_outlined,
                      _getFilteredSchedule('evening'),
                    ),
                    const SizedBox(height: 16),
                    _buildTimeSection(
                      'ก่อนนอน',
                      '${_getFilteredSchedule("night").length} รายการ',
                      AppColors.sleep,
                      AppColors.sleepBorder,
                      AppColors.sleepIcon,
                      Icons.nightlight_round_outlined,
                      _getFilteredSchedule('night'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopButton(
    String label,
    IconData icon,
    Color bgColor,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.whitelist,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.blueBorder, width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSection(
    String title,
    String count,
    Color bgColor,
    Color borderColor,
    Color iconColor,
    IconData icon,
    List<DailyIntake> items,
  ) {
    // Get boxes for this period
    // Map ภาษาไทยและภาษาอังกฤษไปยัง period
    final periodMap = {
      // ภาษาไทย
      'เช้า': 'MORNING',
      'กลางวัน': 'NOON',
      'เย็น': 'EVENING',
      'ก่อนนอน': 'BEDTIME',
      // ภาษาอังกฤษ (backup)
      'morning': 'MORNING',
      'afternoon': 'NOON',
      'evening': 'EVENING',
      'night': 'BEDTIME',
    };
    final period = periodMap[title] ?? periodMap[title.toLowerCase()] ?? '';

    final boxItems = _getBoxesForPeriod(period);
    final totalCount = items.length + boxItems.length;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 2),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    '$totalCount รายการ',
                    style: TextStyle(color: AppColors.textSub, fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (items.isEmpty && boxItems.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.medication_outlined,
                    color: AppColors.textSub,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ไม่มียาช่วงนี้',
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
                    period,
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
      if (box.createdAt != null) {
        final createdDateOnly = DateTime(
          box.createdAt!.year,
          box.createdAt!.month,
          box.createdAt!.day,
        );
        if (selectedDateOnly.isBefore(createdDateOnly)) continue;
      }

      if (box.id != null && box.intakePeriods.contains(period)) {
        final dailyMeds = _boxDailyMedications[box.id] ?? [];
        final convertedMeds = <Map<String, dynamic>>[];
        final seenKeys = <String>{};

        for (final med in dailyMeds) {
          final medicationObj = med['medication'] as Map<String, dynamic>?;
          final medicationName =
              (medicationObj?['name'] as String? ??
                      med['medicationName'] as String? ??
                      'ไม่ระบุชื่อ')
                  .trim();

          final intakeTime =
              med['intakeTime'] as String? ??
              med['scheduledTime'] as String? ??
              _getDefaultTimeForPeriod(period);

          if (!_isTimeInPeriod(intakeTime, period)) continue;

          final scheduledTime = _formatTime(intakeTime);
          final status = med['status'] as String? ?? 'PENDING';
          final intakeId = med['id'] as String? ?? '';

          // De-duplicate by name only within the period (coarse deduplication)
          // to ensure "trrrrr" only shows once in the box for "NOON"
          final dedupKey = medicationName.toLowerCase();
          if (seenKeys.contains(dedupKey)) continue;
          seenKeys.add(dedupKey);

          convertedMeds.add({
            'id': intakeId,
            'medicationName': medicationName,
            'scheduledTime': scheduledTime,
            'status': status,
            'dosage': med['dosage'] ?? 1,
            'unit': med['unit'] ?? 'เม็ด',
          });
        }

        if (convertedMeds.isNotEmpty) {
          convertedMeds.sort((a, b) {
            final nameComp = (a['medicationName'] as String).compareTo(
              b['medicationName'] as String,
            );
            if (nameComp != 0) return nameComp;
            return (a['scheduledTime'] as String).compareTo(
              b['scheduledTime'] as String,
            );
          });
          result.add({'box': box, 'medications': convertedMeds});
        } else if (box.medications.isNotEmpty) {
          // Fallback if no daily intakes loaded yet
          final fallbackMeds = <Map<String, dynamic>>[];
          final fallbackSeen = <String>{};

          for (final med in box.medications) {
            final medName = (med['name'] as String? ?? 'ไม่ระบุชื่อ').trim();
            final scheduledTime = _getDefaultTimeForPeriod(period);
            final key = '${medName.toLowerCase()}|$scheduledTime';

            if (fallbackSeen.contains(key)) continue;
            fallbackSeen.add(key);

            fallbackMeds.add({
              'id': med['id'] ?? '',
              'medicationName': medName,
              'dosage': med['dosage'] ?? med['quantity'] ?? 1,
              'unit': med['unit'] ?? 'เม็ด',
              'status': 'PENDING',
              'scheduledTime': scheduledTime,
            });
          }
          fallbackMeds.sort(
            (a, b) => (a['medicationName'] as String).compareTo(
              b['medicationName'] as String,
            ),
          );
          result.add({'box': box, 'medications': fallbackMeds});
        }
      }
    }

    result.sort(
      (a, b) => (a['box'] as MedicationBox).name.trim().toLowerCase().compareTo(
        (b['box'] as MedicationBox).name.trim().toLowerCase(),
      ),
    );
    return result;
  }

  // แปลงเวลา format "HH:mm:ss" หรือ "HH:mm" เป็น "HH:mm"
  String _formatTime(String timeStr) {
    if (timeStr.isEmpty) return '08:00';
    final parts = timeStr.split(':');
    if (parts.length >= 2) {
      return '${parts[0]}:${parts[1]}';
    }
    return timeStr;
  }

  String _getDefaultTimeForPeriod(String period) {
    switch (period) {
      case 'MORNING':
        return '08:00';
      case 'NOON':
        return '12:00';
      case 'EVENING':
        return '18:00';
      case 'BEDTIME':
        // Keep consistent with backend schedule (DailyMedicationService + box schedule uses 21:00)
        return '21:00';
      default:
        return '08:00';
    }
  }

  Widget _buildBoxCard(
    MedicationBox box,
    List<Map<String, dynamic>> medications,
    String period,
  ) {
    // Get time from first medication or use box default
    final firstMed = medications.isNotEmpty ? medications.first : null;
    // รองรับทั้ง scheduledTime และ intakeTime
    final timeStr =
        firstMed?['scheduledTime'] as String? ??
        firstMed?['intakeTime'] as String? ??
        '08:00';
    // แปลง format ถ้าเป็น "HH:mm:ss" เป็น "HH:mm"
    final formattedTime = _formatTime(timeStr);
    // สถานะกล่อง: ถ้ายาทุกตัวในกล่องทานแล้ว = ทานแล้ว (กดยืนยันครั้งเดียวสำหรับทั้งกล่อง)
    final allStatuses = medications
        .map((m) => m['status'] as String? ?? 'PENDING')
        .toList();
    final isTaken =
        medications.isNotEmpty &&
        allStatuses.every((s) => s.toUpperCase() == 'TAKEN' || s.toUpperCase() == 'TAKEN_LATE');
    final hasLateIntake = 
        medications.isNotEmpty &&
        allStatuses.any((s) => s.toUpperCase() == 'TAKEN_LATE');
    final isNotTaken =
        medications.isNotEmpty &&
        allStatuses.every((s) => s.toUpperCase() == 'NOT_TAKEN');
    final isMissed =
        medications.isNotEmpty &&
        allStatuses.any((s) => s.toUpperCase() == 'MISSED');
    final isOverdue =
        !isTaken &&
        !isNotTaken &&
        (allStatuses.any((s) => s.toUpperCase() == 'OVERDUE') ||
            (allStatuses.any((s) => s.toUpperCase() == 'PENDING') &&
                _isTimePassedForSelectedDate(formattedTime)));
    final canConfirmToday = _isSelectedDateToday();
    final canConfirmLate = _isSelectedDateTodayOrPast();

    final cardStatus = isTaken
        ? (hasLateIntake ? MedicineBoxReminderStatus.taken_late : MedicineBoxReminderStatus.taken)
        : (isOverdue || isNotTaken || isMissed)
        ? MedicineBoxReminderStatus.overdue
        : MedicineBoxReminderStatus.pending;

    final medicineItems = medications.map((med) {
      final medName = med['medicationName'] as String? ?? 'ไม่ระบุชื่อ';
      final medDosage = med['dosage'] as num?;
      final unitRaw = (med['unit'] as String?)?.trim() ?? '';
      final medUnit = unitRaw.isEmpty ? 'เม็ด' : unitRaw;
      final medImagePath = (med['imagePath'] as String?)?.trim();
      final dosageText = medDosage != null
          ? (medDosage == medDosage.roundToDouble()
                ? '${medDosage.toInt()} $medUnit'
                : '$medDosage $medUnit')
          : '1 $medUnit';
      return MedicineInBox(
        name: medName,
        dosage: dosageText,
        imagePath: medImagePath,
      );
    }).toList();

    final parsedHour = int.tryParse(formattedTime.split(':').first) ?? 8;
    final parsedMinute = int.tryParse(formattedTime.split(':').last) ?? 0;
    final scheduledAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      parsedHour,
      parsedMinute,
    );

    return MedicineBoxReminderCard(
      boxName: box.name,
      boxImagePath: box.imagePath,
      medicines: medicineItems,
      scheduledTime: scheduledAt,
      intakeTimingLabel: toThaiIntakeTimingLabel(box.intakeTiming),
      status: cardStatus,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PillBoxDetailPage(pillBox: box)),
        ).then((_) => _loadData());
      },
      onConfirm: cardStatus == MedicineBoxReminderStatus.pending
          ? (canConfirmToday
                ? () => _markWholeBoxAsTaken(box, period, isLate: false)
                : null)
          : (cardStatus == MedicineBoxReminderStatus.overdue &&
                    canConfirmLate &&
                    !isNotTaken &&
                    !isMissed
                ? () => _markWholeBoxAsTaken(box, period, isLate: true)
                : null),
    );
  }

  /// ยืนยันการทานยาทั้งกล่องของช่วงนั้นเท่านั้น (กดเช้า = มาร์กเฉพาะเช้า ไม่มาร์กกลางวัน/เย็น/ก่อนนอน)
  Future<void> _markWholeBoxAsTaken(
    MedicationBox box,
    String period, {
    bool isLate = false,
  }) async {
    if (!isLate && !_isSelectedDateToday()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ยืนยันได้เฉพาะรายการของวันนี้เท่านั้น'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    if (box.id == null || box.id!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ข้อมูลไม่ถูกต้อง (Missing Box ID)'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final confirmed = await showConfirmIntakeDialog(
      context,
      title: isLate ? 'ยืนยันการทานยาย้อนหลัง' : 'ยืนยันการทานยา',
      message: isLate
          ? 'คุณต้องการบันทึกการทานยาย้อนหลังของกล่องยานี้ใช่หรือไม่'
          : 'คุณต้องการที่จะยืนยันการทานยากล่องนี้ใช่หรือไม่',
    );

    if (!confirmed || !mounted) {
      return;
    }

    final userId = context.read<AuthProvider>().user?.id;
    final success = await _pillBoxService.markBoxAsTaken(
      box.id!,
      _selectedDate,
      userId: userId,
      period: period,
    );

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isLate
                  ? 'บันทึกว่า ${box.name} ทานล่าช้าแล้ว'
                  : 'บันทึกการทาน ${box.name} เรียบร้อยแล้ว',
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
        // อัพเดทข้อมูลจากหลังบ้าน
        await _loadSchedule(showLoading: false);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ไม่สามารถบันทึกข้อมูลได้'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildMedicationCard(DailyIntake item) {
    final bool isTaken = item.status == IntakeStatus.TAKEN;
    final bool isLateIntake = item.status == IntakeStatus.TAKEN_LATE;
    final bool isNotTaken = item.status == IntakeStatus.NOT_TAKEN;
    final bool isMissed = item.status == IntakeStatus.MISSED;

    // Check if overdue: only for today and only if time has passed and status is PENDING
    // Don't mark as overdue if already TAKEN or NOT_TAKEN
    final bool isOverdue =
        !isTaken &&
        !isLateIntake &&
        !isNotTaken &&
        (item.status == IntakeStatus.OVERDUE ||
            item.status == IntakeStatus.MISSED ||
            (_isTimePassedForSelectedDate(item.time) &&
                item.status == IntakeStatus.PENDING));
    final bool canConfirmToday = _isSelectedDateToday();
    final bool canConfirmLate = _isSelectedDateTodayOrPast();

    final cardStatus = isTaken
        ? MedicineReminderStatus.taken
        : isLateIntake
        ? MedicineReminderStatus.taken_late
        : (isOverdue || isNotTaken || isMissed)
        ? MedicineReminderStatus.overdue
        : MedicineReminderStatus.pending;

    final timeParts = item.time.split(':');
    final hour = timeParts.isNotEmpty ? int.tryParse(timeParts[0]) ?? 0 : 0;
    final minute = timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 0 : 0;

    return MedicineReminderCard(
      medicineName: item.medicationName,
      dosage: '1 เม็ด',
      imagePath: item.imagePath,
      scheduledTime: DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        hour,
        minute,
      ),
      intakeTimingLabel: toThaiIntakeTimingLabel(item.intakeTiming),
      status: cardStatus,
      onConfirm: cardStatus == MedicineReminderStatus.pending
          ? (canConfirmToday
                ? () => _confirmAndMarkAsTaken(item, isLate: false)
                : null)
          : (cardStatus == MedicineReminderStatus.overdue &&
                    canConfirmLate &&
                    !isNotTaken &&
                    !isMissed
                ? () => _confirmAndMarkAsTaken(item, isLate: true)
                : null),
    );
  }

  // Helper to check if a time string falls into a specific period range
  bool _isTimeInPeriod(String timeStr, String p) {
    if (timeStr.isEmpty) return false;
    final parts = timeStr.split(':');
    if (parts.length < 2) return false;
    final hour = int.tryParse(parts[0]) ?? -1;
    if (hour < 0) return false;

    switch (p) {
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

  // Determine if a specific medication name is already in any box for this period
  bool _isMedicationInAnyBox(DailyIntake item, String period) {
    final searchName = item.medicationName.trim().toLowerCase();
    for (final box in _boxes) {
      if (box.intakePeriods.contains(period)) {
        // 1. Check loaded daily intakes for this box
        final boxMeds = _boxDailyMedications[box.id] ?? [];
        for (final bm in boxMeds) {
          final bmName =
              ((bm['medication'] as Map?)?['name'] as String? ??
                      bm['medicationName'] as String? ??
                      '')
                  .trim()
                  .toLowerCase();

          if (bmName == searchName) {
            // Check if this specific intake in the box belongs to the same period
            final bmTime =
                bm['intakeTime'] as String? ??
                bm['scheduledTime'] as String? ??
                '';
            // If the box is assigned to this period and contains this med name,
            // we treat it as being in the box for this period.
            if (bmTime.isEmpty || _isTimeInPeriod(bmTime, period)) return true;
          }
        }

        // 2. Check box definition if daily intakes are empty
        if (boxMeds.isEmpty) {
          for (final m in box.medications) {
            final mName = (m['name'] as String? ?? '').trim().toLowerCase();
            if (mName == searchName) return true;
          }
        }
      }
    }
    return false;
  }

  // Check if the scheduled time has passed
  // Now handles past dates correctly: if the date is in the past, time always "passed"
  bool _isTimePassedForSelectedDate(String time) {
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
    final periodKey =
        {
          'morning': 'MORNING',
          'afternoon': 'NOON',
          'evening': 'EVENING',
          'night': 'BEDTIME',
        }[period] ??
        period.toUpperCase();

    final filtered = _schedule.where((item) {
      bool timeMatch = false;
      if (item.periodKey != null && item.periodKey!.isNotEmpty) {
        final pk = item.periodKey!.toUpperCase();
        switch (period) {
          case 'morning':
            timeMatch = pk == 'MORNING';
            break;
          case 'afternoon':
            timeMatch = pk == 'NOON';
            break;
          case 'evening':
            timeMatch = pk == 'EVENING';
            break;
          case 'night':
            timeMatch = pk == 'BEDTIME';
            break;
        }
      } else {
        final hour = int.parse(item.time.split(':')[0]);
        switch (period) {
          case 'morning':
            timeMatch = hour >= 5 && hour < 11;
            break;
          case 'afternoon':
            timeMatch = hour >= 11 && hour < 16;
            break;
          case 'evening':
            timeMatch = hour >= 16 && hour < 21;
            break;
          case 'night':
            timeMatch = hour >= 21 || hour < 5;
            break;
        }
      }

      if (!timeMatch) return false;

      // Hide if already in a box for this period
      if (_isMedicationInAnyBox(item, periodKey)) {
        return false;
      }

      return true;
    }).toList();

    filtered.sort(
      (a, b) => a.medicationName.trim().compareTo(b.medicationName.trim()),
    );
    return filtered;
  }
}
