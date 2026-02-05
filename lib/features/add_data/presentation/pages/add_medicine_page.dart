import 'dart:io';
import 'package:flutter/material.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:capyadoo/core/widgets/app_image_picker.dart';
import 'package:capyadoo/core/widgets/app_text_field.dart';
import 'package:capyadoo/core/widgets/app_radio_button.dart';
import 'package:capyadoo/core/widgets/app_checkbox.dart';
import 'package:capyadoo/core/widgets/app_searchable_dropdown.dart';
import 'package:capyadoo/core/widgets/app_date_picker.dart';
import 'package:capyadoo/core/widgets/app_button.dart';

class AddMedicinePage extends StatefulWidget {
  const AddMedicinePage({super.key});

  @override
  State<AddMedicinePage> createState() => _AddMedicinePageState();
}

class _AddMedicinePageState extends State<AddMedicinePage> {
  final _formKey = GlobalKey<FormState>();
  File? _selectedImage;
  String? _medicineName;
  String _amount = '';
  String _unit = '';
  String _frequency = '';
  String _mealTiming = 'ก่อนอาหาร';
  List<String> _mealTimes = [];
  DateTime? _expiryDate;
  List<String> _recommendations = [];
  String _additionalNotes = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Expanded(
                          child: Text(
                            'เพิ่มข้อมูลยา',
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

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Medicine image picker
                    AppImagePicker(
                      onImageSelected: (File? imageFile) {
                        setState(() {
                          _selectedImage = imageFile;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Medicine name
                    AppSearchableDropdown<String>(
                      label: 'ชื่อยา',
                      hint: 'เลือกหรือค้นหายา',
                      value: _medicineName,
                      isRequired: true,
                      items: [
                        SearchableDropdownItem(
                          value: 'พาราเซตามอล',
                          label: 'พาราเซตามอล',
                        ),
                        SearchableDropdownItem(
                          value: 'ไอบูโพรเฟน',
                          label: 'ไอบูโพรเฟน',
                        ),
                        SearchableDropdownItem(
                          value: 'แอสไพริน',
                          label: 'แอสไพริน',
                        ),
                        SearchableDropdownItem(
                          value: 'อะม็อกซีซิลลิน',
                          label: 'อะม็อกซีซิลลิน',
                        ),
                        SearchableDropdownItem(
                          value: 'เซฟิกซิม',
                          label: 'เซฟิกซิม',
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _medicineName = value;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Amount and Unit
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: 'ปริมาณ',
                            hint: 'เช่น 1',
                            keyboardType: TextInputType.number,
                            isRequired: true,
                            onChanged: (value) {
                              setState(() {
                                _amount = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AppTextField(
                            label: 'หน่วย',
                            hint: 'เม็ด',
                            isRequired: true,
                            onChanged: (value) {
                              setState(() {
                                _unit = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Frequency per day
                    AppTextField(
                      label: 'จำนวนครั้งที่ทานต่อวัน',
                      hint: 'ระบุจำนวน',
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          _frequency = value;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Meal timing
                    const Text(
                      'รับประทาน',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: AppRadioButton<String>(
                            value: 'ก่อนอาหาร',
                            groupValue: _mealTiming,
                            label: 'ก่อนอาหาร',
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _mealTiming = value;
                                });
                              }
                            },
                          ),
                        ),
                        Expanded(
                          child: AppRadioButton<String>(
                            value: 'หลังอาหาร',
                            groupValue: _mealTiming,
                            label: 'หลังอาหาร',
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _mealTiming = value;
                                });
                              }
                            },
                          ),
                        ),
                        Expanded(
                          child: AppRadioButton<String>(
                            value: 'ทานทันที',
                            groupValue: _mealTiming,
                            label: 'ทานทันที',
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _mealTiming = value;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Meal times
                    const Text(
                      'เวลารับประทาน',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: AppCheckbox(
                                value: _mealTimes.contains('เช้า'),
                                label: 'เช้า',
                                onChanged: (checked) {
                                  setState(() {
                                    if (checked == true) {
                                      _mealTimes.add('เช้า');
                                    } else {
                                      _mealTimes.remove('เช้า');
                                    }
                                  });
                                },
                              ),
                            ),
                            Expanded(
                              child: AppCheckbox(
                                value: _mealTimes.contains('กลางวัน'),
                                label: 'กลางวัน',
                                onChanged: (checked) {
                                  setState(() {
                                    if (checked == true) {
                                      _mealTimes.add('กลางวัน');
                                    } else {
                                      _mealTimes.remove('กลางวัน');
                                    }
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: AppCheckbox(
                                value: _mealTimes.contains('เย็น'),
                                label: 'เย็น',
                                onChanged: (checked) {
                                  setState(() {
                                    if (checked == true) {
                                      _mealTimes.add('เย็น');
                                    } else {
                                      _mealTimes.remove('เย็น');
                                    }
                                  });
                                },
                              ),
                            ),
                            Expanded(
                              child: AppCheckbox(
                                value: _mealTimes.contains('ก่อนนอน'),
                                label: 'ก่อนนอน',
                                onChanged: (checked) {
                                  setState(() {
                                    if (checked == true) {
                                      _mealTimes.add('ก่อนนอน');
                                    } else {
                                      _mealTimes.remove('ก่อนนอน');
                                    }
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Expiry date
                    AppDatePicker(
                      label: 'วันที่หมดอายุ',
                      hint: 'เลือกวันที่',
                      selectedDate: _expiryDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                      onDateSelected: (date) {
                        setState(() {
                          _expiryDate = date;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Recommendations
                    const Text(
                      'ข้อแนะนำ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AppCheckboxGroup(
                      options: const [
                        AppCheckboxOption(
                          value: 'ก่อนอาหาร 1/2 - 1 ชั่วโมง',
                          label: 'ก่อนอาหาร 1/2 - 1 ชั่วโมง',
                        ),
                        AppCheckboxOption(
                          value: 'ทานติดต่อกันจนหมด',
                          label: 'ทานติดต่อกันจนหมด',
                        ),
                        AppCheckboxOption(
                          value: 'ทานยาหลังอาหารทันที',
                          label: 'ทานยาหลังอาหารทันที',
                        ),
                        AppCheckboxOption(
                          value: 'ดื่มน้ำตามมากๆ',
                          label: 'ดื่มน้ำตามมากๆ',
                        ),
                        AppCheckboxOption(
                          value:
                              'ไม่ทานยาพร้อมนม ยาลดกรด แคลเซียม แมกนีเซียม ธาตุเหล็ก',
                          label:
                              'ไม่ทานยาพร้อมนม ยาลดกรด แคลเซียม แมกนีเซียม ธาตุเหล็ก',
                        ),
                        AppCheckboxOption(
                          value: 'ยานี้อาจทำให้ง่วงซึม',
                          label: 'ยานี้อาจทำให้ง่วงซึม',
                        ),
                      ],
                      selectedValues: _recommendations,
                      onChanged: (values) {
                        setState(() {
                          _recommendations = values;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Additional notes
                    AppLongTextField(
                      label: 'หมายเหตุเพิ่มเติม',
                      hint: 'กรอกข้อมูลเพิ่มเติม...',
                      onChanged: (value) {
                        setState(() {
                          _additionalNotes = value;
                        });
                      },
                    ),
                    const SizedBox(height: 32),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            text: 'ยกเลิก',
                            isOutlined: true,
                            textColor: AppColors.textSub,
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AppButton(
                            text: 'บันทึก',
                            onPressed: () {
                              // TODO: Save medicine data
                              if (_formKey.currentState?.validate() ?? false) {
                                Navigator.pop(context);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
