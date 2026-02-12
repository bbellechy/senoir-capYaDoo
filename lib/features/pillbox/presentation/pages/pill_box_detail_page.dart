import 'dart:io';
import 'package:flutter/material.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:capyadoo/core/config/api_config.dart';
import 'package:capyadoo/core/model/user_medication.dart';
import 'package:capyadoo/core/model/medication_box.dart';
import 'package:capyadoo/features/pillbox/controller/pill_box_controller.dart';
import 'package:capyadoo/features/notifications/data/medication_search_service.dart';
import 'package:capyadoo/core/services/pill_box_service.dart';
import 'package:capyadoo/features/notifications/presentation/widgets/unified_selection_dialog.dart';
import 'package:capyadoo/core/services/auth_service.dart';
import 'package:capyadoo/core/widgets/app_nav_bar.dart';
import 'package:capyadoo/core/services/page_navigation_service.dart';

class PillBoxDetailPage extends StatefulWidget {
  final MedicationBox pillBox;

  const PillBoxDetailPage({super.key, required this.pillBox});

  @override
  State<PillBoxDetailPage> createState() => _PillBoxDetailPageState();
}

class _PillBoxDetailPageState extends State<PillBoxDetailPage> {
  final PillBoxController _controller = PillBoxController();
  final PillBoxService _pillBoxService = PillBoxService();
  final MedicationSearchService _searchService = MedicationSearchService();
  late MedicationBox _currentBox;

  List<UserMedication> _allUserMedications = [];
  bool _isLoading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _currentBox = widget.pillBox;
    _loadData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // 1. Fetch latest box contents from specific API (this will include updated medications)
      final boxDetails = await _pillBoxService.getBoxById(widget.pillBox.id!);

      // 2. Fetch all user medications
      if (_userId == null) {
        final profile = await AuthService.getProfile();
        _userId = profile?.id;
      }

      if (_userId != null) {
        // Refresh user medications to get latest data
        final userMeds = await _searchService.searchUserMedications(_userId!);
        if (mounted) {
          setState(() {
            if (boxDetails != null) {
              _currentBox = boxDetails;
              print('Box medications: ${_currentBox.medicationIds}');
            }
            _allUserMedications = userMeds;
            print(
              'All user medications: ${_allUserMedications.map((m) => m.id).toList()}',
            );
            print(
              'Medications in box: ${_medicationsInBox.map((m) => m['name'] ?? 'ไม่ระบุชื่อ').toList()}',
            );
            _isLoading = false;
          });
        }
      } else {
        // Fallback or handle unauthenticated
        if (mounted) setState(() => _isLoading = false);
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
  // Use medications from box directly, or match with user medications if available
  List<Map<String, dynamic>> get _medicationsInBox {
    // If box has medications array, use it directly
    if (_currentBox.medications.isNotEmpty) {
      return _currentBox.medications;
    }

    // Otherwise, try to match with user medications
    final matchedMeds = _allUserMedications
        .where((m) => _currentBox.medicationIds.contains(m.id))
        .map((m) => {'id': m.id, 'name': m.displayName})
        .toList();

    return matchedMeds;
  }

  Future<void> _removeMedicationFromBox(dynamic med) async {
    // med can be either UserMedication or Map<String, dynamic> from medications array
    String? medicationId;
    String medName;

    if (med is UserMedication) {
      medicationId = med.id;
      medName = med.name;
    } else if (med is Map<String, dynamic>) {
      medicationId = med['id']?.toString();
      medName = med['name']?.toString() ?? 'ไม่ระบุชื่อ';
    } else {
      return;
    }

    if (medicationId == null || medicationId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ไม่พบข้อมูลยา')));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบยาออกจากกล่อง'),
        content: Text('คุณต้องการลบ $medName ออกจากกล่องยานี้ใช่หรือไม่?'),
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

    if (confirm == true && _currentBox.id != null) {
      final boxId = _currentBox.id!;
      print('Removing medication id=$medicationId from box id=$boxId');
      final success = await _pillBoxService.removeMedicationFromBox(
        boxId,
        medicationId,
      );

      if (success) {
        // อัปเดต UI ทันที (optimistic): ลบยาออกจาก _currentBox เพื่อไม่ให้รายการค้างอยู่แม้ backend อาจยังไม่ลบจริง
        final newMedications = _currentBox.medications
            .where((m) => m['id']?.toString() != medicationId)
            .toList();
        final newIds = _currentBox.medicationIds
            .where((id) => id != medicationId)
            .toList();
        if (mounted) {
          setState(() {
            _currentBox = _currentBox.copyWith(
              medications: newMedications,
              medicationIds: newIds,
            );
          });
        }
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('ลบ $medName เรียบร้อยแล้ว')));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('ไม่สามารถลบยาได้')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      appBar: AppBar(
        title: Text(_currentBox.name),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header Section with Image
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    image: _currentBox.imagePath != null
                        ? DecorationImage(
                            image: FileImage(File(_currentBox.imagePath!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _currentBox.imagePath == null
                      ? const Icon(
                          Icons.inventory_2,
                          size: 48,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentBox.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currentBox.description ?? 'ไม่มีรายละเอียด',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Action Section: Title and Add Button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'รายการยาในกล่อง (${_medicationsInBox.length})',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
                TextButton.icon(
                  onPressed: _showAddMedicationPopup,
                  icon: const Icon(
                    Icons.add_circle,
                    color: AppColors.primaryBlue,
                  ),
                  label: const Text(
                    'เพิ่มยา',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Medication List Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildMedicationList(_medicationsInBox),
          ),
        ],
      ),
      bottomNavigationBar: AppNavBar(
        currentIndex: 0, // Highlight home as it's the root for this
        onTap: _onNavBarTap,
      ),
    );
  }

  void _onNavBarTap(int index) {
    // Navigate back to MainLayout and set index
    Navigator.of(context).popUntil((route) => route.isFirst);
    PageNavigationService().setIndex(index);
  }

  Widget _buildMedicationList(List<Map<String, dynamic>> meds) {
    if (meds.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.medication_outlined,
                  size: 64,
                  color: Colors.blue[200],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'กรุณาค้นหาชื่อยาหรือพิมพ์ชื่อยาที่ต้องการเพิ่ม',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: meds.length,
      itemBuilder: (context, index) {
        final med = meds[index];
        final medId = med['id'] as String? ?? '';
        final medName = med['name'] as String? ?? 'ไม่ระบุชื่อ';

        // Try to find matching user medication for image
        UserMedication? userMed;
        try {
          userMed = _allUserMedications.firstWhere((m) => m.id == medId);
        } catch (e) {
          try {
            userMed = _allUserMedications.firstWhere(
              (m) => m.displayName == medName,
            );
          } catch (e2) {
            userMed = null;
          }
        }
        final resolvedPath = userMed != null
            ? _resolveImagePath(userMed.imagePath)
            : null;
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  image: resolvedPath != null && resolvedPath.isNotEmpty
                      ? DecorationImage(
                          image: resolvedPath.startsWith('http')
                              ? NetworkImage(resolvedPath) as ImageProvider
                              : FileImage(File(resolvedPath)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: resolvedPath == null || resolvedPath.isEmpty
                    ? Icon(Icons.medication, color: AppColors.primaryBlue)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (userMed != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${userMed.dosage ?? "-"} ${userMed.unit ?? "-"}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      // Timing tags
                      Wrap(spacing: 8, children: _buildTimingTags(userMed)),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () {
                  // Use medication from box directly (med object from _medicationsInBox)
                  _removeMedicationFromBox(med);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildTimingTags(UserMedication med) {
    if (med.intakePeriods == null || med.intakePeriods!.isEmpty) return [];

    final periods = med.intakePeriods!;
    return periods.map((p) {
      Color color;
      String label;
      switch (p.trim().toLowerCase()) {
        case 'morning':
          color = const Color(0xFFFFF9C4);
          label = 'เช้า';
          break;
        case 'noon':
          color = const Color(0xFFFFE0B2);
          label = 'กลางวัน';
          break;
        case 'evening':
          color = const Color(0xFFE1F5FE);
          label = 'เย็น';
          break;
        case 'bedtime':
          color = const Color(0xFFEDE7F6);
          label = 'ก่อนนอน';
          break;
        default:
          color = Colors.grey[200]!;
          label = p;
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      );
    }).toList();
  }

  void _showAddMedicationPopup() async {
    if (_userId == null) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => UnifiedSelectionDialog(
        userId: _userId!,
        title: 'เพิ่มยาลงในกล่อง',
        showMasterMedications: true,
        showBoxes: false,
        allowFreeText: true,
        loadAllMedicationsOnOpen: false,
      ),
    );

    if (result != null) {
      final medName = result['name'] as String;
      final medId = result['id'] as String?;
      final type = result['type'] as String?;

      setState(() => _isLoading = true);

      bool success = false;

      if (type == 'user_medication' && medId != null) {
        // Already a user medication - use medicationId parameter
        success = await _controller.addMedicationToBox(
          _currentBox.id!,
          medicationId: medId,
        );
      } else if (type == 'medication' && medId != null) {
        // Master medication - use masterMedicationId parameter
        success = await _controller.addMedicationToBox(
          _currentBox.id!,
          masterMedicationId: medId,
        );
      } else if (type == 'manual' || (type == null && medId == null)) {
        // Manual input - use medicationName parameter
        success = await _controller.addMedicationToBox(
          _currentBox.id!,
          medicationName: medName,
        );
      }

      if (success) {
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('เพิ่ม $medName แล้ว')));
        }
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_controller.error ?? 'ไม่สามารถเพิ่มยาได้')),
          );
        }
      }
    }
  }

  String? _resolveImagePath(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;

    // Check if it's an absolute local path
    if (path.contains(':') ||
        path.startsWith('/') ||
        path.contains('Documents/') ||
        path.contains('data/user/')) {
      return path;
    }

    if (path.startsWith('uploads/')) {
      return '${ApiConfig.baseUrl}/$path';
    }

    return '${ApiConfig.baseUrl}/$path';
  }
}
