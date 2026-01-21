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
              title: '12. Buttons',
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
