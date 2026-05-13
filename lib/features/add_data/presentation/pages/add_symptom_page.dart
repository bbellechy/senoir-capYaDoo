import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:capyadoo/core/widgets/app_text_field.dart';
import 'package:capyadoo/core/widgets/app_date_picker.dart';
import 'package:capyadoo/core/widgets/app_button.dart';
import 'package:capyadoo/core/widgets/app_searchable_dropdown.dart';
import 'package:capyadoo/core/widgets/app_slider.dart';
import 'package:capyadoo/core/services/symptom_service.dart';
import 'package:capyadoo/core/services/auth_service.dart';
import 'package:capyadoo/core/model/symptom_record.dart';
import 'package:capyadoo/core/services/medication_service.dart';
import 'package:intl/intl.dart';

class AddSymptomPage extends StatefulWidget {
  final String? symptomId;
  const AddSymptomPage({super.key, this.symptomId});

  @override
  State<AddSymptomPage> createState() => _AddSymptomPageState();
}

class _AddSymptomPageState extends State<AddSymptomPage> {
  // Form controllers
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedMedicine;
  double _severityLevel = 5.0;
  List<String> _userMedicationNames = [];

  bool get _isEditMode => widget.symptomId != null;

  @override
  void initState() {
    super.initState();
    // Set default date and time to now
    _selectedDate = DateTime.now();
    _selectedTime = TimeOfDay.now();
    _loadUserMedications();
    _loadSymptomData();
  }

  Future<void> _loadSymptomData() async {
    if (widget.symptomId == null) return;

    try {
      final userId = (await AuthService.getProfile())?.id;
      if (userId == null) return;

      final symptoms = await SymptomService.getUserSymptoms(userId);
      final symptom = symptoms.firstWhere((s) => s.id == widget.symptomId);

      if (mounted) {
        setState(() {
          _selectedDate = DateTime.parse(symptom.date);
          final timeParts = symptom.time.split(':');
          _selectedTime = TimeOfDay(
            hour: int.parse(timeParts[0]),
            minute: int.parse(timeParts[1]),
          );
          _selectedMedicine = symptom.medicationName;
          _severityLevel = symptom.severityLevel.toDouble();
          _descriptionController.text = symptom.symptom ?? '';
        });
      }
    } catch (e) {
      print('Error loading symptom data: $e');
    }
  }

  Future<void> _loadUserMedications() async {
    final profile = await AuthService.getProfile();
    if (profile == null) return;
    final medications = await MedicationService.getUserMedications(profile.id);
    if (mounted) {
      setState(() {
        _userMedicationNames = medications.map((m) => m.name).toSet().toList();
      });
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryBlue,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = (date.year + 543).toString(); // Convert to Buddhist year
    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          Container(
            height: 160.h,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32.r),
                bottomRight: Radius.circular(32.r),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  Positioned(
                    right: -50.w,
                    top: -50.h,
                    child: Container(
                      width: 200.w,
                      height: 200.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -30.w,
                    bottom: -30.h,
                    child: Container(
                      width: 140.w,
                      height: 140.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                          left: 30.w,
                          right: 30.w,
                          bottom: 20.h,
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.arrow_back_ios,
                                color: Colors.white,
                                size: 24.sp,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Expanded(
                              child: Text(
                                _isEditMode
                                    ? 'แก้ไขบันทึกอาการ'
                                    : 'เพิ่มบันทึกอาการ',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 48.w,
                            ), // Balance the back button
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Form content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // วันที่
                  Text(
                    'วันที่',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Sarabun',
                    ),
                  ),
                  SizedBox(height: 8.h),
                  AppDatePicker(
                    hint: 'เลือกวันที่',
                    selectedDate: _selectedDate,
                    onDateSelected: (date) {
                      setState(() {
                        _selectedDate = date;
                      });
                    },
                  ),
                  SizedBox(height: 20.h),

                  // เวลา
                  Text(
                    'เวลา',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Sarabun',
                    ),
                  ),
                  SizedBox(height: 8.h),
                  InkWell(
                    onTap: () => _selectTime(context),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 14.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: AppColors.textSublest, width: 1.w),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time, color: AppColors.textSub, size: 24.sp),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: Text(
                              _selectedTime != null
                                  ? _formatTime(_selectedTime!)
                                  : 'เลือกเวลา',
                              style: TextStyle(
                                fontSize: 16.sp,
                                color: _selectedTime != null
                                    ? AppColors.textSub
                                    : AppColors.textSub,
                                fontFamily: 'Sarabun',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // ชื่อยา
                  AppSearchableDropdown<String>(
                    label: 'ชื่อยา',
                    hint: 'เลือกยาหรือค้นหาชื่อยา',
                    value: _selectedMedicine,
                    isRequired: true,
                    items: _userMedicationNames.map((name) {
                      return SearchableDropdownItem<String>(
                        value: name,
                        label: name,
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedMedicine = value;
                      });
                    },
                  ),
                  SizedBox(height: 20.h),

                  // ระดับความรุนแรง
                  AppSlider(
                    label: 'ระดับความรุนแรง',
                    value: _severityLevel,
                    min: 0,
                    max: 10,
                    divisions: 10,
                    minLabel: 'น้อย',
                    maxLabel: 'มาก',
                    isRequired: true,
                    onChanged: (value) {
                      setState(() {
                        _severityLevel = value;
                      });
                    },
                  ),
                  SizedBox(height: 20.h),

                  // รายละเอียดอาการ
                  Text(
                    'รายละเอียดอาการ',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Sarabun',
                    ),
                  ),
                  SizedBox(height: 8.h),
                  AppLongTextField(
                    controller: _descriptionController,
                    hint: 'กรอกรายละเอียดอาการ...',
                  ),
                  SizedBox(height: 32.h),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          text: 'ยกเลิก',
                          isOutlined: true,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: AppButton(
                          text: 'บันทึก',
                          isLoading: _isSubmitting,
                          onPressed: _submitForm,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isSubmitting = false;

  Future<void> _submitForm() async {
    if (_selectedMedicine == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            'กรุณาเลือกชื่อยา',
            style: TextStyle(fontFamily: 'Sarabun', fontSize: 14.sp),
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final profile = await AuthService.getProfile();
      if (profile == null) throw Exception('User not logged in');

      final dateStr = DateFormat(
        'yyyy-MM-dd',
      ).format(_selectedDate ?? DateTime.now());
      final timeStr =
          '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00';

      final record = SymptomRecord(
        date: dateStr,
        time: timeStr,
        medicationName: _selectedMedicine!,
        severityLevel: _severityLevel.toInt(),
        symptom: _descriptionController.text.trim(),
        userId: profile.id,
      );

      final result = widget.symptomId != null
          ? await SymptomService.updateSymptom(widget.symptomId!, record)
          : await SymptomService.createSymptom(record);

      if (result != null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(
            SnackBar(
              content: Text(
                'บันทึกอาการสำเร็จ',
                style: TextStyle(fontFamily: 'Sarabun', fontSize: 14.sp),
              ),
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('Failed to save symptom record');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(
              'เกิดข้อผิดพลาด: $e',
              style: TextStyle(fontFamily: 'Sarabun', fontSize: 14.sp),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
