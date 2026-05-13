import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../../core/model/medication.dart';
import '../../../../core/constants/app_colors.dart';

class MedicationDetailPage extends StatefulWidget {
  final Medication medication;

  const MedicationDetailPage({super.key, required this.medication});

  @override
  State<MedicationDetailPage> createState() => _MedicationDetailPageState();
}

class _MedicationDetailPageState extends State<MedicationDetailPage> {
  final FlutterTts flutterTts = FlutterTts();
  bool isPlaying = false;
  String currentSection = '';

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await flutterTts.setLanguage("th-TH");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);

    flutterTts.setCompletionHandler(() {
      setState(() {
        isPlaying = false;
        currentSection = '';
      });
    });
  }

  Future<void> _speak(String text, String section) async {
    if (isPlaying && currentSection == section) {
      await flutterTts.stop();
      setState(() {
        isPlaying = false;
        currentSection = '';
      });
    } else {
      await flutterTts.stop();
      setState(() {
        isPlaying = true;
        currentSection = section;
      });
      await flutterTts.speak(text);
    }
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  bool _isValidValue(String? value) {
    return value != null && value.trim().isNotEmpty && value.trim() != '-';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offwhite,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primaryBlue,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 24.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'รายละเอียดยา',
          style: TextStyle(
            color: Colors.white,
            fontSize: 36.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24.r),
                  bottomRight: Radius.circular(24.r),
                ),
              ),
              padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 32.h),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10.r,
                          offset: Offset(0, 4.h),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.medication,
                      size: 36.sp,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    widget.medication.tradenameTh ?? '-',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    widget.medication.tradenameEn ?? '-',
                    style: TextStyle(
                      fontSize: 20.sp,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Content Section
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Column(
                children: [
                  _buildInfoCard(
                    title: 'คำอธิบาย',
                    icon: Icons.description_outlined,
                    content: widget.medication.indication ?? "-",
                    section: 'indication',
                  ),
                  SizedBox(height: 12.h),
                  _buildInfoCard(
                    title: 'การใช้ประโยชน์',
                    icon: Icons.integration_instructions_outlined,
                    content: widget.medication.categoryUse ?? "-",
                    section: 'categoryUse',
                  ),
                  if (_isValidValue(widget.medication.basicDoseForm)) ...[
                    SizedBox(height: 12.h),
                    _buildInfoCard(
                      title: 'รูปแบบยา (Basic)',
                      icon: Icons.medication_liquid_outlined,
                      content: widget.medication.basicDoseForm!,
                      section: 'basicDoseForm',
                    ),
                  ],
                  if (_isValidValue(widget.medication.doseFormTh)) ...[
                    SizedBox(height: 12.h),
                    _buildInfoCard(
                      title: 'รูปแบบยา (ไทย)',
                      icon: Icons.medication_liquid_outlined,
                      content: widget.medication.doseFormTh!,
                      section: 'doseFormTh',
                    ),
                  ],
                  if (_isValidValue(widget.medication.doseFormEn)) ...[
                    SizedBox(height: 12.h),
                    _buildInfoCard(
                      title: 'รูปแบบยา (อังกฤษ)',
                      icon: Icons.medication_liquid_outlined,
                      content: widget.medication.doseFormEn!,
                      section: 'doseFormEn',
                    ),
                  ],
                  SizedBox(height: 12.h),
                  _buildInfoCard(
                    title: 'ประเภทกฎหมาย',
                    icon: Icons.gavel_outlined,
                    content: widget.medication.legislationClass ?? "-",
                    section: 'legislationClass',
                  ),
                  SizedBox(height: 12.h),
                  _buildInfoCard(
                    title: 'วันที่อนุมัติ',
                    icon: Icons.calendar_today_outlined,
                    content: widget.medication.approvalDate ?? "-",
                    section: 'approvalDate',
                  ),
                  SizedBox(height: 12.h),
                  _buildInfoCard(
                    title: 'วันหมดอายุ',
                    icon: Icons.event_outlined,
                    content: widget.medication.validityDate ?? "-",
                    section: 'validityDate',
                  ),
                  SizedBox(height: 12.h),
                  _buildInfoCard(
                    title: 'ชื่อผู้ได้รับอนุญาต',
                    icon: Icons.business_outlined,
                    content: widget.medication.licenseeName ?? "-",
                    section: 'licenseeName',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required String content,
    required String section,
  }) {
    final bool isCurrentlyPlaying = isPlaying && currentSection == section;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.blueBorder, width: 1.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(icon, color: Colors.blue.shade600, size: 20.sp),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => _speak(content, section),
                  borderRadius: BorderRadius.circular(20.r),
                  child: Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: isCurrentlyPlaying
                          ? Colors.blue.shade100
                          : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCurrentlyPlaying ? Icons.stop : Icons.volume_up,
                      color: isCurrentlyPlaying
                          ? Colors.blue.shade700
                          : Colors.grey.shade700,
                      size: 20.sp,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.grey.shade200, width: 1.w),
              ),
              child: Text(
                content.isNotEmpty ? content : 'ไม่มีข้อมูล',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: content.isNotEmpty
                      ? Colors.grey.shade800
                      : Colors.grey.shade400,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
