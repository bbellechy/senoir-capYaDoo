import 'package:flutter/material.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:capyadoo/core/widgets/app_text_field.dart';
import 'package:capyadoo/core/widgets/app_date_picker.dart';
import 'package:capyadoo/core/widgets/app_button.dart';
import 'package:capyadoo/core/widgets/app_searchable_dropdown.dart';
import 'package:capyadoo/core/widgets/app_slider.dart';

class AddSymptomPage extends StatefulWidget {
  const AddSymptomPage({super.key});

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

  @override
  void initState() {
    super.initState();
    // Set default date and time to now
    _selectedDate = DateTime.now();
    _selectedTime = TimeOfDay.now();
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
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Expanded(
                          child: Text(
                            'เพิ่มบันทึกอาการ',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48), // Balance the back button
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Form content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // วันที่
                  const Text(
                    'วันที่',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Sarabun',
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppDatePicker(
                    hint: 'เลือกวันที่',
                    selectedDate: _selectedDate,
                    onDateSelected: (date) {
                      setState(() {
                        _selectedDate = date;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // เวลา
                  const Text(
                    'เวลา',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Sarabun',
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _selectTime(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.textSublest),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time, color: AppColors.textSub),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              _selectedTime != null
                                  ? _formatTime(_selectedTime!)
                                  : 'เลือกเวลา',
                              style: TextStyle(
                                fontSize: 16,
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
                  const SizedBox(height: 20),

                  // ชื่อยา
                  AppSearchableDropdown<String>(
                    label: 'ชื่อยา',
                    hint: 'เลือกยาหรือค้นหาชื่อยา',
                    value: _selectedMedicine,
                    isRequired: true,
                    items: const [
                      SearchableDropdownItem(
                        value: 'medicine1',
                        label: 'แก้อักเสบ',
                        searchKeywords: ['แก้อักเสบ'],
                      ),
                      SearchableDropdownItem(
                        value: 'medicine2',
                        label: 'ยาลดน้ำมูก',
                        searchKeywords: ['ยาลดน้ำมูก', 'น้ำมูก'],
                      ),
                      SearchableDropdownItem(
                        value: 'medicine3',
                        label: 'ยาแก้ปวด',
                        searchKeywords: ['ยาแก้ปวด', 'ปวด'],
                      ),
                      SearchableDropdownItem(
                        value: 'medicine4',
                        label: 'ยาลดไข้',
                        searchKeywords: ['ยาลดไข้', 'ไข้'],
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedMedicine = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

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
                  const SizedBox(height: 20),

                  // รายละเอียดอาการ
                  const Text(
                    'รายละเอียดอาการ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Sarabun',
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppLongTextField(
                    controller: _descriptionController,
                    hint: 'กรอกรายละเอียดอาการ...',
                  ),
                  const SizedBox(height: 32),

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
                      const SizedBox(width: 16),
                      Expanded(
                        child: AppButton(
                          text: 'บันทึก',
                          onPressed: () {
                            // TODO: Validate and save form
                            if (_selectedMedicine == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('กรุณาเลือกชื่อยา'),
                                ),
                              );
                              return;
                            }
                            Navigator.pop(context);
                          },
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
}
