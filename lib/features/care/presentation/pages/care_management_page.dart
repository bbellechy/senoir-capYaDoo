import 'package:flutter/material.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:capyadoo/core/widgets/app_input_text.dart';
import 'package:capyadoo/features/care/controller/care_controller.dart';
import 'package:capyadoo/core/model/care_models.dart';
import 'package:capyadoo/core/services/care_service.dart';
import 'package:capyadoo/features/care/presentation/pages/patient_detail_page.dart';
import 'package:capyadoo/core/services/page_navigation_service.dart';
import 'package:capyadoo/core/widgets/app_empty_card.dart';

class CareManagementPage extends StatefulWidget {
  const CareManagementPage({super.key});

  @override
  State<CareManagementPage> createState() => _CareManagementPageState();
}

class _CareManagementPageState extends State<CareManagementPage> {
  final CareController _controller = CareController();
  final TextEditingController _searchController = TextEditingController();
  final bool _isCaregiverView = true;

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to avoid triggering rebuilds during an ongoing build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PageNavigationService().setCaregiverMode(true);
    });
    _controller.loadData();
    _controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    // Similarly for dispose, ensure we don't trigger updates during a build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PageNavigationService().setCaregiverMode(false);
    });
    _controller.removeListener(_onControllerUpdate);
    _searchController.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _removePatient(Patient patient) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text(
          'คุณต้องการลบ ${patient.fullName} ออกจากรายการผู้ดูแลใช่หรือไม่?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await CareService.removePatient(patient.patientId);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ลบผู้ดูแลเรียบร้อยแล้ว')),
          );
          _controller.loadData();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ไม่สามารถลบผู้ดูแลได้'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _sendRequest() async {
    final username = _searchController.text.trim();
    if (username.isEmpty) return;

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการเพิ่มผู้ดูแล'),
        content: Text(
          'คุณต้องการเพิ่ม $username เป็น${_isCaregiverView ? 'ผู้ดูแล' : 'ผู้ดูแล'}ใช่หรือไม่?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'ยืนยัน',
              style: TextStyle(color: AppColors.primaryBlue),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await _controller.sendRequest(username);
    if (success) {
      _searchController.clear();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ส่งคำขอเรียบร้อยแล้ว')));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ไม่พบผู้ใช้งานหรือเกิดข้อผิดพลาด'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      body: Column(
        children: [
          // Premium Caregiver Header
          Container(
            height: 220,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
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
                  Positioned(
                    left: 8,
                    top: 0,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.supervisor_account_rounded,
                          color: Colors.white70,
                          size: 48,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'ผู้ดูแลและผู้ใช้งาน',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Sarabun',
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Main Content
          Expanded(
            child: _controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAddSection(),
                        const SizedBox(height: 16),
                        if (_controller.sentRequests.isNotEmpty)
                          _buildSentRequestsSection(),
                        if (_controller.sentRequests.isNotEmpty)
                          const SizedBox(height: 16),
                        if (_controller.requests.isNotEmpty)
                          _buildRequestsSection(),
                        if (_controller.requests.isNotEmpty)
                          const SizedBox(height: 16),
                        _buildListSection(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
              Icon(
                _isCaregiverView
                    ? Icons.person_add
                    : Icons.admin_panel_settings,
                color: _isCaregiverView
                    ? AppColors.success
                    : AppColors.primaryBlue,
              ),
              const SizedBox(width: 8),
              Text(
                _isCaregiverView ? 'เพิ่มผู้ใช้งานที่ต้องการดูแล' : 'เพิ่มผู้ดูแล',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          // const SizedBox(height: 4),
          // Text(
          //   'Username ของ${_isCaregiverView ? 'ผู้ใช้งานที่ต้องการดูแล' : 'ผู้ดูแล'}',
          //   style: TextStyle(color: Colors.grey[600], fontSize: 16),
          // ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppInputText(
                  controller: _searchController,
                  hintText: 'กรอก Username ที่ต้องการดูแล',
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _sendRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isCaregiverView
                        ? AppColors.success
                        : AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Icon(Icons.search, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSentRequestsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5), // Light orange background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.access_time,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'คำขอเป็นผู้ดูแล (${_controller.sentRequests.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_controller.sentRequests.isEmpty)
            Center(
              child: Text(
                'ไม่มีคำขอที่รอดำเนินการ',
                style: TextStyle(color: Colors.grey[600], fontSize: 18),
              ),
            )
          else
            ..._controller.sentRequests.map(
              (request) => _buildSentRequestCard(request),
            ),
        ],
      ),
    );
  }

  Widget _buildSentRequestCard(SentCareRequest request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.orange.withOpacity(0.2),
            child: const Icon(Icons.person, color: Colors.orange),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.patientUsername,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '@${request.patientUsername}',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                // Text(
                //   'รอการยอมรับจากผู้ใช้งาน...',
                //   style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                // ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('ยืนยันการยกเลิก'),
                    content: Text(
                      'คุณต้องการยกเลิกคำขอที่ส่งไปหา ${request.patientUsername} ใช่หรือไม่?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('ยกเลิก'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'ยืนยัน',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  final success = await _controller.cancelSentRequest(
                    request.id,
                  );
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ยกเลิกคำขอเรียบร้อยแล้ว')),
                    );
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('ไม่สามารถยกเลิกคำขอได้'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.close, size: 16, color: Colors.black),
              label: const Text(
                'ยกเลิก',
                style: TextStyle(color: Colors.black, fontSize: 12),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5), // Warning light background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                'คำขอต้องการเป็นผู้ดูแลของคุณ (${_controller.requests.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._controller.requests.map((req) => _buildRequestItem(req)),
        ],
      ),
    );
  }

  Widget _buildRequestItem(CareRequest req) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
            child: const Icon(Icons.person, color: AppColors.primaryBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  req.caregiverUsername,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const Text(
                  'ต้องการเป็นผู้ดูแลของคุณ',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _responseButton(
                'ตอบรับ',
                AppColors.success,
                () => _controller.respondToRequest(req.id, true),
              ),
              const SizedBox(width: 8),
              _responseButton(
                'ปฏิเสธ',
                AppColors.error,
                () => _controller.respondToRequest(req.id, false),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _responseButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildListSection() {
    final title = _isCaregiverView ? 'รายชื่อผู้ใช้งานที่กำลังดูแล' : 'รายชื่อผู้ดูแล';
    final items = _isCaregiverView
        ? _controller.patients
        : []; // Caregiver view only for now

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
              Icon(
                _isCaregiverView
                    ? Icons.people_outline
                    : Icons.admin_panel_settings_outlined,
                color: _isCaregiverView
                    ? AppColors.success
                    : AppColors.primaryBlue,
              ),
              const SizedBox(width: 8),
              Text(
                '$title (${items.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            AppEmptyCard(
              icon: Icons.group_off_outlined,
              title:
                  'ยังไม่มี${_isCaregiverView ? 'ผู้ใช้งานใน' : 'ผู้ดูแล'}การดูแล',
              subtitle:
                  'เชิญ${_isCaregiverView ? 'ผู้ใช้งาน' : 'ผู้ดูแล'}เพื่อดูข้อมูล',
            )
          else
            ...items.map((item) => _buildPatientItem(item as Patient)),
        ],
      ),
    );
  }

  Widget _buildPatientItem(Patient patient) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.success.withOpacity(0.1),
            child: const Icon(Icons.person, color: AppColors.success),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.fullName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  '@${patient.username}',
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PatientDetailPage(patient: patient),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'ดูข้อมูล',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () => _removePatient(patient),
          ),
        ],
      ),
    );
  }
}
