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
            backgroundColor: AppColors.error,
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
    const double headerHeight = 175;
    const double searchBoxHeight = 80;

    return Scaffold(
      backgroundColor: AppColors.offwhite,
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                height: headerHeight,
                width: double.infinity,
                color: AppColors.primaryBlue,
                child: SafeArea(
                  bottom: false,
                  child: Stack(
                    children: [
                      Positioned(
                        right: -50,
                        top: -50,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                      ),
                      Positioned(
                        left: -30,
                        bottom: -30,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: (searchBoxHeight / 2) + 12,
                        child: const Center(
                          child: Text(
                            'ค้นหายา',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Sarabun',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: searchBoxHeight / 2 + 12),
                  child: _buildContent(),
                ),
              ),
            ],
          ),
          Positioned(
            top: headerHeight - (searchBoxHeight / 2),
            left: 16,
            right: 16,
            child: Container(
              height: searchBoxHeight,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SpeechToTextField(
                controller: _searchController,
                onSearch: search,
                child: TextField(
                  controller: _searchController,
                  textAlignVertical: TextAlignVertical.center,
                  style: const TextStyle(fontSize: 16, height: 1.2),
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
                    isDense: true,
                    hintText: 'ค้นหายาที่ต้องการ...',
                    hintStyle: TextStyle(
                      color: AppColors.textSub,
                      fontSize: 20,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppColors.textSub,
                      size: 26,
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 56,
                      minHeight: 80,
                    ),
                    suffixIconConstraints: const BoxConstraints(
                      minWidth: 56,
                      minHeight: 80,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 0,
                    ),
                  ),
                ),
              ),
            ),
          ),
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
              color: AppColors.primaryBlue,
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              'กำลังค้นหา...',
              style: TextStyle(color: AppColors.textSub, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (!hasSearched) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Align(
          alignment: Alignment.topCenter,
          child: AppEmptyCard(
            icon: Icons.search_rounded,
            title: 'ค้นหายา',
            subtitle: 'ค้นหายาเพื่อดูข้อมูลรายละเอียด',
            iconColor: AppColors.textSublest,
            borderColor: AppColors.blueBorder,
            borderRadius: 10,
            borderWidth: 2,
          ),
        ),
      );
    }

    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Align(
          alignment: Alignment.topCenter,
          child: AppEmptyCard(
            icon: Icons.search_off_rounded,
            title: 'ไม่พบรายการยา',
            subtitle: 'ไม่พบยาที่คุณค้นหา กรุณาลองตรวจสอบชื่อยาอีกครั้ง',
            iconColor: AppColors.textSublest,
            borderColor: AppColors.blueBorder,
            borderRadius: 10,
            borderWidth: 2,
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.blueBorder, width: 2),
        ),
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
                          color: AppColors.textPrimary,
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
                            fontSize: 16,
                            color: AppColors.textSub,
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
                          color: AppColors.textSub,
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
                            fontSize: 16,
                            color: AppColors.textSub,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.textSub, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
