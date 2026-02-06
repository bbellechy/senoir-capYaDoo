import 'package:flutter/material.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:capyadoo/core/widgets/app_input_text.dart';
import 'package:capyadoo/core/widgets/app_nav_bar.dart';
import 'package:capyadoo/core/services/page_navigation_service.dart';
import 'package:capyadoo/features/care/controller/care_controller.dart';
import 'package:capyadoo/core/model/care_models.dart';
import 'package:capyadoo/features/care/presentation/pages/patient_detail_page.dart';

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
    _controller.loadData();
    _controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _searchController.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _sendRequest() async {
    final username = _searchController.text.trim();
    if (username.isEmpty) return;

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

  void _onNavBarTap(int index) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    PageNavigationService().setIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      bottomNavigationBar: AppNavBar(
        currentIndex: 0,
        onTap: _onNavBarTap,
      ),
      body: Column(
        children: [
          // Blue header
          Container(
            height: 140,
            decoration: const BoxDecoration(color: AppColors.primaryBlue),
            child: SafeArea(
              bottom: false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 30,
                      right: 30,
                      bottom: 20,
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'ผู้ดูแลและผู้ใช้งาน',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Sarabun',
                            ),
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
                        if (_controller.requests.isNotEmpty)
                          _buildRequestsSection(),
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
                _isCaregiverView ? 'เพิ่มผู้ใช้งาน' : 'เพิ่มผู้ดูแล',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Username ของ${_isCaregiverView ? 'ผู้ใช้งาน' : 'ผู้ดูแล'}',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppInputText(
                  controller: _searchController,
                  hintText: 'กรอก Username',
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
                'คำขอที่รอดำเนินการ (${_controller.requests.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
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
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text(
                  'ต้องการเป็นผู้ดูแลของคุณ',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
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
    final title = _isCaregiverView ? 'รายชื่อผู้ใช้งาน' : 'รายชื่อผู้ดูแล';
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
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.group_off_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ยังไม่มี${_isCaregiverView ? 'ผู้ใช้งานใน' : 'ผู้ดูแล'}การดูแล',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
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
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '@${patient.username}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
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
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () {
              // Unlink logic (TBD)
            },
          ),
        ],
      ),
    );
  }
}
