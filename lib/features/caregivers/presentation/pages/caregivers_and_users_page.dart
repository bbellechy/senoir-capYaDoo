import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:capyadoo/core/model/care_models.dart';
import 'package:capyadoo/core/config/api_config.dart';
import 'package:capyadoo/core/services/care_service.dart';
import 'package:capyadoo/features/care/presentation/pages/patient_detail_page.dart';
import 'package:capyadoo/features/caregivers/presentation/widgets/caregiver_request_card.dart';
import 'package:capyadoo/features/caregivers/presentation/widgets/caregiver_card.dart';
import 'package:capyadoo/features/caregivers/presentation/widgets/user_request_card.dart';
import 'package:capyadoo/features/caregivers/presentation/widgets/patient_card.dart';
import '../widgets/role_section.dart';
import '../widgets/add_username_section.dart';
import '../widgets/empty_state_widget.dart';

class CaregiversAndUsersPage extends StatefulWidget {
  const CaregiversAndUsersPage({super.key});

  @override
  State<CaregiversAndUsersPage> createState() => _CaregiversAndUsersPageState();
}

class _CaregiversAndUsersPageState extends State<CaregiversAndUsersPage> {
  // บทบาท
  bool isCaregiver = false;
  bool isUser = true;

  // ข้อมูล caregivers (สำหรับผู้ใช้งาน)
  List<Map<String, String>> caregiverRequests = [];
  List<Map<String, String>> acceptedCaregivers = [];

  // ข้อมูล patients (สำหรับผู้ดูแล)
  List<SentCareRequest> patientRequests = [];
  List<Patient> acceptedPatients = [];
  bool _isLoadingPatients = false;

  // Controller สำหรับค้นหา username
  final TextEditingController usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Auto-detect caregiver mode from backend data (patients / sent-requests)
    // so the screen can show data even if the toggle wasn't pressed.
    _bootstrapCaregiverMode();
  }

  Future<void> _bootstrapCaregiverMode() async {
    // Try to fetch caregiver-related data regardless of current isCaregiver flag.
    // If backend returns data, we enable caregiver mode automatically.
    try {
      setState(() => _isLoadingPatients = true);
      List<Patient> patients = [];
      List<SentCareRequest> sent = [];

      try {
        patients = await CareService.getPatients();
      } catch (e) {
        print('bootstrap: getPatients error: $e');
      }
      try {
        sent = await CareService.getSentCareRequests();
      } catch (e) {
        print('bootstrap: getSentCareRequests error: $e');
      }

      print(
        'bootstrap fetched: patients=${patients.length}, sent=${sent.length}',
      );

      if (!mounted) return;
      setState(() {
        acceptedPatients = patients;
        patientRequests = sent;
        // If backend has caregiver-related data, enable caregiver UI.
        if (patients.isNotEmpty || sent.isNotEmpty) {
          isCaregiver = true;
        }
        _isLoadingPatients = false;
      });
      print(
        'bootstrap applied: isCaregiver=$isCaregiver, acceptedPatients=${acceptedPatients.length}, patientRequests=${patientRequests.length}',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingPatients = false);
      print('Error bootstrapping caregiver mode: $e');
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    if (!isCaregiver) return;
    setState(() => _isLoadingPatients = true);
    try {
      final patients = await CareService.getPatients();
      if (mounted) {
        setState(() {
          acceptedPatients = patients;
          _isLoadingPatients = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPatients = false);
      }
      print('Error loading patients: $e');
    }
  }

  void _addCaregiverRole() {
    setState(() {
      isCaregiver = true;
    });
    _loadPatients();
    _loadSentRequests();
  }

  Future<void> _loadSentRequests() async {
    if (!isCaregiver) return;
    try {
      final sent = await CareService.getSentCareRequests();
      if (mounted) {
        setState(() {
          patientRequests = sent;
        });
      }
    } catch (e) {
      print('Error loading sent requests: $e');
    }
  }

  Future<void> _searchUser() async {
    final username = usernameController.text.trim();
    if (username.isEmpty) {
      _showSnackBar('กรุณากรอก Username');
      return;
    }

    final ok = await CareService.sendCareRequest(username);
    if (ok) {
      if (mounted) {
        setState(() {
          usernameController.clear();
        });
      }
      await _loadSentRequests();
      _showSnackBar('ส่งคำขอไปยัง $username แล้ว');
    } else {
      _showSnackBar('ส่งคำขอไม่สำเร็จ');
    }
  }

  // NOTE: backend ยังไม่มี endpoint ยกเลิกคำขอ (cancel) จึงแสดงเป็นรายการอย่างเดียว

  void _acceptCaregiverRequest(int index) {
    setState(() {
      final request = caregiverRequests.removeAt(index);
      acceptedCaregivers.add(request);
    });
    _showSnackBar('ยอมรับคำขอแล้ว');
  }

  void _rejectCaregiverRequest(int index) {
    setState(() {
      caregiverRequests.removeAt(index);
    });
    _showSnackBar('ปฏิเสธคำขอแล้ว');
  }

  void _removeCaregiver(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'ยืนยันการลบ',
          style: TextStyle(fontFamily: 'Sarabun'),
        ),
        content: const Text(
          'คุณต้องการลบผู้ดูแลคนนี้ใช่หรือไม่?',
          style: TextStyle(fontFamily: 'Sarabun'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                acceptedCaregivers.removeAt(index);
              });
              Navigator.pop(context);
              _showSnackBar('ลบผู้ดูแลแล้ว');
            },
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
  }

  Future<void> _removePatient(int index) async {
    final patient = acceptedPatients[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'ยืนยันการลบ',
          style: TextStyle(fontFamily: 'Sarabun'),
        ),
        content: const Text(
          'คุณต้องการลบผู้ใช้งานคนนี้ใช่หรือไม่?',
          style: TextStyle(fontFamily: 'Sarabun'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await CareService.removePatient(patient.patientId);
        if (success && mounted) {
          setState(() {
            acceptedPatients.removeAt(index);
          });
          _showSnackBar('ลบผู้ใช้งานแล้ว');
        } else {
          _showSnackBar('เกิดข้อผิดพลาดในการลบ');
        }
      } catch (e) {
        _showSnackBar('เกิดข้อผิดพลาดในการลบ');
      }
    }
  }

  void _viewPatientData(Patient patient) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PatientDetailPage(patient: patient)),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Sarabun')),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showCareDebugInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'สถานะการเชื่อมต่อ',
          style: TextStyle(fontFamily: 'Sarabun'),
        ),
        content: Text(
          'baseUrl: ${ApiConfig.baseUrl}\n'
          'sent-requests: ${patientRequests.length}\n'
          'patients: ${acceptedPatients.length}\n'
          'loading: $_isLoadingPatients\n'
          'isCaregiver: $isCaregiver',
          style: const TextStyle(fontFamily: 'Sarabun'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasCaregiverData =
        patientRequests.isNotEmpty || acceptedPatients.isNotEmpty;
    final showCaregiverUi = isCaregiver || hasCaregiverData;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          if (kDebugMode)
            Container(
              width: double.infinity,
              color: Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                'DEBUG caregiver=$isCaregiver showUi=$showCaregiverUi '
                'loading=$_isLoadingPatients '
                'sent=${patientRequests.length} patients=${acceptedPatients.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          // Header
          Container(
            height: 120,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'ผู้ดูแลและผู้ใช้งาน',
                          style: TextStyle(
                            fontFamily: 'Sarabun',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        await _bootstrapCaregiverMode();
                        if (mounted) {
                          _showSnackBar(
                            'รีเฟรชแล้ว (sent=${patientRequests.length}, patients=${acceptedPatients.length})',
                          );
                        }
                      },
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      tooltip: 'รีเฟรช',
                    ),
                    IconButton(
                      onPressed: _showCareDebugInfo,
                      icon: const Icon(Icons.info_outline, color: Colors.white),
                      tooltip: 'ดูสถานะ',
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ส่วนบทบาทของคุณ
                      RoleSection(isCaregiver: isCaregiver),

                      const SizedBox(height: 24),

                      // ส่วนของผู้ใช้งาน - คำขอจากผู้ดูแล
                      if (caregiverRequests.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.noonIcon,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    color: AppColors.noonIcon,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'คำขอจากผู้ดูแล (${caregiverRequests.length})',
                                    style: const TextStyle(
                                      fontFamily: 'Sarabun',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ...caregiverRequests.asMap().entries.map((entry) {
                                final index = entry.key;
                                final request = entry.value;
                                return CaregiverRequestCard(
                                  name: request['name']!,
                                  username: request['username']!,
                                  onAccept: () =>
                                      _acceptCaregiverRequest(index),
                                  onReject: () =>
                                      _rejectCaregiverRequest(index),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // ส่วนของผู้ดูแล - เพิ่มผู้ใช้งาน
                      if (showCaregiverUi) ...[
                        AddUserSection(
                          controller: usernameController,
                          onSearch: _searchUser,
                        ),
                        const SizedBox(height: 24),
                      ],

                      // ส่วนของผู้ดูแล - คำขอที่ส่งไปแล้ว (รอดำเนินการ)
                      if (showCaregiverUi) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.noonIcon,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    color: AppColors.noonIcon,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'คำขอที่รอดำเนินการ (${patientRequests.length})',
                                    style: const TextStyle(
                                      fontFamily: 'Sarabun',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (patientRequests.isEmpty)
                                const Text(
                                  'ยังไม่มีคำขอที่ส่งไป',
                                  style: TextStyle(
                                    fontFamily: 'Sarabun',
                                    fontSize: 13,
                                    color: AppColors.textSub,
                                  ),
                                )
                              else
                                ...patientRequests.asMap().entries.map((entry) {
                                  final request = entry.value;
                                  return UserRequestCard(
                                    name: request.patientUsername.isNotEmpty
                                        ? request.patientUsername
                                        : 'ไม่ระบุชื่อ',
                                    username: request.patientUsername.isNotEmpty
                                        ? '@${request.patientUsername}'
                                        : '',
                                    isPending: true,
                                    onCancel: null,
                                  );
                                }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // ส่วนของผู้ใช้งาน - ถ้ายังไม่มีผู้ดูแล
                      // แสดงเฉพาะตอน "ยังไม่มีข้อมูลฝั่งผู้ดูแลเลยจริงๆ"
                      if (!showCaregiverUi && acceptedCaregivers.isEmpty) ...[
                        EmptyStateWidget(
                          icon: Icons.people_outline,
                          title: 'คุณยังไม่ได้เป็นผู้ดูแล',
                          subtitle: 'เพิ่มบทบาทผู้ดูแลเพื่อดูแลผู้ใช้งานคนอื่น',
                          buttonText: 'เพิ่มบทบาทผู้ดูแล',
                          onButtonPressed: _addCaregiverRole,
                        ),
                        const SizedBox(height: 24),
                      ],

                      // รายชื่อผู้ดูแล (สำหรับผู้ใช้งาน)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.blueBorder,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.people,
                                  color: AppColors.primaryBlue,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  acceptedCaregivers.isEmpty
                                      ? 'รายชื่อผู้ดูแล'
                                      : 'รายชื่อผู้ดูแล (${acceptedCaregivers.length} คน)',
                                  style: const TextStyle(
                                    fontFamily: 'Sarabun',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (acceptedCaregivers.isEmpty)
                              const EmptyStateWidget(
                                icon: Icons.person_outline,
                                title: 'ยังไม่มีผู้ดูแลในการดูแลคุณ',
                                subtitle:
                                    'เพิ่มผู้ดูแลโดยใช้ Username ของผู้ใช้งาน',
                                showBorder: false,
                              )
                            else
                              ...acceptedCaregivers.asMap().entries.map((
                                entry,
                              ) {
                                final index = entry.key;
                                final caregiver = entry.value;
                                return CaregiverCard(
                                  name: caregiver['name']!,
                                  username: caregiver['username']!,
                                  onDelete: () => _removeCaregiver(index),
                                );
                              }),
                          ],
                        ),
                      ),

                      // รายชื่อผู้ใช้งาน (สำหรับผู้ดูแล)
                      if (showCaregiverUi) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.blueBorder,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.people,
                                    color: AppColors.primaryBlue,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    acceptedPatients.isEmpty
                                        ? 'รายชื่อผู้ใช้งาน'
                                        : 'รายชื่อผู้ใช้งาน (${acceptedPatients.length} คน)',
                                    style: const TextStyle(
                                      fontFamily: 'Sarabun',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (_isLoadingPatients)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              else if (acceptedPatients.isEmpty)
                                const EmptyStateWidget(
                                  icon: Icons.person_outline,
                                  title: 'ยังไม่มีผู้ใช้งานในการดูแล',
                                  subtitle:
                                      'เพิ่มผู้ใช้งานโดยใช้ Username ของผู้ใช้งาน',
                                  showBorder: false,
                                )
                              else
                                ...acceptedPatients.asMap().entries.map((
                                  entry,
                                ) {
                                  final index = entry.key;
                                  final patient = entry.value;
                                  return PatientCard(
                                    name: patient.fullName,
                                    username: patient.username,
                                    onViewData: () => _viewPatientData(patient),
                                    onDelete: () => _removePatient(index),
                                  );
                                }),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
