import 'package:flutter/material.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:capyadoo/core/model/medication.dart';
import 'package:capyadoo/core/model/user_medication.dart';
import 'package:capyadoo/core/model/medication_box.dart';
import 'package:capyadoo/features/notifications/data/medication_search_service.dart';
import 'package:capyadoo/core/widgets/speech_to_text_field.dart';
import 'dart:async';

class UnifiedSelectionDialog extends StatefulWidget {
  final String userId;
  final String? title;
  final bool showMasterMedications;
  final bool showBoxes;
  final bool allowFreeText;

  /// โหลดรายการยาทั้งหมดแสดงทันทีเมื่อเปิด dialog (เหมาะกับหน้าเพิ่มยาในกล่อง)
  final bool loadAllMedicationsOnOpen;

  const UnifiedSelectionDialog({
    super.key,
    required this.userId,
    this.title,
    this.showMasterMedications = true,
    this.showBoxes = false,
    this.allowFreeText = true,
    this.loadAllMedicationsOnOpen = false,
  });

  @override
  State<UnifiedSelectionDialog> createState() => _UnifiedSelectionDialogState();
}

class _UnifiedSelectionDialogState extends State<UnifiedSelectionDialog>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final MedicationSearchService _searchService = MedicationSearchService();
  late TabController _tabController;

  List<dynamic> _medSuggestions = [];
  List<MedicationBox> _boxes = [];
  bool _isSearching = false;
  Timer? _debounce;
  int _lastSearchId = 0;

  // Speech-to-text

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.showBoxes ? 2 : 1,
      vsync: this,
    );
    if (widget.showBoxes) {
      _loadBoxes();
    }
    if (widget.loadAllMedicationsOnOpen) {
      _performSearch('');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBoxes() async {
    final boxes = await _searchService.getMedicationBoxes();
    if (mounted) {
      setState(() => _boxes = boxes);
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isSearching = true);
    final currentSearchId = ++_lastSearchId;

    try {
      final List<Future> futures = [];

      // Always search user medications
      futures.add(_searchService.searchUserMedications(widget.userId, query));

      // Always search master medications when enabled
      if (widget.showMasterMedications) {
        futures.add(_searchService.searchMasterMedications(query));
      }

      final results = await Future.wait(futures);

      if (currentSearchId != _lastSearchId) return;

      final userMedsResult = results[0] as List<UserMedication>;
      final masterMedsResult = widget.showMasterMedications
          ? results[1] as List<Medication>
          : <Medication>[];

      final List<dynamic> combinedList = [];
      final Set<String> seenIds = {};

      // 1. Process User Medications
      for (var med in userMedsResult) {
        combinedList.add(med);
        if (med.id != null) seenIds.add(med.id!);
        if (med.masterMedicationEntity?.id != null) {
          seenIds.add(med.masterMedicationEntity!.id!);
        }
      }

      // 2. Process Master Medications
      for (var med in masterMedsResult) {
        if (med.id != null && !seenIds.contains(med.id)) {
          combinedList.add(med);
          seenIds.add(med.id!);
        } else if (med.id == null) {
          final medName = med.name.toLowerCase();
          bool alreadyIn = combinedList.any((m) {
            if (m is UserMedication)
              return m.displayName.toLowerCase() == medName;
            if (m is Medication) return m.name.toLowerCase() == medName;
            return false;
          });
          if (!alreadyIn) combinedList.add(med);
        }
      }

      if (mounted) {
        setState(() {
          _medSuggestions = combinedList;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted && currentSearchId == _lastSearchId) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _onSelect(dynamic item) {
    if (item is Medication) {
      Navigator.pop(context, {
        'name': item.name,
        'id': item.id,
        'type': 'medication',
        'imagePath': null,
      });
    } else if (item is UserMedication) {
      Navigator.pop(
        context,
        {
          'name': item.displayName,
          'id': item.id,
          'type': 'user_medication',
          'imagePath': item.imagePath,
        },
      ); // Indication is usually where a generic image might be, but use null if not sure
    } else if (item is MedicationBox) {
      Navigator.pop(context, {
        'name': item.name,
        'id': item.id,
        'type': 'box',
        'imagePath': item.imagePath,
      });
    }
  }

  void _onManualSubmit() {
    if (!widget.allowFreeText) return;
    final text = _searchController.text.trim();
    if (text.isNotEmpty) {
      Navigator.pop(context, {
        'name': text,
        'id': null,
        'type': 'manual',
        'imagePath': null,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title ?? 'เพิ่มยา',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            if (widget.showBoxes)
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
            const SizedBox(height: 16),
            SizedBox(
              height: 350,
              child: TabBarView(
                controller: _tabController,
                physics: widget.showBoxes
                    ? null
                    : const NeverScrollableScrollPhysics(),
                children: [
                  // Medications Tab
                  _buildMedicationSearch(),
                  // Boxes Tab (if enabled)
                  if (widget.showBoxes) _buildBoxList(),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('ยกเลิก'),
                  ),
                ),
                if (widget.allowFreeText) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _onManualSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('เพิ่มด้วยชื่อ'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationSearch() {
    return Column(
      children: [
        SpeechToTextField(
          controller: _searchController,
          onSearch: () => _performSearch(_searchController.text),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'ค้นหายา...',
              filled: true,
              fillColor: Colors.blue[50],
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _medSuggestions.isEmpty && !_isSearching
              ? Center(
                  child: Text(
                    _searchController.text.isNotEmpty
                        ? 'ไม่พบยา "${_searchController.text}"'
                        : 'กรุณาค้นหาชื่อยาหรือพิมพ์ชื่อยาที่ต้องการเพิ่ม',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  itemCount: _medSuggestions.length,
                  itemBuilder: (context, index) {
                    final item = _medSuggestions[index];
                    String name = '';
                    String subtitle = '';
                    if (item is Medication) {
                      name = item.name;
                      subtitle = 'ยากลาง';
                    } else if (item is UserMedication) {
                      name = item.displayName;
                      subtitle = 'ยาของคุณ';
                    }
                    return ListTile(
                      title: Text(name),
                      subtitle: Text(
                        subtitle,
                        style: const TextStyle(fontSize: 12),
                      ),
                      leading: const Icon(Icons.medication_outlined),
                      onTap: () => _onSelect(item),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildBoxList() {
    if (_boxes.isEmpty) {
      return const Center(child: Text('ไม่พบกล่องยา'));
    }
    return ListView.builder(
      itemCount: _boxes.length,
      itemBuilder: (context, index) {
        final box = _boxes[index];
        return ListTile(
          title: Text(box.name),
          subtitle: Text(box.description ?? ''),
          leading: const Icon(Icons.inventory_2_outlined),
          onTap: () => _onSelect(box),
        );
      },
    );
  }
}
