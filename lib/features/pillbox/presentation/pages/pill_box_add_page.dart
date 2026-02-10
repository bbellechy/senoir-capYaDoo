import 'dart:io';
import 'package:flutter/material.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:capyadoo/core/model/medication_box.dart';
import 'package:capyadoo/core/widgets/app_button.dart';
import 'package:capyadoo/core/widgets/app_image_picker.dart';
import 'package:capyadoo/core/widgets/app_text_field.dart';
import 'package:capyadoo/core/widgets/app_checkbox.dart';
import 'package:capyadoo/core/widgets/app_radio_button.dart';
import 'package:capyadoo/features/notifications/presentation/widgets/day_selector_widget.dart';
import 'package:capyadoo/features/pillbox/controller/pill_box_controller.dart';

class PillBoxAddPage extends StatefulWidget {
  final MedicationBox? existingBox;

  const PillBoxAddPage({super.key, this.existingBox});

  @override
  State<PillBoxAddPage> createState() => _PillBoxAddPageState();
}

class _PillBoxAddPageState extends State<PillBoxAddPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final PillBoxController _controller = PillBoxController();

  File? _imageFile;
  bool _isSubmitting = false;

  List<int> _selectedDays = [];
  List<String> _selectedPeriods = [];
  String _selectedTiming = 'หลังอาหาร';

  @override
  void initState() {
    super.initState();
    if (widget.existingBox != null) {
      _nameController.text = widget.existingBox!.name;
      _descController.text = widget.existingBox!.description ?? '';
      if (widget.existingBox!.imagePath != null) {
        _imageFile = File(widget.existingBox!.imagePath!);
      }
      _selectedDays = List.from(widget.existingBox!.days);
      _selectedPeriods = widget.existingBox!.intakePeriods.map((p) {
        switch (p) {
          case 'MORNING':
            return 'เช้า';
          case 'NOON':
            return 'กลางวัน';
          case 'EVENING':
            return 'เย็น';
          case 'BEDTIME':
            return 'ก่อนนอน';
          default:
            return p;
        }
      }).toList();
      final timing = widget.existingBox!.intakeTiming;
      switch (timing) {
        case 'BEFORE_MEAL':
          _selectedTiming = 'ก่อนอาหาร';
          break;
        case 'AFTER_MEAL':
          _selectedTiming = 'หลังอาหาร';
          break;
        case 'WITH_MEAL':
          _selectedTiming = 'พร้อมอาหาร';
          break;
        case 'IMMEDIATE':
          _selectedTiming = 'ทานทันที';
          break;
        default:
          break;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกวันที่ต้องทานยา')),
      );
      return;
    }
    if (_selectedPeriods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกช่วงเวลารับประทาน')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    bool success;

    if (widget.existingBox != null) {
      final updatedBox = widget.existingBox!.copyWith(
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        days: _selectedDays..sort(),
        intakePeriods: _selectedPeriods.map((p) {
          switch (p) {
            case 'เช้า':
              return 'MORNING';
            case 'กลางวัน':
              return 'NOON';
            case 'เย็น':
              return 'EVENING';
            case 'ก่อนนอน':
              return 'BEDTIME';
            default:
              return p;
          }
        }).toList(),
        intakeTiming: _selectedTiming == 'ก่อนอาหาร'
            ? 'BEFORE_MEAL'
            : _selectedTiming == 'หลังอาหาร'
            ? 'AFTER_MEAL'
            : _selectedTiming == 'พร้อมอาหาร'
            ? 'WITH_MEAL'
            : 'IMMEDIATE',
      );
      success = await _controller.updatePillBox(updatedBox, _imageFile);
    } else {
      success = await _controller.addPillBox(
        _nameController.text.trim(),
        _descController.text.trim(),
        _imageFile,
        _selectedDays..sort(),
        _selectedPeriods.map((p) {
          switch (p) {
            case 'เช้า':
              return 'MORNING';
            case 'กลางวัน':
              return 'NOON';
            case 'เย็น':
              return 'EVENING';
            case 'ก่อนนอน':
              return 'BEDTIME';
            default:
              return p;
          }
        }).toList(),
        _selectedTiming == 'ก่อนอาหาร'
            ? 'BEFORE_MEAL'
            : _selectedTiming == 'หลังอาหาร'
            ? 'AFTER_MEAL'
            : _selectedTiming == 'พร้อมอาหาร'
            ? 'WITH_MEAL'
            : 'IMMEDIATE',
      );
    }

    setState(() {
      _isSubmitting = false;
    });

    if (success) {
      if (mounted) {
        Navigator.pop(context, true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_controller.error ?? 'เกิดข้อผิดพลาดในการบันทึก'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingBox != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'แก้ไขกล่องยา' : 'เพิ่มกล่องยา'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Picker
              Center(
                child: AppImagePicker(
                  label: 'รูปกล่องยา',
                  imageFile: _imageFile,
                  onImageSelected: (file) {
                    setState(() {
                      _imageFile = file;
                    });
                  },
                  height: 200,
                  width: double.infinity,
                ),
              ),
              const SizedBox(height: 24),

              // Name Field
              AppTextField(
                controller: _nameController,
                label: 'ชื่อกล่องยา *',
                hint: 'เช่น ยาเบาหวาน, ยาประจำวัน',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณาระบุชื่อกล่องยา';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description Field
              AppTextField(
                controller: _descController,
                label: 'รายละเอียด',
                hint: 'รายละเอียดเพิ่มเติม',
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // Days selector
              Row(
                children: [
                  const Text(
                    'วันที่ต้องทานยา',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const Text(
                    ' *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DaySelectorWidget(
                selectedDays: _selectedDays,
                onDaysChanged: (days) {
                  setState(() {
                    _selectedDays = days;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Meal timing
              const Text(
                'รับประทาน',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: AppRadioButton<String>(
                      value: 'ก่อนอาหาร',
                      groupValue: _selectedTiming,
                      label: 'ก่อนอาหาร',
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedTiming = value;
                          });
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: AppRadioButton<String>(
                      value: 'หลังอาหาร',
                      groupValue: _selectedTiming,
                      label: 'หลังอาหาร',
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedTiming = value;
                          });
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: AppRadioButton<String>(
                      value: 'พร้อมอาหาร',
                      groupValue: _selectedTiming,
                      label: 'พร้อมอาหาร',
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedTiming = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AppRadioButton<String>(
                value: 'ทานทันที',
                groupValue: _selectedTiming,
                label: 'ทานทันที',
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedTiming = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),

              // Meal times
              Row(
                children: [
                  const Text(
                    'เวลารับประทาน',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const Text(
                    ' *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AppCheckbox(
                          value: _selectedPeriods.contains('เช้า'),
                          label: 'เช้า',
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                if (!_selectedPeriods.contains('เช้า')) {
                                  _selectedPeriods.add('เช้า');
                                }
                              } else {
                                _selectedPeriods.remove('เช้า');
                              }
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: AppCheckbox(
                          value: _selectedPeriods.contains('กลางวัน'),
                          label: 'กลางวัน',
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                if (!_selectedPeriods.contains('กลางวัน')) {
                                  _selectedPeriods.add('กลางวัน');
                                }
                              } else {
                                _selectedPeriods.remove('กลางวัน');
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
                          value: _selectedPeriods.contains('เย็น'),
                          label: 'เย็น',
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                if (!_selectedPeriods.contains('เย็น')) {
                                  _selectedPeriods.add('เย็น');
                                }
                              } else {
                                _selectedPeriods.remove('เย็น');
                              }
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: AppCheckbox(
                          value: _selectedPeriods.contains('ก่อนนอน'),
                          label: 'ก่อนนอน',
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                if (!_selectedPeriods.contains('ก่อนนอน')) {
                                  _selectedPeriods.add('ก่อนนอน');
                                }
                              } else {
                                _selectedPeriods.remove('ก่อนนอน');
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'ยกเลิก',
                      isOutlined: true,
                      backgroundColor: Colors.grey,
                      textColor: Colors.grey,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppButton(
                      text: isEditing ? 'บันทึก' : 'สร้างกล่องยา',
                      isLoading: _isSubmitting,
                      onPressed: _submit,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
