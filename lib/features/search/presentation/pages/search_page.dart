import 'package:flutter/material.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import '../../../../core/model/medication.dart';
import '../../../../features/notifications/data/medication_search_service.dart';
import '../../../../core/widgets/speech_to_text_field.dart';
import 'medication_detail_page.dart';
import 'package:capyadoo/core/widgets/app_empty_card.dart';

class SearchPage extends StatefulWidget {
  final bool isSelectionMode;
  const SearchPage({super.key, this.isSelectionMode = false});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();

  bool loading = false;
  List<dynamic> results = []; // Can contain both Medication and UserMedication
  bool hasSearched = false;
  int _lastSearchId = 0;
  final MedicationSearchService _searchService = MedicationSearchService();

  String displayTradeName(String? th, String? en) {
    bool hasTh = th != null && th.trim().isNotEmpty && th.trim() != '-';
    bool hasEn = en != null && en.trim().isNotEmpty && en.trim() != '-';

    if (!hasTh && !hasEn) {
      return '-';
    }

    if (hasTh && hasEn) {
      return '$th ($en)';
    }

    return hasTh ? th : en ?? '-';
  }

  String? displayDoseForm(String? th, String? en) {
    bool hasTh = th != null && th.trim().isNotEmpty && th.trim() != '-';
    bool hasEn = en != null && en.trim().isNotEmpty && en.trim() != '-';

    if (!hasTh && !hasEn) {
      return null;
    }

    return hasTh ? th : en;
  }

  @override
  void initState() {
    super.initState();
  }

  void search() async {
    if (_searchController.text.trim().isEmpty) {
      if (mounted) {
        setState(() {
          results = [];
          hasSearched = false;
        });
      }
      return;
    }

    setState(() {
      loading = true;
      hasSearched = true;
    });

    final currentSearchId = ++_lastSearchId;

    try {
      final query = _searchController.text.trim();

      // Only search master medications
      final List<Medication> masterMeds = await _searchService
          .searchMasterMedications(query);

      // Check if this is still the latest search
      if (currentSearchId != _lastSearchId) return;

      if (mounted) {
        setState(() {
          results = masterMeds;
        });
      }
    } catch (e) {
      print('Search error: $e');
      if (mounted && currentSearchId == _lastSearchId) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('ค้นหาไม่สำเร็จ กรุณาลองใหม่อีกครั้ง'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }

    if (mounted && currentSearchId == _lastSearchId) {
      setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Top Blue Header
          Container(
            height: 200,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  // Decorative Circles
                  Positioned(
                    right: -40,
                    top: -40,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -20,
                    bottom: -20,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          color: Colors.white70,
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'ค้นหายา',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Sarabun',
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: SpeechToTextField(
                      controller: _searchController,
                      onSearch: search,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          if (value.isEmpty) {
                            setState(() {
                              results = [];
                              hasSearched = false;
                            });
                          }
                        },
                        onSubmitted: (_) => search(),
                        decoration: InputDecoration(
                          hintText: 'ค้นหายาที่ต้องการ...',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey.shade600,
                            size: 22,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content Section
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: const Color(0xFF2196F3),
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              'กำลังค้นหา...',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (!hasSearched) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: AppEmptyCard(
            icon: Icons.search_rounded,
            title: 'ค้นหายา',
            subtitle: 'ค้นหายาเพื่อดูข้อมูลและวิธีการทานยาอย่างละเอียด',
          ),
        ),
      );
    }

    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: AppEmptyCard(
            icon: Icons.search_off_rounded,
            title: 'ไม่พบรายการยา',
            subtitle: 'ไม่พบยาที่คุณค้นหา กรุณาลองตรวจสอบชื่อยาอีกครั้ง',
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        return _buildMedicationCard(item);
      },
    );
  }

  Widget _buildMedicationCard(Medication medication) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.05),
        child: InkWell(
          onTap: () {
            if (widget.isSelectionMode) {
              Navigator.pop(context, medication);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MedicationDetailPage(medication: medication),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayTradeName(
                          medication.tradenameTh,
                          medication.tradenameEn,
                        ),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (displayDoseForm(
                            medication.doseFormTh,
                            medication.doseFormEn,
                          ) !=
                          null) ...[
                        Text(
                          'รูปแบบยา: ${displayDoseForm(medication.doseFormTh, medication.doseFormEn)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                      ],
                      Text(
                        'สรรพคุณ: ${medication.indication ?? "-"}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (medication.categoryUse != null &&
                          medication.categoryUse!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'การใช้ประโยชน์: ${medication.categoryUse}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
