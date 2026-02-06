import 'package:flutter/material.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
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
  List<Map<String, String>> patientRequests = [];
  List<Map<String, String>> acceptedPatients = [];

  // Controller สำหรับค้นหา username
  final TextEditingController usernameController = TextEditingController();

  @override
  void dispose() {
    usernameController.dispose();
    super.dispose();
  }

  void _addCaregiverRole() {
    setState(() {
      isCaregiver = true;
    });
  }

  void _searchUser() {
    final username = usernameController.text.trim();
    if (username.isEmpty) {
      _showSnackBar('กรุณากรอก Username');
      return;
    }

    // จำลองการส่งคำขอ
    setState(() {
      patientRequests.add({'name': username, 'username': '@$username'});
      usernameController.clear();
    });
    _showSnackBar('ส่งคำขอไปยัง $username แล้ว');
  }

  void _cancelRequest(int index) {
    setState(() {
      patientRequests.removeAt(index);
    });
    _showSnackBar('ยกเลิกคำขอแล้ว');
  }

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

  void _removePatient(int index) {
    showDialog(
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
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                acceptedPatients.removeAt(index);
              });
              Navigator.pop(context);
              _showSnackBar('ลบผู้ใช้งานแล้ว');
            },
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
  }

  void _viewPatientData(Map<String, String> patient) {
    // TODO: Navigate to patient data page
    _showSnackBar('ดูข้อมูลของ ${patient['name']}');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Sarabun')),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
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
                    const SizedBox(width: 48),
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
                      if (isCaregiver) ...[
                        AddUserSection(
                          controller: usernameController,
                          onSearch: _searchUser,
                        ),
                        const SizedBox(height: 24),
                      ],

                      // ส่วนของผู้ดูแล - คำขอที่รอดำเนินการ
                      if (isCaregiver && patientRequests.isNotEmpty) ...[
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
                              ...patientRequests.asMap().entries.map((entry) {
                                final index = entry.key;
                                final request = entry.value;
                                return UserRequestCard(
                                  name: request['name']!,
                                  username: request['username']!,
                                  isPending: true,
                                  onCancel: () => _cancelRequest(index),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // ส่วนของผู้ใช้งาน - ถ้ายังไม่มีผู้ดูแล
                      if (!isCaregiver && acceptedCaregivers.isEmpty) ...[
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
                      if (isCaregiver) ...[
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
                              if (acceptedPatients.isEmpty)
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
                                    name: patient['name']!,
                                    username: patient['username']!,
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
