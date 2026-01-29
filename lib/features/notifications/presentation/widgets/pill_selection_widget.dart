import 'package:flutter/material.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:capyadoo/core/model/medication.dart';
import 'package:capyadoo/core/model/medication_box.dart';
import 'package:capyadoo/features/notifications/data/medication_search_service.dart';
import 'package:capyadoo/core/services/pill_box_service.dart';
import 'dart:io';

class PillSelectionWidget extends StatefulWidget {
  final String? initialValue;
  final String? initialImagePath;
  final Function(String name, String? imagePath) onSelected;

  const PillSelectionWidget({
    super.key,
    this.initialValue,
    this.initialImagePath,
    required this.onSelected,
  });

  @override
  State<PillSelectionWidget> createState() => _PillSelectionWidgetState();
}

class _PillSelectionWidgetState extends State<PillSelectionWidget> {
  final MedicationSearchService _searchService = MedicationSearchService();
  String? _selectedName;
  String? _selectedImagePath;
  final String _userId =
      'c9905ab5-dfe0-44b7-890f-64ec92790b14'; // From user request

  @override
  void initState() {
    super.initState();
    _selectedName = widget.initialValue;
    _selectedImagePath = widget.initialImagePath;
  }

  void _showSelectionDialog() async {
    final result = await showDialog<Map<String, String?>>(
      context: context,
      builder: (context) =>
          _SelectionDialog(searchService: _searchService, userId: _userId),
    );

    if (result != null) {
      setState(() {
        _selectedName = result['name'];
        _selectedImagePath = result['imagePath'];
      });
      widget.onSelected(_selectedName!, _selectedImagePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      text: 'เลือกยา/กล่องยา ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                      children: const [
                        TextSpan(
                          text: '*',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _showSelectionDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedName ?? 'เลือกยาหรือกล่องยา',
                              style: TextStyle(
                                color: _selectedName != null
                                    ? Colors.black87
                                    : Colors.grey[500],
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Avatar/Image preview
            Padding(
              padding: const EdgeInsets.only(top: 25),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                  image: _selectedImagePath != null
                      ? DecorationImage(
                          image: _selectedImagePath!.startsWith('http')
                              ? NetworkImage(_selectedImagePath!)
                              : FileImage(File(_selectedImagePath!))
                                    as ImageProvider,
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _selectedImagePath == null
                    ? Icon(
                        Icons.medication_outlined,
                        color: Colors.grey[400],
                        size: 30,
                      )
                    : null,
              ),
            ),
          ],
        ),
        if (_selectedName != null) ...[
          const SizedBox(height: 8),
          Text(
            '*หากเลือกกล่องยาจะแจ้งเตือนสำหรับยาทุกตัวในกล่อง',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}

class _SelectionDialog extends StatefulWidget {
  final MedicationSearchService searchService;
  final String userId;

  const _SelectionDialog({required this.searchService, required this.userId});

  @override
  State<_SelectionDialog> createState() => _SelectionDialogState();
}

class _SelectionDialogState extends State<_SelectionDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Medication> _medications = [];
  List<MedicationBox> _boxes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      widget.searchService.searchMedications(widget.userId),
      widget.searchService.getMedicationBoxes(),
    ]);

    if (mounted) {
      setState(() {
        _medications = results[0] as List<Medication>;
        _boxes = results[1] as List<MedicationBox>;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primaryBlue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primaryBlue,
            tabs: const [
              Tab(text: 'ยา'),
              Tab(text: 'กล่องยา'),
            ],
          ),
          SizedBox(
            height: 300,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // Medications tab
                      _medications.isEmpty
                          ? const Center(child: Text('ไม่พบข้อมูล'))
                          : ListView.builder(
                              itemCount: _medications.length,
                              itemBuilder: (context, index) {
                                final med = _medications[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.grey[200],
                                    child: const Icon(
                                      Icons.medication,
                                      size: 20,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  title: Text(med.name),
                                  onTap: () async {
                                    // Try to find image from box
                                    final pillBoxService = PillBoxService();
                                    final imagePath = med.id != null
                                        ? await pillBoxService
                                              .getImageForMedication(med.id!)
                                        : null;
                                    if (mounted) {
                                      Navigator.pop(context, {
                                        'name': med.name,
                                        'imagePath': imagePath,
                                      });
                                    }
                                  },
                                );
                              },
                            ),
                      // Boxes tab
                      _boxes.isEmpty
                          ? const Center(child: Text('ไม่พบข้อมูล'))
                          : ListView.builder(
                              itemCount: _boxes.length,
                              itemBuilder: (context, index) {
                                final box = _boxes[index];
                                return ListTile(
                                  leading: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      shape: BoxShape.circle,
                                      image: box.imagePath != null
                                          ? DecorationImage(
                                              image:
                                                  box.imagePath!.startsWith(
                                                    'http',
                                                  )
                                                  ? NetworkImage(box.imagePath!)
                                                  : FileImage(
                                                          File(box.imagePath!),
                                                        )
                                                        as ImageProvider,
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: box.imagePath == null
                                        ? const Icon(
                                            Icons.inventory_2,
                                            size: 20,
                                            color: Colors.grey,
                                          )
                                        : null,
                                  ),
                                  title: Text(box.name),
                                  onTap: () => Navigator.pop(context, {
                                    'name': box.name,
                                    'imagePath': box.imagePath,
                                  }),
                                );
                              },
                            ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
