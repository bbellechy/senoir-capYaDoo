import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

  String _normalizeKey(String s) {
    return s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

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
      final Set<String> seenNameKeys = {};

      // 1. Process User Medications
      for (var med in userMedsResult) {
        final nameKey = _normalizeKey(med.displayName);
        // De-dup by displayed name to avoid duplicate UI entries
        // (e.g., same medication created twice or coming from multiple sources)
        if (nameKey.isNotEmpty && seenNameKeys.contains(nameKey)) {
          continue;
        }
        if (nameKey.isNotEmpty) {
          seenNameKeys.add(nameKey);
        }
        combinedList.add(med);
        if (med.id != null) seenIds.add(med.id!);
        if (med.masterMedicationEntity?.id != null) {
          seenIds.add(med.masterMedicationEntity!.id!);
        }
      }

      // 2. Process Master Medications
      for (var med in masterMedsResult) {
        final nameKey = _normalizeKey(med.name);
        if (nameKey.isNotEmpty && seenNameKeys.contains(nameKey)) {
          continue;
        }
        if (med.id != null && !seenIds.contains(med.id)) {
          combinedList.add(med);
          seenIds.add(med.id!);
          if (nameKey.isNotEmpty) seenNameKeys.add(nameKey);
        } else if (med.id == null) {
          // Fallback: no ID -> de-dup by nameKey
          if (nameKey.isNotEmpty && !seenNameKeys.contains(nameKey)) {
            combinedList.add(med);
            seenNameKeys.add(nameKey);
          }
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title ?? 'เพิ่มยา',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, size: 24.sp),
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
            SizedBox(height: 16.h),
            SizedBox(
              height: 350.h,
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
            SizedBox(height: 16.h),
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
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text('ยกเลิก', style: TextStyle(fontSize: 16.sp)),
                  ),
                ),
                if (widget.allowFreeText) ...[
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _onManualSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text('บันทึก', style: TextStyle(fontSize: 16.sp)),
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
            style: TextStyle(fontSize: 16.sp),
            decoration: InputDecoration(
              hintText: 'ค้นหายา...',
              filled: true,
              fillColor: Colors.blue[50],
              prefixIcon: Icon(Icons.search, size: 24.sp),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              suffixIcon: _isSearching
                  ? Padding(
                      padding: EdgeInsets.all(12.r),
                      child: SizedBox(
                        width: 20.w,
                        height: 20.h,
                        child: CircularProgressIndicator(strokeWidth: 2.w),
                      ),
                    )
                  : null,
            ),
          ),
        ),
        SizedBox(height: 12.h),
        Expanded(
          child: _medSuggestions.isEmpty && !_isSearching
              ? Center(
                  child: Text(
                    _searchController.text.isNotEmpty
                        ? 'ไม่พบยา "${_searchController.text}"'
                        : 'กรุณาค้นหาชื่อยาหรือพิมพ์ชื่อยาที่ต้องการเพิ่ม',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14.sp),
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
                      title: Text(name, style: TextStyle(fontSize: 16.sp)),
                      subtitle: Text(
                        subtitle,
                        style: TextStyle(fontSize: 12.sp),
                      ),
                      leading: Icon(Icons.medication_outlined, size: 24.sp),
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
      return Center(child: Text('ไม่พบกล่องยา', style: TextStyle(fontSize: 14.sp)));
    }
    return ListView.builder(
      itemCount: _boxes.length,
      itemBuilder: (context, index) {
        final box = _boxes[index];
        return ListTile(
          title: Text(box.name, style: TextStyle(fontSize: 16.sp)),
          subtitle: Text(box.description ?? '', style: TextStyle(fontSize: 14.sp)),
          leading: Icon(Icons.inventory_2_outlined, size: 24.sp),
          onTap: () => _onSelect(box),
        );
      },
    );
  }
}
