import 'package:flutter/material.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:capyadoo/core/model/care_models.dart';
import 'package:capyadoo/core/config/api_config.dart';
import 'package:capyadoo/features/caregivers/presentation/controller/care_controller.dart';
import 'package:capyadoo/features/caregivers/presentation/widgets/patient_detail_page.dart';
import 'package:capyadoo/features/caregivers/presentation/widgets/caregiver_request_card.dart';
import 'package:capyadoo/features/caregivers/presentation/widgets/user_request_card.dart';
import 'package:capyadoo/features/caregivers/presentation/widgets/patient_card.dart';
import '../widgets/role_section.dart';
import '../widgets/add_username_section.dart';
import '../widgets/empty_state_widget.dart';
import 'package:capyadoo/core/services/page_navigation_service.dart';
import 'package:capyadoo/core/widgets/app_empty_card.dart';
import 'package:capyadoo/core/widgets/delete_dialog.dart';

class CaregiversAndUsersPage extends StatefulWidget {
  const CaregiversAndUsersPage({super.key});

  @override
  State<CaregiversAndUsersPage> createState() => _CaregiversAndUsersPageState();
}

class _CaregiversAndUsersPageState extends State<CaregiversAndUsersPage> {
  final CareController _careController = CareController();

  // บทบาท
  bool isCaregiver = false;
  bool isUser = true;

  // ข้อมูล caregivers (สำหรับผู้ใช้งาน)
  List<CareRequest> caregiverRequests = [];

  // ข้อมูล patients (สำหรับผู้ดูแล)
  List<SentCareRequest> patientRequests = [];
  List<Patient> acceptedPatients = [];
  bool _isLoadingPatients = false;

  // Controller สำหรับค้นหา username
  final TextEditingController usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to avoid triggering rebuilds during an ongoing build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PageNavigationService().setCaregiverMode(true);
    });
    _loadAllCareData();
  }

  Future<void> _loadAllCareData() async {
    setState(() => _isLoadingPatients = true);
    await _careController.loadData();
    if (!mounted) return;

    setState(() {
      caregiverRequests = List<CareRequest>.from(_careController.requests);
      patientRequests = List<SentCareRequest>.from(
        _careController.sentRequests,
      );
      acceptedPatients = List<Patient>.from(_careController.patients);
      if (acceptedPatients.isNotEmpty || patientRequests.isNotEmpty) {
        isCaregiver = true;
      }
      _isLoadingPatients = _careController.isLoading;
    });
  }

  Future<void> _loadIncomingCareRequests() async {
    await _loadAllCareData();
  }

  Future<void> _bootstrapCaregiverMode() async {
    await _loadAllCareData();
  }

  @override
  void dispose() {
    // Similarly for dispose, ensure we don't trigger updates during a build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PageNavigationService().setCaregiverMode(false);
    });
    _careController.dispose();
    usernameController.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    if (!isCaregiver) return;
    await _loadAllCareData();
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
    await _loadAllCareData();
  }

  Future<void> _searchUser() async {
    final username = usernameController.text.trim();
    if (username.isEmpty) {
      _showSnackBar('กรุณากรอก Username');
      return;
    }

    final ok = await _careController.sendRequest(username);
    if (ok) {
      if (mounted) {
        setState(() {
          usernameController.clear();
          patientRequests = List<SentCareRequest>.from(
            _careController.sentRequests,
          );
          acceptedPatients = List<Patient>.from(_careController.patients);
          caregiverRequests = List<CareRequest>.from(_careController.requests);
        });
      }
      _showSnackBar('ส่งคำขอไปยัง $username แล้ว');
    } else {
      _showSnackBar('ส่งคำขอไม่สำเร็จ');
    }
  }

  // NOTE: backend ยังไม่มี endpoint ยกเลิกคำขอ (cancel) จึงแสดงเป็นรายการอย่างเดียว

  Future<void> _acceptCaregiverRequest(int index) async {
    final request = caregiverRequests[index];
    final success = await _careController.respondToRequest(request.id, true);
    if (!mounted) return;

    if (success) {
      setState(() {
        caregiverRequests = List<CareRequest>.from(_careController.requests);
        patientRequests = List<SentCareRequest>.from(
          _careController.sentRequests,
        );
        acceptedPatients = List<Patient>.from(_careController.patients);
      });
      _showSnackBar('ยอมรับคำขอแล้ว');
      return;
    }

    _showSnackBar('ไม่สามารถยอมรับคำขอได้');
  }

  Future<void> _rejectCaregiverRequest(int index) async {
    final request = caregiverRequests[index];
    final success = await _careController.respondToRequest(request.id, false);
    if (!mounted) return;

    if (success) {
      setState(() {
        caregiverRequests = List<CareRequest>.from(_careController.requests);
        patientRequests = List<SentCareRequest>.from(
          _careController.sentRequests,
        );
        acceptedPatients = List<Patient>.from(_careController.patients);
      });
      _showSnackBar('ปฏิเสธคำขอแล้ว');
      return;
    }

    _showSnackBar('ไม่สามารถปฏิเสธคำขอได้');
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
        final success = await _careController.removePatient(patient.patientId);
        if (success && mounted) {
          setState(() {
            caregiverRequests = List<CareRequest>.from(
              _careController.requests,
            );
            patientRequests = List<SentCareRequest>.from(
              _careController.sentRequests,
            );
            acceptedPatients = List<Patient>.from(_careController.patients);
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

  Future<void> _cancelSentRequest(int index) async {
    final request = patientRequests[index];
    final confirmed = await showDeleteDialog(
      context,
      title: 'ยืนยันการยกเลิก',
      message:
          'คุณต้องการยกเลิกคำขอที่ส่งไปหา ${request.patientUsername} ใช่หรือไม่?',
      confirmText: 'ยืนยัน',
    );

    if (confirmed != true) return;

    try {
      final success = await _careController.cancelSentRequest(request.id);
      if (!mounted) return;

      if (success) {
        setState(() {
          caregiverRequests = List<CareRequest>.from(_careController.requests);
          patientRequests = List<SentCareRequest>.from(
            _careController.sentRequests,
          );
          acceptedPatients = List<Patient>.from(_careController.patients);
        });
        _showSnackBar('ยกเลิกคำขอเรียบร้อยแล้ว');
      } else {
        _showSnackBar('ไม่สามารถยกเลิกคำขอได้');
      }
    } catch (e) {
      _showSnackBar('ไม่สามารถยกเลิกคำขอได้');
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
      backgroundColor: const Color(0xFFF8FAF8),
      body: Column(
        children: [
          // Premium Caregiver Header
          Container(
            height: 160,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  // Decorative Circles (Green tint)
                  Positioned(
                    right: -50,
                    top: -50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -30,
                    bottom: -30,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 48),
                            child: Text(
                              'ผู้ดูแลและผู้ใช้งาน',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Sarabun',
                                letterSpacing: 0.4,
                                height: 1.15,
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(
                                Icons.arrow_back_ios,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
                                  name: request.caregiverUsername,
                                  username: request.caregiverUsername,
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

                      // ส่วนของผู้ดูแล - คำขอที่ส่งไปแล้ว (รอดำเนินการ)
                      if (showCaregiverUi && patientRequests.isNotEmpty) ...[
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
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ...patientRequests.asMap().entries.map((entry) {
                                final index = entry.key;
                                final request = entry.value;
                                return UserRequestCard(
                                  name: request.patientUsername.isNotEmpty
                                      ? request.patientUsername
                                      : 'ไม่ระบุชื่อ',
                                  username: request.patientUsername.isNotEmpty
                                      ? '@${request.patientUsername}'
                                      : '',
                                  isPending: true,
                                  onCancel: () => _cancelSentRequest(index),
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
                                      fontSize: 20,
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
                                AppEmptyCard(
                                  icon: Icons.person_outline,
                                  title: 'ยังไม่มีผู้ใช้งานในการดูแล',
                                  subtitle:
                                      'เพิ่มผู้ใช้งานโดยใช้ Username ของผู้ใช้งาน',
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
                        const SizedBox(height: 24),
                      ],

                      // ส่วนของผู้ใช้งาน - ถ้ายังไม่มีผู้ดูแล
                      // แสดงเฉพาะตอน "ยังไม่มีข้อมูลฝั่งผู้ดูแลเลยจริงๆ"
                      if (!showCaregiverUi) ...[
                        EmptyStateWidget(
                          icon: Icons.people_outline,
                          title: 'คุณยังไม่ได้เป็นผู้ดูแล',
                          subtitle: 'เพิ่มบทบาทผู้ดูแลเพื่อดูแลผู้ใช้งานคนอื่น',
                          buttonText: 'เพิ่มบทบาทผู้ดูแล',
                          onButtonPressed: _addCaregiverRole,
                        ),
                        const SizedBox(height: 24),
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
