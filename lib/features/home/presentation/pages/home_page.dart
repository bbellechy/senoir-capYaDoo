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

  // ── Collapsible header ──────────────────────────────────────────────────────
  // ความสูงของส่วน greeting + logo ที่จะซ่อนเมื่อ scroll ลง
  static const double _greetingHeight = 120.0;
  final ScrollController _contentScrollController = ScrollController();
  double _collapseProgress = 0.0; // 0 = full header, 1 = collapsed
  // ────────────────────────────────────────────────────────────────────────────

  List<DailyIntake> _schedule = [];
  List<MedicationBox> _boxes = [];
  Map<String, List<Map<String, dynamic>>> _boxDailyMedications = {};
  final PillBoxService _pillBoxService = PillBoxService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('th_TH', null);
    _contentScrollController.addListener(_onContentScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
    PageNavigationService().currentIndex.addListener(_onTabIndexChanged);
  }

  @override
  void dispose() {
    _contentScrollController.removeListener(_onContentScroll);
    _contentScrollController.dispose();
    PageNavigationService().currentIndex.removeListener(_onTabIndexChanged);
    _dateScrollController?.dispose();
    super.dispose();
  }

  // ── Collapse logic ──────────────────────────────────────────────────────────
  void _onContentScroll() {
    if (!_contentScrollController.hasClients) return;
    final offset = _contentScrollController.offset.clamp(0.0, _greetingHeight);
    final progress = offset / _greetingHeight;
    if ((progress - _collapseProgress).abs() > 0.005) {
      setState(() => _collapseProgress = progress);
    }
  }
  // ────────────────────────────────────────────────────────────────────────────

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
    await _checkOverdueStatus();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadBoxes() async {
    try {
      final boxes = await _pillBoxService.getAllPillBoxes();
      boxes.sort(
        (a, b) =>
            a.name.trim().toLowerCase().compareTo(b.name.trim().toLowerCase()),
      );
      if (mounted) {
        setState(() => _boxes = boxes);
        for (final box in boxes) {
          if (box.id != null) {
            final dailyMeds = await _pillBoxService.getDailyMedicationsForBox(
              box.id!,
              _selectedDate,
            );
            if (mounted) {
              setState(() => _boxDailyMedications[box.id!] = dailyMeds);
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

      for (final item in _schedule) {
        if (item.status == IntakeStatus.PENDING &&
            !item.intakeId.contains('_') &&
            item.intakeId.isNotEmpty) {
          if (_isTimePassedForSelectedDate(item.time)) {
            await MedicationScheduleService.markAsOverdue(item.intakeId);
            hasChanges = true;
          }
        }
      }

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

    if (!confirmed || !mounted) return;

    await _markAsTakenSmart(item, isLate: isLate);
  }

  Future<void> _markAsTakenSmart(
    DailyIntake item, {
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

  // ════════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Collapsible blue header (greeting + date picker) ──────────────
            _buildCollapsibleHeader(user),

            // ── White content card (fills rest of screen) ─────────────────────
            Expanded(child: _buildContentCard()),
          ],
        ),
      ),
    );
  }

  // ── Collapsible header ──────────────────────────────────────────────────────
  Widget _buildCollapsibleHeader(User? user) {
    // greeting + logo fade out ตาม collapseProgress
    final greetingOpacity = (1.0 - _collapseProgress * 1.5).clamp(0.0, 1.0);
    // ความสูงของ greeting section ค่อยๆ ลดลงเป็น 0
    final greetingCurrentHeight = _greetingHeight * (1.0 - _collapseProgress);

    return Column(
      children: [
        // ── Greeting + Logo (collapsible) ─────────────────────────────────
        ClipRect(
          child: AnimatedContainer(
            duration: Duration.zero, // ไม่ต้องการ animation เพราะ driven by scroll
            height: greetingCurrentHeight.clamp(0.0, _greetingHeight),
            child: Opacity(
              opacity: greetingOpacity,
              child: _buildHeader(user),
            ),
          ),
        ),

        // ── Date Picker (always visible, sticky) ──────────────────────────
        _buildDatePicker(),

        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildHeader(User? user) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
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
            height: 100,
            width: 100,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 100,
                width: 100,
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

    // เมื่อ collapsed เต็มที่ ให้ซ่อน Thai date label เพื่อประหยัดพื้นที่
    final dateLabelOpacity = (1.0 - _collapseProgress * 2.5).clamp(0.0, 1.0);
    final dateLabelHeight = 28.0 * (1.0 - _collapseProgress).clamp(0.0, 1.0);

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
        // Thai date label (fade out เร็วกว่า)
        ClipRect(
          child: AnimatedContainer(
            duration: Duration.zero,
            height: dateLabelHeight,
            child: Opacity(
              opacity: dateLabelOpacity,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  thaiDateFormat.format(_selectedDate),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Horizontal date strip (always visible)
        SizedBox(
          height: 72,
          child: Row(
            children: [
              const SizedBox(width: 16),
              GestureDetector(
                onTap: openCalendar,
                child: Container(
                  width: 44,
                  height: 44,
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
                    final dateOnly =
                        DateTime(date.year, date.month, date.day);
                    final isSelected =
                        DateFormat('yyyy-MM-dd').format(dateOnly) ==
                        DateFormat('yyyy-MM-dd').format(_selectedDate);
                    final isFutureDate = dateOnly.isAfter(todayDateOnly);

                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedDate = dateOnly);
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

  // ════════════════════════════════════════════════════════════════════════════
  // CONTENT CARD  (เชื่อม _contentScrollController กับ ListView)
  // ════════════════════════════════════════════════════════════════════════════

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
                // ── เชื่อม controller สำหรับ collapse ──
                controller: _contentScrollController,
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
      (a, b) =>
          (a['box'] as MedicationBox).name.trim().toLowerCase().compareTo(
            (b['box'] as MedicationBox).name.trim().toLowerCase(),
          ),
    );
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

  String _getDefaultTimeForPeriod(String period) {
    switch (period) {
      case 'MORNING':
        return '08:00';
      case 'NOON':
        return '12:00';
      case 'EVENING':
        return '18:00';
      case 'BEDTIME':
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
    final firstMed = medications.isNotEmpty ? medications.first : null;
    final timeStr =
        firstMed?['scheduledTime'] as String? ??
        firstMed?['intakeTime'] as String? ??
        '08:00';
    final formattedTime = _formatTime(timeStr);
    final allStatuses = medications
        .map((m) => m['status'] as String? ?? 'PENDING')
        .toList();
    final isTaken =
        medications.isNotEmpty &&
        allStatuses.every(
          (s) => s.toUpperCase() == 'TAKEN' || s.toUpperCase() == 'TAKEN_LATE',
        );
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
        ? (hasLateIntake
              ? MedicineBoxReminderStatus.taken_late
              : MedicineBoxReminderStatus.taken)
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

    if (!confirmed || !mounted) return;

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

  bool _isMedicationInAnyBox(DailyIntake item, String period) {
    final searchName = item.medicationName.trim().toLowerCase();
    for (final box in _boxes) {
      if (box.intakePeriods.contains(period)) {
        final boxMeds = _boxDailyMedications[box.id] ?? [];
        for (final bm in boxMeds) {
          final bmName =
              ((bm['medication'] as Map?)?['name'] as String? ??
                      bm['medicationName'] as String? ??
                      '')
                  .trim()
                  .toLowerCase();

          if (bmName == searchName) {
            final bmTime =
                bm['intakeTime'] as String? ??
                bm['scheduledTime'] as String? ??
                '';
            if (bmTime.isEmpty || _isTimeInPeriod(bmTime, period)) return true;
          }
        }

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

  bool _isTimePassedForSelectedDate(String time) {
    try {
      final now = DateTime.now();
      final selectedDateOnly = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );
      final todayOnly = DateTime(now.year, now.month, now.day);

      if (selectedDateOnly.isBefore(todayOnly)) return true;
      if (selectedDateOnly.isAfter(todayOnly)) return false;

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
      if (_isMedicationInAnyBox(item, periodKey)) return false;

      return true;
    }).toList();

    filtered.sort(
      (a, b) => a.medicationName.trim().compareTo(b.medicationName.trim()),
    );
    return filtered;
  }
}
