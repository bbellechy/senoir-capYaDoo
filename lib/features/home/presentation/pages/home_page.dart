import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:capyadoo/core/model/daily_intake.dart';
import 'package:capyadoo/core/services/medication_schedule_service.dart';
import 'package:capyadoo/core/model/user.dart';
import 'package:capyadoo/core/providers/auth_provider.dart';
import 'package:capyadoo/features/pillbox/presentation/pages/pill_box_list_page.dart';
import 'package:capyadoo/features/pillbox/presentation/pages/pill_box_detail_page.dart';
import 'package:capyadoo/features/care/presentation/pages/care_management_page.dart';
import 'package:capyadoo/core/services/pill_box_service.dart';
import 'package:capyadoo/core/model/medication_box.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime _selectedDate = DateTime.now();
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

  Future<void> _markAsTaken(String intakeId, String name) async {
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
            content: Text('บันทึกการทาน $name เรียบร้อยแล้ว'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        // อัพเดทเฉพาะ item ที่เปลี่ยน ไม่ต้อง reload ทั้งหน้า
        setState(() {
          final index = _schedule.indexWhere(
            (item) => item.intakeId == intakeId,
          );
          if (index != -1) {
            _schedule[index] = DailyIntake(
              intakeId: _schedule[index].intakeId,
              medicationName: _schedule[index].medicationName,
              time: _schedule[index].time,
              periodKey: _schedule[index].periodKey,
              intakeTiming: _schedule[index].intakeTiming,
              status: IntakeStatus.TAKEN,
              imagePath: _schedule[index].imagePath,
              remainingQuantity: _schedule[index].remainingQuantity,
              medicationId: _schedule[index].medicationId,
            );
          }
        });
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
              onPressed: () => _markAsTaken(intakeId, name),
            ),
          ),
        );
      }
    }
  }

  Future<void> _markAsTakenSmart(DailyIntake item) async {
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

    await _markAsTaken(intakeId, item.medicationName);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      body: Stack(
        children: [
          // Blue Header Background
          Container(
            height: 300,
            decoration: const BoxDecoration(
              color: Color(0xFF1E88E5),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),

          SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile & Logo Header
                    _buildHeader(user),
                    const SizedBox(height: 20),

                    // Date Picker Section
                    _buildDatePicker(),
                    const SizedBox(height: 20),

                    // Main Content Card
                    _buildContentCard(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(User? user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: _handleLogout,
              ),
              Column(
                children: [
                  const Icon(
                    Icons.notifications_none,
                    color: Colors.white,
                    size: 36,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'CAPYADOO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ],
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
            itemCount: 14, // Show 2 weeks
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
                  _loadData();
                }
              }

              return GestureDetector(
                onTap: () async {
                  // index==0 เป็นปุ่มเปิดปฏิทิน (ไม่ใช่เลือกวัน)
                  if (index == 0) {
                    await openCalendar();
                    return;
                  }
                  setState(() {
                    _selectedDate = date;
                  });
                  _loadData();
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
                                  ? Colors.blue[800]
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
          // Top Buttons
          Row(
            children: [
              Expanded(
                child: _buildTopButton(
                  'กล่องยา',
                  Icons.shopping_bag_outlined,
                  const Color(0xFFE3F2FD),
                  const Color(0xFF2196F3),
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PillBoxListPage()),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTopButton(
                  'ผู้ดูแล',
                  Icons.people_outline,
                  const Color(0xFFE3F2FD),
                  const Color(0xFF2196F3),
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CareManagementPage(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else ...[
            _buildTimeSection(
              'เช้า',
              '${_getFilteredSchedule("morning").length} รายการ',
              const Color(0xFFFFF9C4),
              const Color(0xFFFBC02D),
              Icons.wb_sunny_outlined,
              _getFilteredSchedule('morning'),
            ),
            const SizedBox(height: 16),
            _buildTimeSection(
              'กลางวัน',
              '${_getFilteredSchedule("afternoon").length} รายการ',
              const Color(0xFFFFE0B2),
              const Color(0xFFF57C00),
              Icons.wb_sunny,
              _getFilteredSchedule('afternoon'),
            ),
            const SizedBox(height: 16),
            _buildTimeSection(
              'เย็น',
              '${_getFilteredSchedule("evening").length} รายการ',
              const Color(0xFFE1F5FE),
              const Color(0xFF0288D1),
              Icons.cloud_outlined,
              _getFilteredSchedule('evening'),
            ),
            const SizedBox(height: 16),
            _buildTimeSection(
              'ก่อนนอน',
              '${_getFilteredSchedule("night").length} รายการ',
              const Color(0xFFEDE7F6),
              const Color(0xFF673AB7),
              Icons.nightlight_round_outlined,
              _getFilteredSchedule('night'),
            ),
          ],
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSection(
    String title,
    String count,
    Color bgColor,
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
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    '$totalCount รายการ',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
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
                    color: Colors.grey[400],
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ไม่มีในรายการช่วงนี้',
                    style: TextStyle(color: Colors.grey[400]),
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
    print('_getBoxesForPeriod called with period: $period');
    print('Total boxes: ${_boxes.length}');

    final selectedDateOnly = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    bool isTimeInPeriod(String timeStr, String p) {
      // Accept "HH:mm:ss" or "HH:mm"
      if (timeStr.isEmpty) return false;
      final parts = timeStr.split(':');
      if (parts.length < 2) return false;
      final hour = int.tryParse(parts[0]) ?? -1;
      if (hour < 0) return false;

      switch (p) {
        case 'MORNING': // 05:00 - 10:59
          return hour >= 5 && hour < 11;
        case 'NOON': // 11:00 - 15:59
          return hour >= 11 && hour < 16;
        case 'EVENING': // 16:00 - 20:59
          return hour >= 16 && hour < 21;
        case 'BEDTIME': // 21:00 - 04:59 (cross midnight)
          return hour >= 21 || hour < 5;
        default:
          return false;
      }
    }

    for (final box in _boxes) {
      // ไม่แสดงกล่องถ้าวันที่เลือกอยู่ก่อนวันที่สร้างกล่อง (แสดงเฉพาะตั้งแต่วันที่สร้างเป็นต้นไป)
      if (box.createdAt != null) {
        final createdDateOnly = DateTime(
          box.createdAt!.year,
          box.createdAt!.month,
          box.createdAt!.day,
        );
        if (selectedDateOnly.isBefore(createdDateOnly)) continue;
      }

      // แสดงกล่องในทุกช่วงที่กล่องถูกตั้งค่าไว้ (เช้า/กลางวัน/เย็น/ก่อนนอน)
      if (box.id != null && box.intakePeriods.contains(period)) {
        print('Box ${box.name} matches period $period');
        final dailyMeds = _boxDailyMedications[box.id] ?? [];
        print('Daily medications for ${box.name}: ${dailyMeds.length}');

        // แปลง response จาก API ให้ตรงกับ format ที่โค้ดใช้
        // API ส่ง: { id, medication: { name }, intakeTime, status }
        // โค้ดต้องการ: { id, medicationName, scheduledTime, status }
        // กรองเฉพาะรายการที่อยู่ในช่วงเวลานี้ โดยดูจาก intakeTime ที่ backend ส่งมา
        final seenKeys = <String>{};
        final convertedMeds = <Map<String, dynamic>>[];
        for (final med in dailyMeds) {
          final medicationObj = med['medication'] as Map<String, dynamic>?;
          final medId =
              medicationObj?['id']?.toString() ??
              med['medicationId']?.toString() ??
              '';
          final medicationName =
              medicationObj?['name'] as String? ??
              med['medicationName'] as String? ??
              'ไม่ระบุชื่อ';

          final intakeTime =
              med['intakeTime'] as String? ??
              med['scheduledTime'] as String? ??
              _getDefaultTimeForPeriod(period);
          if (!isTimeInPeriod(intakeTime, period)) {
            continue;
          }
          final scheduledTime = _formatTime(intakeTime);
          final status = med['status'] as String? ?? 'PENDING';
          final intakeId = med['id'] as String? ?? '';

          // Unique per (med + time) so a medication can appear in multiple periods,
          // but not duplicated within the same period.
          final dedupKey =
              '${medId.isNotEmpty ? medId : medicationName}|$scheduledTime';
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

        // ถ้ามี daily medications ให้แสดง
        if (convertedMeds.isNotEmpty) {
          print(
            'Adding box ${box.name} with ${convertedMeds.length} medications',
          );
          result.add({'box': box, 'medications': convertedMeds});
        } else if (box.medications.isNotEmpty) {
          // ถ้าไม่มี daily medications แต่มี medications ใน box ให้ใช้ข้อมูลจาก box
          print('Using box medications for ${box.name}');
          final boxMeds = box.medications.map((med) {
            return {
              'id': med['id'] ?? '',
              'medicationName': med['name'] ?? 'ไม่ระบุชื่อ',
              'dosage': med['dosage'] ?? med['quantity'] ?? 1,
              'unit': med['unit'] ?? 'เม็ด',
              'status': 'PENDING',
              'scheduledTime': _getDefaultTimeForPeriod(period),
            };
          }).toList();
          result.add({'box': box, 'medications': boxMeds});
        } else {
          print('Box ${box.name} has no medications to display');
        }
      } else {
        if (box.id == null) {
          print('Box ${box.name} has no id');
        } else if (!box.intakePeriods.contains(period)) {
          print(
            'Box ${box.name} does not match period $period (has: ${box.intakePeriods})',
          );
        }
      }
    }
    print(
      '_getBoxesForPeriod returning ${result.length} boxes for period $period',
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
        allStatuses.every((s) => s.toUpperCase() == 'TAKEN');
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

    final mealTimingText = _mealTimingLabel(box.intakeTiming);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PillBoxDetailPage(pillBox: box)),
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
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    image: box.imagePath != null && box.imagePath!.isNotEmpty
                        ? DecorationImage(
                            image: box.imagePath!.startsWith('http')
                                ? NetworkImage(box.imagePath!)
                                : FileImage(File(box.imagePath!))
                                      as ImageProvider,
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: box.imagePath == null || box.imagePath!.isEmpty
                      ? const Icon(
                          Icons.inventory_2_outlined,
                          size: 20,
                          color: Colors.blue,
                        )
                      : null,
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
                const Icon(Icons.chevron_right, color: Colors.grey, size: 24),
              ],
            ),
            const SizedBox(height: 12),
            // List medications in box
            ...medications.map((med) {
              final medName = med['medicationName'] as String? ?? 'ไม่ระบุชื่อ';
              final medDosage = med['dosage'] as num?;
              final medUnit = med['unit'] as String? ?? 'เม็ด';
              final medStatus = med['status'] as String? ?? 'PENDING';
              final isMedTaken = medStatus == 'TAKEN';
              // ใช้ dosage ถ้ามี ไม่เช่นนั้นใช้ 1 เม็ด
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
                          decoration: isMedTaken
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                    if (isMedTaken)
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green,
                      ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  mealTimingText.isNotEmpty
                      ? mealTimingText
                      : '${formattedTime.substring(0, formattedTime.length > 5 ? 5 : formattedTime.length)} น.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const Spacer(),
                if (isTaken)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.cancel_outlined,
                          color: Colors.white,
                          size: 18,
                        ),
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
                else if (isOverdue)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'เกินกำหนด',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: () => _markWholeBoxAsTaken(box, period),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: const Text(
                      'ยืนยันการทาน',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ],
        ),
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

  /// ยืนยันการทานยาทั้งกล่องของช่วงนั้นเท่านั้น (กดเช้า = มาร์กเฉพาะเช้า ไม่มาร์กกลางวัน/เย็น/ก่อนนอน)
  Future<void> _markWholeBoxAsTaken(MedicationBox box, String period) async {
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
            content: Text('บันทึกการทาน ${box.name} เรียบร้อยแล้ว'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        // อัพเดทเฉพาะ intake ของกล่องนี้ใน period นี้ ไม่ต้อง reload ทั้งหน้า
        if (box.id != null) {
          final dailyMeds = _boxDailyMedications[box.id] ?? [];
          final updatedMeds = dailyMeds.map((med) {
            // ตรวจสอบว่า intake นี้อยู่ใน period นี้หรือไม่
            final intakeTime =
                med['intakeTime'] as String? ??
                med['scheduledTime'] as String? ??
                '';
            if (intakeTime.isNotEmpty) {
              final timeParts = intakeTime.split(':');
              if (timeParts.length >= 2) {
                final hour = int.tryParse(timeParts[0]) ?? 0;
                bool isInPeriod = false;
                switch (period) {
                  case 'MORNING':
                    isInPeriod = hour >= 5 && hour < 11;
                    break;
                  case 'NOON':
                    isInPeriod = hour >= 11 && hour < 16;
                    break;
                  case 'EVENING':
                    isInPeriod = hour >= 16 && hour < 21;
                    break;
                  case 'BEDTIME':
                    isInPeriod = hour >= 21 || hour < 5;
                    break;
                }
                if (isInPeriod) {
                  // อัพเดทสถานะเป็น TAKEN
                  final updated = Map<String, dynamic>.from(med);
                  updated['status'] = 'TAKEN';
                  return updated;
                }
              }
            }
            return med;
          }).toList();

          setState(() {
            _boxDailyMedications[box.id!] = updatedMeds;
          });
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ไม่สามารถบันทึกข้อมูลได้'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildMedicationCard(DailyIntake item) {
    final bool isTaken = item.status == IntakeStatus.TAKEN;
    final bool isNotTaken = item.status == IntakeStatus.NOT_TAKEN;
    final bool isMissed = item.status == IntakeStatus.MISSED;

    // Check if overdue: only for today and only if time has passed and status is PENDING
    // Don't mark as overdue if already TAKEN or NOT_TAKEN
    final bool isOverdue =
        !isTaken &&
        !isNotTaken &&
        (item.status == IntakeStatus.OVERDUE ||
            item.status == IntakeStatus.MISSED ||
            (_isTimePassedForSelectedDate(item.time) &&
                item.status == IntakeStatus.PENDING));

    final bool isLowQuantity =
        item.remainingQuantity != null && item.remainingQuantity! < 7;

    // (เดิมเคยใช้ตรวจ intakeId แบบ UUID แต่ตอนนี้ Pending ต้องแสดงปุ่มยืนยันเสมอ)

    final hasImage = item.imagePath != null && item.imagePath!.isNotEmpty;

    return Container(
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
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              image: hasImage
                  ? DecorationImage(
                      image: item.imagePath!.startsWith('http')
                          ? NetworkImage(item.imagePath!)
                          : FileImage(File(item.imagePath!)) as ImageProvider,
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: hasImage
                ? null
                : const Icon(
                    Icons.medication_outlined,
                    color: Colors.blue,
                    size: 22,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.medicationName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),

                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      _mealTimingLabel(item.intakeTiming).isNotEmpty
                          ? _mealTimingLabel(item.intakeTiming)
                          : '${item.time.substring(0, 5)} น.',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
                if (item.remainingQuantity != null) ...[
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
          else if (isOverdue)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'เกินกำหนด',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            ElevatedButton(
              onPressed: () => _markAsTakenSmart(item),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: const Text(
                'ยืนยันการทาน',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
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
    return _schedule.where((item) {
      // Prefer filtering by logical periodKey (MORNING/NOON/EVENING/BEDTIME)
      // so that "ก่อนนอน" won't move to "เย็น" even if intakeTiming shifts time (e.g., 20:30).
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

      // Fallback to time-based filtering (older data without periodKey)
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
}
