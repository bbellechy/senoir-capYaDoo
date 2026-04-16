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
import 'package:capyadoo/core/widgets/delete_dialog.dart';
import 'package:capyadoo/features/pillbox/presentation/widgets/simple_medicine_list_card.dart';

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
      final boxDetails = await _pillBoxService.getBoxById(widget.pillBox.id!);

      if (_userId == null) {
        final profile = await AuthService.getProfile();
        _userId = profile?.id;
      }

      if (_userId != null) {
        final userMeds = await _searchService.searchUserMedications(_userId!);
        if (mounted) {
          setState(() {
            if (boxDetails != null) {
              _currentBox = boxDetails;
            }
            _allUserMedications = userMeds;
            _isLoading = false;
          });
        }
      } else {
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

  List<Map<String, dynamic>> get _medicationsInBox {
    if (_currentBox.medications.isNotEmpty) {
      final meds = List<Map<String, dynamic>>.from(_currentBox.medications);
      meds.sort((a, b) {
        final an = (a['name']?.toString() ?? '').trim().toLowerCase();
        final bn = (b['name']?.toString() ?? '').trim().toLowerCase();
        final byName = an.compareTo(bn);
        if (byName != 0) return byName;
        final ai = (a['id']?.toString() ?? '');
        final bi = (b['id']?.toString() ?? '');
        return ai.compareTo(bi);
      });
      return meds;
    }

    final matchedMeds =
        _allUserMedications
            .where((m) => _currentBox.medicationIds.contains(m.id))
            .map((m) => {'id': m.id, 'name': m.displayName})
            .toList()
          ..sort((a, b) {
            final an = (a['name']?.toString() ?? '').trim().toLowerCase();
            final bn = (b['name']?.toString() ?? '').trim().toLowerCase();
            final byName = an.compareTo(bn);
            if (byName != 0) return byName;
            final ai = (a['id']?.toString() ?? '');
            final bi = (b['id']?.toString() ?? '');
            return ai.compareTo(bi);
          });

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

    final confirm = await showDeleteDialog(
      context,
      title: 'ลบยาออกจากกล่อง',
      message: 'คุณต้องการลบ $medName ออกจากกล่องยานี้ใช่หรือไม่?',
      cancelText: 'ยกเลิก',
      confirmText: 'ลบ',
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
    print('DEBUG build: _medicationsInBox.length: ${_medicationsInBox.length}');
    print(
      'DEBUG build: _currentBox.medications.length: ${_currentBox.medications.length}',
    );
    print('DEBUG build: _isLoading: $_isLoading');
    return Scaffold(
      backgroundColor: AppColors.offwhite,
      body: Column(
        children: [
          // Header section: back arrow + box info in the same row
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 24, 24),
            decoration: const BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            image: _currentBox.imagePath != null
                                ? DecorationImage(
                                    image: FileImage(
                                      File(_currentBox.imagePath!),
                                    ),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _currentBox.imagePath == null
                              ? const Icon(
                                  Icons.inventory_2,
                                  size: 44,
                                  color: Colors.white,
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
                ],
              ),
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
                    fontWeight: FontWeight.w600,
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
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildBoxImage() {
    return Container(
      width: 88,
      height: 88,
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
          ? const Icon(Icons.inventory_2, size: 44, color: Colors.white)
          : null,
    );
  }

  Widget _buildBoxInfo() {
    return Column(
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
          style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.8)),
        ),
      ],
    );
  }

  Widget _buildMedicationList(List<Map<String, dynamic>> meds) {
    print('DEBUG _buildMedicationList: meds count: ${meds.length}');
    print('DEBUG _buildMedicationList: meds: $meds');
    if (meds.isEmpty) {
      print('DEBUG _buildMedicationList: meds is empty, showing empty state');
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
                'เพิ่มยาเพื่อจัดการกล่องยาของคุณ',
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
        final amountText = _formatAmountText(userMed);
        final mealTimes = userMed != null
            ? _toThaiMealTimes(userMed.intakePeriods ?? const [])
            : <String>[];

        return SimpleMedicineListCard(
          icon: Icons.medication,
          iconColor: AppColors.primaryBlue,
          iconBackgroundColor: AppColors.subBlue.withValues(alpha: 0.45),
          name: medName,
          amount: amountText,
          mealTimes: mealTimes,
          onDelete: () => _removeMedicationFromBox(med),
        );
      },
    );
  }

  List<String> _toThaiMealTimes(List<String> intakePeriods) {
    final mapped = <String>[];
    for (final p in intakePeriods) {
      switch (p.trim().toLowerCase()) {
        case 'morning':
          mapped.add('เช้า');
          break;
        case 'noon':
          mapped.add('กลางวัน');
          break;
        case 'evening':
          mapped.add('เย็น');
          break;
        case 'bedtime':
          mapped.add('ก่อนนอน');
          break;
      }
    }
    return mapped;
  }

  String _formatAmountText(UserMedication? userMed) {
    if (userMed == null) return '1 เม็ด';

    final rawDose = userMed.dosage?.toString().trim() ?? '';
    final rawUnit = userMed.unit?.toString().trim() ?? '';

    final unit = rawUnit.isEmpty ? 'เม็ด' : rawUnit;
    if (rawDose.isEmpty) return '1 $unit';

    final doseNumber = num.tryParse(rawDose);
    if (doseNumber != null && doseNumber == doseNumber.roundToDouble()) {
      return '${doseNumber.toInt()} $unit';
    }

    return '$rawDose $unit';
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
        showMasterMedications: false,
        showBoxes: false,
        allowFreeText: false,
        loadAllMedicationsOnOpen: true,
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
        // Backend also requires medicationName or masterMedicationId
        success = await _controller.addMedicationToBox(
          _currentBox.id!,
          medicationId: medId,
          medicationName: medName,
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
