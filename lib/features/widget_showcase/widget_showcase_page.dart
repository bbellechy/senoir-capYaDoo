import 'dart:io';
import 'package:flutter/material.dart';
import 'package:capyadoo/core/widgets/app_button.dart';
import 'package:capyadoo/core/widgets/app_radio_button.dart';
import 'package:capyadoo/core/widgets/app_checkbox.dart';
import 'package:capyadoo/core/widgets/app_text_field.dart';
import 'package:capyadoo/core/widgets/app_date_picker.dart';
import 'package:capyadoo/core/widgets/app_slider.dart';
import 'package:capyadoo/core/widgets/app_image_picker.dart';
import 'package:capyadoo/core/widgets/app_searchable_dropdown.dart';
import 'package:capyadoo/features/add_data/presentation/widgets/medicine_list_card.dart';
import 'package:capyadoo/features/add_data/presentation/widgets/symptom_list_card.dart';
import 'package:capyadoo/core/widgets/medicine_box_list_card.dart';
import 'package:capyadoo/core/widgets/simple_medicine_list_card.dart';
import 'package:capyadoo/core/widgets/app_time_chip.dart' as time_chip;
import 'package:capyadoo/features/home/presentation/widgets/medicine_reminder_card.dart';
import 'package:capyadoo/features/home/presentation/widgets/medicine_box_reminder_card.dart';

class WidgetShowcasePage extends StatefulWidget {
  const WidgetShowcasePage({super.key});

  @override
  State<WidgetShowcasePage> createState() => _WidgetShowcasePageState();
}

class _WidgetShowcasePageState extends State<WidgetShowcasePage> {
  // Radio button state
  String? selectedOption;

  // Checkbox state
  List<String> selectedCheckboxes = [];

  // Text field controllers
  final TextEditingController shortTextController = TextEditingController();
  final TextEditingController longTextController = TextEditingController();

  // Date picker state
  DateTime? selectedDate;
  DateTimeRange? selectedDateRange;

  // Slider state
  double sliderValue = 5.0;
  RangeValues rangeSliderValues = const RangeValues(20, 80);

  // Image picker state
  File? selectedImage;
  List<File> selectedImages = [];

  // Searchable dropdown state
  String? selectedProvince;

  // Medicine reminder state
  MedicineReminderStatus singleMedicine1Status = MedicineReminderStatus.pending;
  MedicineReminderStatus singleMedicine2Status = MedicineReminderStatus.taken;
  MedicineBoxReminderStatus boxMedicineStatus =
      MedicineBoxReminderStatus.pending;

  // List card state
  final List<Map<String, dynamic>> listItems = [
    {
      'id': 1,
      'name': 'แก้วเสา',
      'detail': 'ปริมาณ: 3 เม็ด\nจำนวนครั้ง: 2 ครั้ง',
    },
    {'id': 2, 'name': 'ทดสอบกล่องยา', 'detail': '4 รายการยา'},
    {'id': 3, 'name': 'ซื้อกล่องยา', 'detail': '1 เม็ด'},
  ];

  @override
  void dispose() {
    shortTextController.dispose();
    longTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Widget Showcase'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: '1. Radio Buttons',
              child: AppRadioGroup<String>(
                title: 'เลือกตัวเลือก',
                groupValue: selectedOption,
                options: const [
                  AppRadioOption(value: 'option1', label: 'ตัวเลือกที่ 1'),
                  AppRadioOption(value: 'option2', label: 'ตัวเลือกที่ 2'),
                  AppRadioOption(value: 'option3', label: 'ตัวเลือกที่ 3'),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedOption = value;
                  });
                },
              ),
            ),
            _buildDivider(),
            _buildSection(
              title: '2. Checkboxes',
              child: AppCheckboxGroup(
                title: 'เลือกหลายตัวเลือก',
                selectedValues: selectedCheckboxes,
                options: const [
                  AppCheckboxOption(value: 'checkbox1', label: 'ตัวเลือก A'),
                  AppCheckboxOption(value: 'checkbox2', label: 'ตัวเลือก B'),
                  AppCheckboxOption(value: 'checkbox3', label: 'ตัวเลือก C'),
                  AppCheckboxOption(value: 'checkbox4', label: 'ตัวเลือก D'),
                ],
                onChanged: (values) {
                  setState(() {
                    selectedCheckboxes = values;
                  });
                },
              ),
            ),
            _buildDivider(),
            _buildSection(
              title: '3. Text Field (ปกติ)',
              child: AppTextField(
                controller: shortTextController,
                label: 'ชื่อผู้ใช้',
                hint: 'กรอกชื่อผู้ใช้',
                prefixIcon: const Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: '4. Long Text Field (200 ตัวอักษร)',
              child: AppLongTextField(
                controller: longTextController,
                label: 'รายละเอียด',
                hint: 'กรอกรายละเอียดไม่เกิน 200 ตัวอักษร',
              ),
            ),
            _buildDivider(),
            _buildSection(
              title: '5. Date Picker (วันที่เดียว)',
              child: AppDatePicker(
                label: 'วันที่',
                hint: 'เลือกวันที่',
                selectedDate: selectedDate,
                onDateSelected: (date) {
                  setState(() {
                    selectedDate = date;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: '6. Date Range Picker (ช่วงวันที่)',
              child: AppDateRangePicker(
                label: 'ช่วงวันที่',
                hint: 'เลือกช่วงวันที่',
                selectedRange: selectedDateRange,
                onRangeSelected: (range) {
                  setState(() {
                    selectedDateRange = range;
                  });
                },
              ),
            ),
            _buildDivider(),
            _buildSection(
              title: '7. Slider (1-10)',
              child: AppSlider(
                label: 'ระดับความพึงพอใจ',
                value: sliderValue,
                min: 1,
                max: 10,
                minLabel: 'น้อย',
                maxLabel: 'มาก',
                onChanged: (value) {
                  setState(() {
                    sliderValue = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: '8. Range Slider (0-100)',
              child: AppRangeSlider(
                label: 'ช่วงราคา',
                values: rangeSliderValues,
                min: 0,
                max: 100,
                minLabel: 'ต่ำสุด',
                maxLabel: 'สูงสุด',
                onChanged: (values) {
                  setState(() {
                    rangeSliderValues = values;
                  });
                },
              ),
            ),
            _buildDivider(),
            _buildSection(
              title: '9. Image Picker (รูปเดียว)',
              child: AppImagePicker(
                label: 'เลือกรูปภาพ',
                hint: 'ถ่ายรูป',
                imageFile: selectedImage,
                height: 200,
                onImageSelected: (file) {
                  setState(() {
                    selectedImage = file;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: '10. Multi Image Picker (หลายรูป)',
              child: AppMultiImagePicker(
                label: 'เลือกรูปหลายรูป (สูงสุด 5 รูป)',
                imageFiles: selectedImages,
                maxImages: 5,
                imageHeight: 120,
                onImagesChanged: (files) {
                  setState(() {
                    selectedImages = files;
                  });
                },
              ),
            ),
            _buildDivider(),
            _buildSection(
              title: '11. Searchable Dropdown',
              child: AppSearchableDropdown<String>(
                label: 'จังหวัด',
                hint: 'เลือกจังหวัด',
                value: selectedProvince,
                items: const [
                  SearchableDropdownItem(
                    value: 'bkk',
                    label: 'กรุงเทพมหานคร',
                    subtitle: 'Bangkok',
                    searchKeywords: ['กทม', 'bangkok', 'bkk'],
                  ),
                  SearchableDropdownItem(
                    value: 'cm',
                    label: 'เชียงใหม่',
                    subtitle: 'Chiang Mai',
                    searchKeywords: ['chiangmai', 'cm'],
                  ),
                  SearchableDropdownItem(
                    value: 'ck',
                    label: 'เชียงราย',
                    subtitle: 'Chiang Rai',
                    searchKeywords: ['chiangrai', 'ck'],
                  ),
                  SearchableDropdownItem(
                    value: 'pk',
                    label: 'ภูเก็ต',
                    subtitle: 'Phuket',
                    searchKeywords: ['phuket', 'pk'],
                  ),
                  SearchableDropdownItem(
                    value: 'kp',
                    label: 'กระบี่',
                    subtitle: 'Krabi',
                    searchKeywords: ['krabi', 'kp'],
                  ),
                  SearchableDropdownItem(
                    value: 'kh',
                    label: 'ขอนแก่น',
                    subtitle: 'Khon Kaen',
                    searchKeywords: ['khonkaen', 'kh'],
                  ),
                  SearchableDropdownItem(
                    value: 'sr',
                    label: 'สุราษฎร์ธานี',
                    subtitle: 'Surat Thani',
                    searchKeywords: ['suratthani', 'sr'],
                  ),
                  SearchableDropdownItem(
                    value: 'np',
                    label: 'นครปฐม',
                    subtitle: 'Nakhon Pathom',
                    searchKeywords: ['nakhonpathom', 'np'],
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedProvince = value;
                  });
                },
              ),
            ),
            _buildDivider(),
            _buildSection(
              title: '12. List Cards',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Medicine List Card - รายการยา
                  const Text(
                    '1. รายการยา (MedicineListCard)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  MedicineListCard(
                    image: null,
                    name: 'แก้อักเสบ',
                    amount: '1 เม็ด',
                    frequency: 2,
                    mealTiming: 'หลังอาหาร',
                    expiryDate: '30/10/2568',
                    mealTimes: const ['เช้า', 'เย็น'],
                    onEdit: () => _showSnackBar('แก้ไข: แก้อักเสบ'),
                    onDelete: () => _showSnackBar('ลบ: แก้อักเสบ'),
                  ),
                  const SizedBox(height: 24),

                  // 2. Symptom List Card - บันทึกอาการ
                  const Text(
                    '2. บันทึกอาการ (SymptomListCard)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'แสดงการไล่สีทุกระดับ 1-10',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  SymptomListCard(
                    level: 1,
                    title: 'อาการเล็กน้อย',
                    description: 'ระดับ 1 - สีเขียว',
                    dateTime: 'บันทึกเมื่อ 08:00 น.',
                    onEdit: () => _showSnackBar('แก้ไข: ระดับ 1'),
                    onDelete: () => _showSnackBar('ลบ: ระดับ 1'),
                  ),
                  const SizedBox(height: 12),
                  SymptomListCard(
                    level: 2,
                    title: 'อาการเล็กน้อย',
                    description: 'ระดับ 2 - สีเขียว',
                    dateTime: 'บันทึกเมื่อ 09:00 น.',
                    onEdit: () => _showSnackBar('แก้ไข: ระดับ 2'),
                    onDelete: () => _showSnackBar('ลบ: ระดับ 2'),
                  ),
                  const SizedBox(height: 12),
                  SymptomListCard(
                    level: 3,
                    title: 'อาการเล็กน้อย',
                    description: 'ระดับ 3 - สีเขียว',
                    dateTime: 'บันทึกเมื่อ 10:00 น.',
                    onEdit: () => _showSnackBar('แก้ไข: ระดับ 3'),
                    onDelete: () => _showSnackBar('ลบ: ระดับ 3'),
                  ),
                  const SizedBox(height: 12),
                  SymptomListCard(
                    level: 4,
                    title: 'อาการปานกลาง',
                    description: 'ระดับ 4 - เขียว → เหลือง',
                    dateTime: 'บันทึกเมื่อ 11:00 น.',
                    onEdit: () => _showSnackBar('แก้ไข: ระดับ 4'),
                    onDelete: () => _showSnackBar('ลบ: ระดับ 4'),
                  ),
                  const SizedBox(height: 12),
                  SymptomListCard(
                    level: 5,
                    title: 'อาการปานกลาง',
                    description: 'ระดับ 5 - สีเหลือง',
                    dateTime: 'บันทึกเมื่อ 12:00 น.',
                    onEdit: () => _showSnackBar('แก้ไข: ระดับ 5'),
                    onDelete: () => _showSnackBar('ลบ: ระดับ 5'),
                  ),
                  const SizedBox(height: 12),
                  SymptomListCard(
                    level: 6,
                    title: 'อาการปานกลาง',
                    description: 'ระดับ 6 - เหลือง → ส้ม',
                    dateTime: 'บันทึกเมื่อ 13:00 น.',
                    onEdit: () => _showSnackBar('แก้ไข: ระดับ 6'),
                    onDelete: () => _showSnackBar('ลบ: ระดับ 6'),
                  ),
                  const SizedBox(height: 12),
                  SymptomListCard(
                    level: 7,
                    title: 'อาการรุนแรง',
                    description: 'ระดับ 7 - สีส้ม',
                    dateTime: 'บันทึกเมื่อ 14:00 น.',
                    onEdit: () => _showSnackBar('แก้ไข: ระดับ 7'),
                    onDelete: () => _showSnackBar('ลบ: ระดับ 7'),
                  ),
                  const SizedBox(height: 12),
                  SymptomListCard(
                    level: 8,
                    title: 'อาการรุนแรง',
                    description: 'ระดับ 8 - ส้ม → แดง',
                    dateTime: 'บันทึกเมื่อ 15:00 น.',
                    onEdit: () => _showSnackBar('แก้ไข: ระดับ 8'),
                    onDelete: () => _showSnackBar('ลบ: ระดับ 8'),
                  ),
                  const SizedBox(height: 12),
                  SymptomListCard(
                    level: 9,
                    title: 'อาการรุนแรงมาก',
                    description: 'ระดับ 9 - สีแดง',
                    dateTime: 'บันทึกเมื่อ 16:00 น.',
                    onEdit: () => _showSnackBar('แก้ไข: ระดับ 9'),
                    onDelete: () => _showSnackBar('ลบ: ระดับ 9'),
                  ),
                  const SizedBox(height: 12),
                  SymptomListCard(
                    level: 10,
                    title: 'อาการรุนแรงมาก',
                    description: 'ระดับ 10 - สีแดง',
                    dateTime: 'บันทึกเมื่อ 17:00 น.',
                    onEdit: () => _showSnackBar('แก้ไข: ระดับ 10'),
                    onDelete: () => _showSnackBar('ลบ: ระดับ 10'),
                  ),
                  const SizedBox(height: 24),

                  // 3. Medicine Box List Card - กล่องยา
                  const Text(
                    '3. กล่องยา (MedicineBoxListCard)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  MedicineBoxListCard(
                    icon: Icons.shopping_bag,
                    iconColor: Colors.blue,
                    iconBackgroundColor: Colors.blue[50]!,
                    name: 'ชื่อกล่องยา',
                    medicineCount: 0,
                    onEdit: () => _showSnackBar('แก้ไข: กล่องยา'),
                    onDelete: () => _showSnackBar('ลบ: กล่องยา'),
                  ),
                  const SizedBox(height: 24),

                  // 4. Simple Medicine List Card - รายการยาแบบง่าย
                  const Text(
                    '4. รายการยาแบบง่าย (SimpleMedicineListCard)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  SimpleMedicineListCard(
                    icon: Icons.medication,
                    iconColor: Colors.blue,
                    iconBackgroundColor: Colors.blue[50]!,
                    name: 'ชื่อยา',
                    amount: '1 เม็ด',
                    mealTimes: const ['เช้า', 'กลางวัน', 'เย็น'],
                    onDelete: () => _showSnackBar('ลบ: ยา'),
                  ),
                  const SizedBox(height: 12),
                  SimpleMedicineListCard(
                    icon: Icons.medication,
                    iconColor: Colors.blue,
                    iconBackgroundColor: Colors.blue[50]!,
                    name: 'ชื่อยา',
                    amount: '1 เม็ด',
                    mealTimes: const ['เช้า', 'ก่อนนอน'],
                    onDelete: () => _showSnackBar('ลบ: ยา'),
                  ),
                  const SizedBox(height: 12),
                  SimpleMedicineListCard(
                    icon: Icons.medication,
                    iconColor: Colors.blue,
                    iconBackgroundColor: Colors.blue[50]!,
                    name: 'ชื่อยา',
                    amount: '1 เม็ด',
                    mealTimes: const ['เช้า', 'เย็น'],
                    onDelete: () => _showSnackBar('ลบ: ยา'),
                  ),
                  const SizedBox(height: 12),
                  SimpleMedicineListCard(
                    icon: Icons.medication,
                    iconColor: Colors.blue,
                    iconBackgroundColor: Colors.blue[50]!,
                    name: 'ชื่อยา',
                    amount: '1 เม็ด',
                    mealTimes: const ['เช้า', 'กลางวัน', 'เย็น'],
                    onDelete: () => _showSnackBar('ลบ: ยา'),
                  ),
                ],
              ),
            ),
            _buildDivider(),
            _buildSection(
              title: '13. Time Chips (ช่วงเวลา)',
              child: Column(
                children: [
                  const Text(
                    'ตัวอย่างช่วงเวลา (แสดงผลอย่างเดียว):',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      time_chip.AppTimeChip(
                        timeOfDay: time_chip.TimeOfDay.morning,
                        onTap: () => _showSnackBar('กดเช้า'),
                      ),
                      time_chip.AppTimeChip(
                        timeOfDay: time_chip.TimeOfDay.noon,
                        onTap: () => _showSnackBar('กดกลางวัน'),
                      ),
                      time_chip.AppTimeChip(
                        timeOfDay: time_chip.TimeOfDay.evening,
                        onTap: () => _showSnackBar('กดเย็น'),
                      ),
                      time_chip.AppTimeChip(
                        timeOfDay: time_chip.TimeOfDay.bedtime,
                        onTap: () => _showSnackBar('กดก่อนนอน'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'หรือแสดงแบบไม่มี interaction:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: const [
                      time_chip.AppTimeChip(
                        timeOfDay: time_chip.TimeOfDay.morning,
                      ),
                      time_chip.AppTimeChip(
                        timeOfDay: time_chip.TimeOfDay.noon,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _buildDivider(),
            _buildSection(
              title: '14. Medicine Reminder Card (ยาเดี่ยว)',
              child: Column(
                children: [
                  MedicineReminderCard(
                    medicineName: 'ชื่อยา',
                    dosage: '1 เม็ด',
                    scheduledTime: DateTime.now().add(const Duration(hours: 1)),
                    status: singleMedicine1Status,
                    onConfirm: () {
                      setState(() {
                        singleMedicine1Status = MedicineReminderStatus.taken;
                      });
                      _showSnackBar('ยืนยันการทานยาแล้ว');
                    },
                  ),
                  MedicineReminderCard(
                    medicineName: 'ชื่อยา',
                    dosage: '1 เม็ด',
                    scheduledTime: DateTime.now(),
                    status: singleMedicine2Status,
                  ),
                  MedicineReminderCard(
                    medicineName: 'ชื่อยา',
                    dosage: '1 เม็ด',
                    scheduledTime: DateTime.now().subtract(
                      const Duration(hours: 1),
                    ),
                    status: MedicineReminderStatus.pending,
                  ),
                ],
              ),
            ),
            _buildDivider(),
            _buildSection(
              title: '15. Medicine Box Reminder Card (กล่องยา)',
              child: Column(
                children: [
                  MedicineBoxReminderCard(
                    boxName: 'ชื่อกล่องยา',
                    medicines: const [
                      MedicineInBox(name: 'ชื่อยา', dosage: '1 เม็ด'),
                      MedicineInBox(name: 'ชื่อยา', dosage: '1 เม็ด'),
                    ],
                    scheduledTime: DateTime.now().add(const Duration(hours: 1)),
                    status: boxMedicineStatus,
                    onConfirm: () {
                      setState(() {
                        boxMedicineStatus = MedicineBoxReminderStatus.taken;
                      });
                      _showSnackBar('ยืนยันการทานยาในกล่องแล้ว');
                    },
                  ),
                  MedicineBoxReminderCard(
                    boxName: 'ชื่อกล่องยา',
                    medicines: const [
                      MedicineInBox(name: 'ชื่อยา', dosage: '1 เม็ด'),
                      MedicineInBox(name: 'ชื่อยา', dosage: '1 เม็ด'),
                    ],
                    scheduledTime: DateTime.now(),
                    status: MedicineBoxReminderStatus.taken,
                  ),
                  MedicineBoxReminderCard(
                    boxName: 'ชื่อกล่องยา',
                    medicines: const [
                      MedicineInBox(name: 'ชื่อยา', dosage: '1 เม็ด'),
                      MedicineInBox(name: 'ชื่อยา', dosage: '1 เม็ด'),
                    ],
                    scheduledTime: DateTime.now().subtract(
                      const Duration(hours: 1),
                    ),
                    status: MedicineBoxReminderStatus.pending,
                  ),
                ],
              ),
            ),
            _buildDivider(),
            _buildSection(
              title: '16. Buttons',
              child: Column(
                children: [
                  AppButton(
                    text: 'Primary Button',
                    onPressed: () {
                      _showSnackBar('Primary Button Clicked');
                    },
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    text: 'Outlined Button',
                    isOutlined: true,
                    onPressed: () {
                      _showSnackBar('Outlined Button Clicked');
                    },
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    text: 'Loading Button',
                    isLoading: true,
                    onPressed: () {},
                  ),
                  const SizedBox(height: 12),
                  AppButton(text: 'Disabled Button', onPressed: null),
                ],
              ),
            ),
            _buildDivider(),
            _buildSection(
              title: 'ตัวอย่างผลลัพธ์',
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildResultItem(
                      'Radio Selected',
                      selectedOption ?? 'ไม่ได้เลือก',
                    ),
                    _buildResultItem(
                      'Checkboxes Selected',
                      selectedCheckboxes.isEmpty
                          ? 'ไม่ได้เลือก'
                          : selectedCheckboxes.join(', '),
                    ),
                    _buildResultItem(
                      'Short Text',
                      shortTextController.text.isEmpty
                          ? 'ยังไม่ได้กรอก'
                          : shortTextController.text,
                    ),
                    _buildResultItem(
                      'Long Text',
                      longTextController.text.isEmpty
                          ? 'ยังไม่ได้กรอก'
                          : '${longTextController.text.length}/200 ตัวอักษร',
                    ),
                    _buildResultItem(
                      'Date Selected',
                      selectedDate?.toString().split(' ')[0] ?? 'ไม่ได้เลือก',
                    ),
                    _buildResultItem(
                      'Date Range Selected',
                      selectedDateRange != null
                          ? '${selectedDateRange!.start.toString().split(' ')[0]} - ${selectedDateRange!.end.toString().split(' ')[0]}'
                          : 'ไม่ได้เลือก',
                    ),
                    _buildResultItem(
                      'Slider Value',
                      sliderValue.toInt().toString(),
                    ),
                    _buildResultItem(
                      'Range Slider',
                      '${rangeSliderValues.start.toInt()} - ${rangeSliderValues.end.toInt()}',
                    ),
                    _buildResultItem(
                      'Single Image',
                      selectedImage != null ? 'เลือกแล้ว' : 'ยังไม่ได้เลือก',
                    ),
                    _buildResultItem(
                      'Multiple Images',
                      '${selectedImages.length} รูป',
                    ),
                    _buildResultItem(
                      'จังหวัดที่เลือก',
                      selectedProvince ?? 'ไม่ได้เลือก',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Divider(thickness: 1),
    );
  }

  Widget _buildResultItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}

// Helper widget สำหรับปุ่มเวลา
class _ActionChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}
