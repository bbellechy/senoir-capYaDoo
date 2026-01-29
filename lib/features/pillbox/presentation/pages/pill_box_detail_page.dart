import 'dart:io';
import 'package:flutter/material.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:capyadoo/core/model/user_medication.dart';
import 'package:capyadoo/core/model/medication_box.dart';
import 'package:capyadoo/features/pillbox/controller/pill_box_controller.dart';
import 'package:capyadoo/features/notifications/data/medication_search_service.dart';
import 'package:capyadoo/core/services/pill_box_service.dart';

class PillBoxDetailPage extends StatefulWidget {
  final MedicationBox pillBox;

  const PillBoxDetailPage({super.key, required this.pillBox});

  @override
  State<PillBoxDetailPage> createState() => _PillBoxDetailPageState();
}

class _PillBoxDetailPageState extends State<PillBoxDetailPage>
    with SingleTickerProviderStateMixin {
  final PillBoxController _controller = PillBoxController();
  final PillBoxService _pillBoxService = PillBoxService();
  final MedicationSearchService _searchService = MedicationSearchService();
  late MedicationBox _currentBox;
  late TabController _tabController;

  List<UserMedication> _allUserMedications = [];
  bool _isLoading = true;
  final String _userId = 'c9905ab5-dfe0-44b7-890f-64ec92790b14'; // Demo User ID

  @override
  void initState() {
    super.initState();
    _currentBox = widget.pillBox;
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // 1. Fetch latest box contents from specific API
      final boxDetails = await _pillBoxService.getBoxById(widget.pillBox.id!);

      // 2. Fetch all user medications
      final userMeds = await _searchService.getUserMedications(_userId);

      if (mounted) {
        setState(() {
          if (boxDetails != null) _currentBox = boxDetails;
          _allUserMedications = userMeds;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  // Section 1: Medications in this box
  List<UserMedication> get _medicationsInBox {
    return _allUserMedications
        .where((m) => _currentBox.medicationIds.contains(m.id))
        .toList();
  }

  // Section 2: Available medications to add (Exclude medications already in the box)
  List<UserMedication> get _availableMedications {
    return _allUserMedications
        .where((m) => !_currentBox.medicationIds.contains(m.id))
        .toList();
  }

  Future<void> _addMedicationToBox(UserMedication med) async {
    if (med.id == null || _currentBox.id == null) return;

    final success = await _pillBoxService.addMedicationToBox(
      _currentBox.id!,
      med.id!,
    );

    if (success) {
      // Refresh data to reflect changes
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เพิ่ม ${med.name} ลงในกล่องแล้ว')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ไม่สามารถเพิ่มยาได้')));
      }
    }
  }

  Future<void> _removeMedicationFromBox(UserMedication med) async {
    // Current backend doesn't seem to have a specific DELETE /medications/{id} for boxes provided in requirements
    // but the controller was using removeMedicationFromBox. We'll stick to controller for removal if needed,
    // or assume the PUT update is the way for removal for now unless requirements specify otherwise.
    // Given Requirement 3 says "Allow users to add... using POST", but doesn't mention delete endpoint,
    // I'll keep the previous removal logic via controller if it worked.

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบยาออกจากกล่อง'),
        content: Text('คุณต้องการลบ ${med.name} ออกจากกล่องยานี้ใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && med.id != null) {
      final success = await _controller.removeMedicationFromBox(
        _currentBox.id!,
        med.id!,
      );

      if (success) {
        await _loadData();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ไม่สามารถลบยาได้')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentBox.name),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.white,
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    image: _currentBox.imagePath != null
                        ? DecorationImage(
                            image: FileImage(File(_currentBox.imagePath!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _currentBox.imagePath == null
                      ? Icon(
                          Icons.inventory_2,
                          size: 32,
                          color: AppColors.primaryBlue,
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentBox.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_currentBox.description?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 4),
                        Text(
                          _currentBox.description!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // TabBar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primaryBlue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.primaryBlue,
              tabs: [
                Tab(text: 'ยาในกล่อง (${_medicationsInBox.length})'),
                Tab(text: 'ยาที่เพิ่มได้'),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMedicationList(_medicationsInBox, true),
                      _buildMedicationList(_availableMedications, false),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationList(List<UserMedication> meds, bool isInBox) {
    if (meds.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.medication_outlined,
                size: 48,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 16),
              Text(
                isInBox
                    ? 'ยังไม่มียาในกล่องนี้'
                    : 'ไม่มียาที่สามารถเพิ่มได้แล้ว',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: meds.length,
      itemBuilder: (context, index) {
        final med = meds[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundColor: Colors.blue[50],
              child: Icon(Icons.medication, color: AppColors.primaryBlue),
            ),
            title: Text(
              med.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: isInBox
                ? IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _removeMedicationFromBox(med),
                  )
                : IconButton(
                    icon: Icon(
                      Icons.add_circle_outline,
                      color: AppColors.primaryBlue,
                    ),
                    onPressed: () => _addMedicationToBox(med),
                  ),
          ),
        );
      },
    );
  }
}
