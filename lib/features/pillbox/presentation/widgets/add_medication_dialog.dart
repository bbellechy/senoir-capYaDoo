import 'package:flutter/material.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:capyadoo/core/model/medication.dart';
import 'package:capyadoo/core/model/user_medication.dart';
import 'package:capyadoo/features/notifications/data/medication_search_service.dart';
import 'package:capyadoo/core/widgets/speech_to_text_field.dart';
import 'dart:async';

class AddMedicationDialog extends StatefulWidget {
  final String userId;
  final String boxName;

  const AddMedicationDialog({
    super.key,
    required this.userId,
    required this.boxName,
  });

  @override
  State<AddMedicationDialog> createState() => _AddMedicationDialogState();
}

class _AddMedicationDialogState extends State<AddMedicationDialog> {
  final _searchController = TextEditingController();
  final MedicationSearchService _searchService = MedicationSearchService();

  List<dynamic> _suggestions = [];
  bool _isSearching = false;
  Timer? _debounce;

  // Speech-to-text

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        _performSearch(query);
      } else {
        setState(() => _suggestions = []);
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isSearching = true);
    try {
      // Fetch from both sources
      final results = await Future.wait([
        _searchService.searchMasterMedications(query),
        _searchService.searchUserMedications(widget.userId, query),
      ]);

      final masterMeds = results[0] as List<Medication>;
      final userMeds = results[1] as List<UserMedication>;

      if (mounted) {
        setState(() {
          // Combine and deduplicate if necessary, here we just show both
          _suggestions = [...masterMeds, ...userMeds];
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _onSelectMedication(dynamic med) {
    String name;
    String? id;

    if (med is Medication) {
      name = med.name;
      id = med.id;
    } else if (med is UserMedication) {
      name = med.displayName;
      id = med.id;
    } else {
      name = med.toString();
    }

    Navigator.pop(context, {
      'name': name,
      'id': id,
      'type': med is UserMedication ? 'user_medication' : 'medication',
    });
  }

  void _onManualSubmit() {
    final text = _searchController.text.trim();
    if (text.isNotEmpty) {
      Navigator.pop(context, {'name': text, 'id': null});
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
                const Text(
                  'เพิ่มยาในกล่อง',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Text(
              'เลือกยาที่ต้องการเพิ่มในกล่อง "${widget.boxName}"',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 24),
            const Text(
              'ชื่อยา',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SpeechToTextField(
              controller: _searchController,
              onSearch: () => _performSearch(_searchController.text),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'เลือกยา...',
                  filled: true,
                  fillColor: Colors.blue[50],
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
            const SizedBox(height: 16),
            if (_suggestions.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = _suggestions[index];
                    String name = '';
                    if (suggestion is Medication) {
                      name = suggestion.name;
                    } else if (suggestion is UserMedication) {
                      name = suggestion.displayName;
                    }

                    return ListTile(
                      title: Text(name),
                      onTap: () => _onSelectMedication(suggestion),
                    );
                  },
                ),
              ),
            const SizedBox(height: 24),
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
                    child: const Text('เพิ่มยา'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
