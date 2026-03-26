import 'dart:io';
import 'package:flutter/material.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:capyadoo/core/config/api_config.dart';
import 'package:capyadoo/core/widgets/app_image_picker.dart';
import 'package:capyadoo/core/widgets/app_text_field.dart';
import 'package:capyadoo/core/widgets/app_radio_button.dart';
import 'package:capyadoo/core/widgets/app_checkbox.dart';
import 'package:capyadoo/core/widgets/app_date_picker.dart';
import 'package:capyadoo/core/widgets/app_button.dart';
import 'package:capyadoo/core/services/medication_service.dart';
import 'package:capyadoo/core/services/auth_service.dart';
import 'package:capyadoo/core/widgets/app_searchable_dropdown.dart';
import 'package:capyadoo/core/model/user_medication.dart';
import 'package:capyadoo/features/notifications/presentation/widgets/day_selector_widget.dart';
import 'package:capyadoo/features/notifications/presentation/widgets/unified_selection_dialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class AddMedicinePage extends StatefulWidget {
  final String? medicationId;
  const AddMedicinePage({super.key, this.medicationId});

  @override
  State<AddMedicinePage> createState() => _AddMedicinePageState();
}

class _AddMedicinePageState extends State<AddMedicinePage> {
  final _formKey = GlobalKey<FormState>();
  File? _selectedImage;
  String? _initialImageUrl;
  String? _medicineName;
  String _amount = '';
  String _unit = '';
  String _frequency = '';
  String _mealTiming = 'ก่อนอาหาร';
  List<String> _mealTimes = [];
  DateTime? _expiryDate;
  List<String> _recommendations = [];
  String _additionalNotes = '';
  bool _isLoading = false;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _frequencyController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  List<int> _selectedDays = [];
  DateTime? _startDate;
  DateTime? _endDate;
  String? _userId;

  bool get _isEditMode => widget.medicationId != null;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final profile = await AuthService.getProfile();
    if (mounted) {
      setState(() {
        _userId = profile?.id;
      });
    }
  }

  Future<void> _showMedicationSelectionDialog() async {
    if (_userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ไม่พบข้อมูลผู้ใช้')));
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => UnifiedSelectionDialog(
        userId: _userId!,
        title: 'เลือกยา',
        showMasterMedications: true,
        showBoxes: false,
        allowFreeText: true,
        loadAllMedicationsOnOpen: false,
      ),
    );

    if (result != null) {
      final type = result['type'] as String;
      setState(() {
        _medicineName = result['name'] as String;

        // If it's a UserMedication or filtered master medication, we might have more data
        // For now, let's see if we can get the full object or if we need to fetch it
        // The result currently only has name, id, type, imagePath.
      });

      // If it's a known medication, try to fetch its full details to populate fields
      if (result['id'] != null &&
          (type == 'medication' || type == 'user_medication')) {
        _populateFieldsFromSelection(
          result['id'].toString(),
          type == 'user_medication',
        );
      }
    }
  }

  Future<void> _populateFieldsFromSelection(
    String id,
    bool isUserMedication,
  ) async {
    setState(() => _isLoading = true);
    try {
      UserMedication? med;
      if (isUserMedication) {
        med = await MedicationService.getMedicationById(id, _userId!);
      } else {
        // For master medication, we don't have a direct "get by ID" that returns UserMedication
        // but it will populate name which is already done.
        // Some master meds might have default dosages in the future.
      }

      if (med != null && mounted) {
        setState(() {
          _medicineName = med!.name;
          _amount = med.dosage?.toString() ?? '';
          _amountController.text = _amount;
          _unit = med.unit ?? '';
          _frequency = med.timesPerDay?.toString() ?? '';
          _frequencyController.text = _frequency;

          if (med.intakeTiming != null) {
            _mealTiming = med.intakeTiming == 'BEFORE_MEAL'
                ? 'ก่อนอาหาร'
                : med.intakeTiming == 'AFTER_MEAL'
                ? 'หลังอาหาร'
                : 'ทานทันที';
          }

          if (med.intakePeriods != null) {
            _mealTimes = med.intakePeriods!.map((t) {
              switch (t) {
                case 'MORNING':
                  return 'เช้า';
                case 'NOON':
                  return 'กลางวัน';
                case 'EVENING':
                  return 'เย็น';
                case 'BEDTIME':
                  return 'ก่อนนอน';
                default:
                  return t;
              }
            }).toList();
          }

          if (med.days != null) {
            _selectedDays = List<int>.from(med.days!);
          }

          if (med.notes != null) {
            _additionalNotes = med.notes!;
            _notesController.text = _additionalNotes;
          }

          if (med.imagePath != null) {
            _initialImageUrl = med.imagePath;
          }
        });
      }
    } catch (e) {
      print('Error populating fields: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _frequencyController.dispose();
    _notesController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (widget.medicationId == null) return;

    setState(() => _isLoading = true);
    try {
      final profile = await AuthService.getProfile();
      if (profile == null) return;

      final med = await MedicationService.getMedicationById(
        widget.medicationId!,
        profile.id,
      );
      if (med != null && mounted) {
        String? initialName = med.name;
        String? initialAmount = med.dosage?.toString() ?? '';
        String? initialUnit = med.unit ?? '';
        String? initialFrequency = med.timesPerDay?.toString() ?? '';
        String? initialMealTiming = med.intakeTiming == 'BEFORE_MEAL'
            ? 'ก่อนอาหาร'
            : med.intakeTiming == 'AFTER_MEAL'
            ? 'หลังอาหาร'
            : 'ทานทันที';
        List<String> initialMealTimes = (med.intakePeriods ?? []).map((t) {
          switch (t) {
            case 'MORNING':
              return 'เช้า';
            case 'NOON':
              return 'กลางวัน';
            case 'EVENING':
              return 'เย็น';
            case 'BEDTIME':
              return 'ก่อนนอน';
            default:
              return t;
          }
        }).toList();
        DateTime? initialExpiryDate = med.expiryDate != null
            ? DateTime.tryParse(med.expiryDate!)
            : null;
        List<String> initialRecommendations =
            med.recommendation
                ?.split(', ')
                .where((s) => s.isNotEmpty)
                .toList() ??
            [];
        String? initialNotes = med.notes ?? '';
        List<int> initialDays = med.days ?? [];
        int? initialQuantity = med.remainingQuantity;
        DateTime? initialStartDate = med.startDate != null
            ? DateTime.tryParse(med.startDate!)
            : null;
        DateTime? initialEndDate = med.endDate != null
            ? DateTime.tryParse(med.endDate!)
            : null;

        File? resolvedSelectedImage;
        String? resolvedInitialImageUrl;

        if (med.imagePath != null && med.imagePath!.isNotEmpty) {
          final normalizedPath = med.imagePath!.replaceAll('\\', '/');
          if (normalizedPath.startsWith('http')) {
            resolvedInitialImageUrl = normalizedPath;
          } else {
            File file = File(med.imagePath!);
            if (file.existsSync()) {
              resolvedSelectedImage = file;
            } else {
              try {
                final appDir = await getApplicationDocumentsDirectory();
                final fileName = path.basename(normalizedPath);
                final localPath = path.join(appDir.path, fileName);
                final localFile = File(localPath);
                if (localFile.existsSync()) {
                  resolvedSelectedImage = localFile;
                } else {
                  resolvedInitialImageUrl =
                      '${ApiConfig.baseUrl}/$normalizedPath';
                }
              } catch (_) {
                resolvedInitialImageUrl =
                    '${ApiConfig.baseUrl}/$normalizedPath';
              }
            }
          }
        }

        setState(() {
          _medicineName = initialName;
          _amount = initialAmount;
          _amountController.text = _amount;
          _unit = initialUnit;
          _frequency = initialFrequency;
          _frequencyController.text = _frequency;
          _mealTiming = initialMealTiming;
          _mealTimes = initialMealTimes;
          _expiryDate = initialExpiryDate;
          _recommendations = initialRecommendations;
          _additionalNotes = initialNotes;
          _notesController.text = _additionalNotes;
          _selectedImage = resolvedSelectedImage;
          _initialImageUrl = resolvedInitialImageUrl;
          _selectedDays = initialDays;
          _quantityController.text = initialQuantity?.toString() ?? '';
          _startDate = initialStartDate;
          _endDate = initialEndDate;
        });
      }
    } catch (e) {
      print('Error loading medication for editing: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
                        Expanded(
                          child: Text(
                            _isEditMode ? 'แก้ไขข้อมูลยา' : 'เพิ่มข้อมูลยา',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
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
                      imageFile: _selectedImage,
                      imageUrl: _initialImageUrl,
                      onImageSelected: (File? imageFile) {
                        setState(() {
                          _selectedImage = imageFile;
                          _initialImageUrl = null;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Medicine name with popup
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'ชื่อยา',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Text(
                              ' *',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _showMedicationSelectionDialog,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _medicineName == null
                                    ? Colors.grey[300]!
                                    : AppColors.primaryBlue,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _medicineName ?? 'เลือกหรือค้นหายา',
                                    style: TextStyle(
                                      color: _medicineName != null
                                          ? Colors.black87
                                          : Colors.grey[500],
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.grey[600],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Amount and Unit
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _amountController,
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
                          child: AppSearchableDropdown<String>(
                            label: 'หน่วย',
                            hint: 'เม็ด',
                            value: _unit.isNotEmpty ? _unit : null,
                            isRequired: true,
                            allowCustomInput: true,
                            items: const [
                              SearchableDropdownItem<String>(
                                value: 'เม็ด',
                                label: 'เม็ด',
                              ),
                              SearchableDropdownItem<String>(
                                value: 'แคปซูล',
                                label: 'แคปซูล',
                              ),
                              SearchableDropdownItem<String>(
                                value: 'ซอง',
                                label: 'ซอง',
                              ),
                              SearchableDropdownItem<String>(
                                value: 'ขวด',
                                label: 'ขวด',
                              ),
                              SearchableDropdownItem<String>(
                                value: 'ช้อนชา',
                                label: 'ช้อนชา',
                              ),
                              SearchableDropdownItem<String>(
                                value: 'ช้อนโต๊ะ',
                                label: 'ช้อนโต๊ะ',
                              ),
                              SearchableDropdownItem<String>(
                                value: 'CC',
                                label: 'CC/ML',
                              ),
                              SearchableDropdownItem<String>(
                                value: 'หยด',
                                label: 'หยด',
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _unit = value ?? '';
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Frequency per day
                    AppTextField(
                      controller: _frequencyController,
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

                    // Days of week selector
                    Row(
                      children: [
                        const Text(
                          'วันที่ต้องทานยา',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
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

                    // Total quantity
                    AppTextField(
                      controller: _quantityController,
                      label: 'จำนวนยาทั้งหมด',
                      hint: 'ระบุจำนวน (เช่น 30)',
                      keyboardType: TextInputType.number,
                      isRequired: true,
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 24),

                    // Start date
                    AppDatePicker(
                      label: 'วันที่เริ่มทานยา',
                      hint: 'เลือกวันที่',
                      selectedDate: _startDate,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 365),
                      ),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      isRequired: true,
                      onDateSelected: (date) {
                        setState(() {
                          _startDate = date;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // End date (optional)
                    AppDatePicker(
                      label: 'วันที่สิ้นสุดการทานยา (ไม่บังคับ)',
                      hint: 'เลือกวันที่ (ถ้ามี)',
                      selectedDate: _endDate,
                      firstDate: _startDate ?? DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                      onDateSelected: (date) {
                        setState(() {
                          _endDate = date;
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
                      controller: _notesController,
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
                            isLoading: _isSubmitting || _isLoading,
                            onPressed: _submitForm,
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

  bool _isSubmitting = false;

  Future<void> _submitForm() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    try {
      final profile = await AuthService.getProfile();
      if (profile == null) throw Exception('User not logged in');

      // Validation
      if (_medicineName == null || _medicineName!.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาเลือกหรือระบุชื่อยา')),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      if (_selectedDays.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาเลือกวันที่ต้องทานยา')),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      final quantityValue = int.tryParse(_quantityController.text);
      if (quantityValue == null || quantityValue <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาระบุจำนวนยาทั้งหมด')),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      if (_startDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาเลือกวันที่เริ่มทานยา')),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      final dosageValue = double.tryParse(_amount) ?? 0.0;
      final timesValue = int.tryParse(_frequency) ?? 0;

      // ส่ง imagePath เฉพาะเมื่อเป็น URL จาก server (backend ไม่รองรับ local path)
      final imagePathForApi =
          (_selectedImage == null && _initialImageUrl != null)
          ? _initialImageUrl
          : null;

      final request = {
        'name': _medicineName ?? '',
        'dosage': dosageValue,
        'unit': _unit,
        'timesPerDay': timesValue,
        'intakeTiming': _mealTiming == 'ก่อนอาหาร'
            ? 'BEFORE_MEAL'
            : _mealTiming == 'หลังอาหาร'
            ? 'AFTER_MEAL'
            : 'IMMEDIATE',
        'intakePeriods': _mealTimes.map((t) {
          switch (t) {
            case 'เช้า':
              return 'MORNING';
            case 'กลางวัน':
              return 'NOON';
            case 'เย็น':
              return 'EVENING';
            case 'ก่อนนอน':
              return 'BEDTIME';
            default:
              return t;
          }
        }).toList(),
        'expiryDate': _expiryDate?.toIso8601String().split('T')[0],
        'recommendation': _recommendations.join(', '),
        'notes': _additionalNotes,
        'userId': profile.id,
        'days': _selectedDays,
        'remainingQuantity': quantityValue,
        'startDate': _startDate!.toIso8601String().split('T')[0],
        if (_endDate != null)
          'endDate': _endDate!.toIso8601String().split('T')[0],
        if (imagePathForApi != null) 'imagePath': imagePathForApi,
      };

      final result = widget.medicationId != null
          ? await MedicationService.updateMedication(
              widget.medicationId!,
              request,
            )
          : await MedicationService.createMedication(request);

      if (result != null) {
        if (_selectedImage != null) {
          final medId = widget.medicationId ?? result.id!;
          await MedicationService.saveMedicationImageLocally(
            medId,
            _selectedImage!,
          );
        }
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('บันทึกข้อมูลยาสำเร็จ')));
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('Failed to save medication');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
