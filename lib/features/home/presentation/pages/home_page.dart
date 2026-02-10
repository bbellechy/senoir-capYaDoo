import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:capyadoo/core/model/daily_intake.dart';
import 'package:capyadoo/core/services/medication_schedule_service.dart';
import 'package:capyadoo/core/model/user.dart';
import 'package:capyadoo/core/providers/auth_provider.dart';
import 'package:capyadoo/features/pillbox/presentation/pages/pill_box_list_page.dart';
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
    await Future.wait([
      _loadSchedule(showLoading: false),
      _loadBoxes(),
      _checkOverdueStatus(), // Check for late medications
    ]);
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
      final now = DateTime.now();
      // Only check for today
      if (DateFormat('yyyy-MM-dd').format(_selectedDate) !=
          DateFormat('yyyy-MM-dd').format(now)) {
        return;
      }

      bool hasChanges = false;
      for (final item in _schedule) {
        // Only check items with valid UUID intakeId (from backend)
        if (item.status == IntakeStatus.PENDING &&
            !item.intakeId.contains('_') &&
            item.intakeId.isNotEmpty) {
          final timeParts = item.time.split(':');
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

            // If current time has passed the scheduled time, mark as overdue
            if (now.isAfter(scheduleTime)) {
              await MedicationScheduleService.markAsOverdue(item.intakeId);
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
      }
      _loadSchedule(showLoading: false);
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

    // ถ้ายัง resolve ไม่ได้ ให้แจ้งผู้ใช้ และรีเฟรชตารางอีกครั้ง
    if (intakeId.contains('_')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ระบบยังไม่สร้างรายการวันนี้ กรุณาลองใหม่อีกครั้ง'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      _loadSchedule(showLoading: false);
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
          Column(
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
              ),
            ],
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

              return GestureDetector(
                onTap: () {
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
                            Icons.calendar_today,
                            color: Colors.blue,
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

    for (final box in _boxes) {
      if (box.id != null && box.intakePeriods.contains(period)) {
        print('Box ${box.name} matches period $period');
        final dailyMeds = _boxDailyMedications[box.id] ?? [];
        print('Daily medications for ${box.name}: ${dailyMeds.length}');

        // แปลง response จาก API ให้ตรงกับ format ที่โค้ดใช้
        // API ส่ง: { id, medication: { name }, intakeTime, status }
        // โค้ดต้องการ: { id, medicationName, scheduledTime, status }
        final convertedMeds = dailyMeds.map((med) {
          // ดึง medication name จาก medication object
          final medicationObj = med['medication'] as Map<String, dynamic>?;
          final medicationName =
              medicationObj?['name'] as String? ??
              med['medicationName'] as String? ??
              'ไม่ระบุชื่อ';

          // ดึง intakeTime และแปลงเป็น scheduledTime (HH:mm)
          final intakeTime =
              med['intakeTime'] as String? ??
              med['scheduledTime'] as String? ??
              _getDefaultTimeForPeriod(period);
          final scheduledTime = _formatTime(intakeTime);

          // ดึง status
          final status = med['status'] as String? ?? 'PENDING';

          // ดึง id (intakeId)
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
        return '22:00';
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
    final intakeId = firstMed?['id'] as String? ?? '';
    final status = firstMed?['status'] as String? ?? 'PENDING';

    final isTaken = status == 'TAKEN';
    final isNotTaken = status == 'NOT_TAKEN';
    final isMissed = status == 'MISSED';
    final isOverdue =
        status == 'OVERDUE' ||
        (status == 'PENDING' && _isTimePassedForSelectedDate(formattedTime));

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
              const CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, size: 16, color: Colors.white),
              ),
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
                '${formattedTime.substring(0, formattedTime.length > 5 ? 5 : formattedTime.length)} น.',
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
              else
                ElevatedButton(
                  onPressed: isOverdue
                      ? null
                      : () => _markBoxAsTaken(intakeId, box.name),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isOverdue
                        ? Colors.red
                        : const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: Text(
                    isOverdue ? 'เกินกำหนด' : 'ยืนยันการทาน',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _markBoxAsTaken(String intakeId, String boxName) async {
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
            content: Text('บันทึกการทาน $boxName เรียบร้อยแล้ว'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      _loadData();
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
                      '${item.time.substring(0, 5)} น.',
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
          else
            ElevatedButton(
              // Pending = ปุ่มฟ้า "ยืนยันการทาน"
              // ถ้าเลยเวลา = แดง "เกินกำหนด" และปิดกด
              onPressed: isOverdue ? null : () => _markAsTakenSmart(item),
              style: ElevatedButton.styleFrom(
                // Pending = ปุ่มสีฟ้า "ยืนยันการทาน"
                // ถ้าเลยเวลา/เกินกำหนด = สีแดง
                backgroundColor: isOverdue
                    ? Colors.red
                    : const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: Text(
                isOverdue ? 'เกินกำหนด' : 'ยืนยันการทาน',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  // Check if the scheduled time has passed
  // Check if time has passed for the selected date (not today)
  bool _isTimePassedForSelectedDate(String time) {
    try {
      final now = DateTime.now();
      final selectedDateOnly = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );
      final todayOnly = DateTime(now.year, now.month, now.day);

      // Only check overdue if selected date is today
      if (selectedDateOnly != todayOnly) {
        return false;
      }

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
