import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
  String _lastSearchedQuery = '';
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
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      if (mounted) {
        setState(() {
          results = [];
          hasSearched = false;
          _lastSearchedQuery = '';
        });
      }
      return;
    }

    setState(() {
      loading = true;
      hasSearched = true;
      _lastSearchedQuery = query;
    });

    final currentSearchId = ++_lastSearchId;

    try {
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
            content: Text(
              'ค้นหาไม่สำเร็จ กรุณาลองใหม่อีกครั้ง',
              style: TextStyle(fontFamily: 'Sarabun', fontSize: 14.sp),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    if (mounted && currentSearchId == _lastSearchId) {
      setState(() => loading = false);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    FocusScope.of(context).unfocus();
    setState(() {
      results = [];
      hasSearched = false;
      loading = false;
      _lastSearchedQuery = '';
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double headerHeight = 175.h;
    final double searchBoxHeight = 80.h;
    final query = _searchController.text.trim();
    final hasQuery = query.isNotEmpty;
    final hasCurrentSearch =
        hasSearched &&
        query == _lastSearchedQuery &&
        _lastSearchedQuery.isNotEmpty;

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
                        right: -50.w,
                        top: -50.h,
                        child: Container(
                          width: 200.w,
                          height: 200.h,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                      ),
                      Positioned(
                        left: -30.w,
                        bottom: -30.h,
                        child: Container(
                          width: 140.w,
                          height: 140.h,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: (searchBoxHeight / 2) + 12.h,
                        child: const Center(
                          child: Text(
                            'ค้นหายา',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 36.sp,
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
                  padding: EdgeInsets.only(top: searchBoxHeight / 2 + 12.h),
                  child: _buildContent(),
                ),
              ),
            ],
          ),
          Positioned(
            top: headerHeight - (searchBoxHeight / 2),
            left: 16.w,
            right: 16.w,
            child: Container(
              height: searchBoxHeight,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 8.r,
                    offset: Offset(0, 2.h),
                  ),
                ],
              ),
              child: SpeechToTextField(
                controller: _searchController,
                onSearch: search,
                child: TextField(
                  controller: _searchController,
                  textAlignVertical: TextAlignVertical.center,
                  style: TextStyle(fontSize: 16.sp, height: 1.2),
                  onChanged: (value) {
                    setState(() {});
                    if (value.isEmpty) {
                      setState(() {
                        results = [];
                        hasSearched = false;
                        _lastSearchedQuery = '';
                      });
                    }
                  },
                  onSubmitted: (_) => search(),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'ค้นหายาที่ต้องการ...',
                    hintStyle: TextStyle(
                      color: AppColors.textSub,
                      fontSize: 20.sp,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppColors.textSub,
                      size: 26.sp,
                    ),
                    prefixIconConstraints: BoxConstraints(
                      minWidth: 56.w,
                      minHeight: 80.h,
                    ),
                    suffixIcon: hasQuery
                        ? IconButton(
                            tooltip: hasCurrentSearch
                                ? 'ล้างการค้นหา'
                                : 'ค้นหา',
                            onPressed: loading
                                ? null
                                : (hasCurrentSearch ? _clearSearch : search),
                            icon: Icon(
                              hasCurrentSearch
                                  ? Icons.close_rounded
                                  : Icons.arrow_forward_rounded,
                              color: loading
                                  ? AppColors.textSublest
                                  : (hasCurrentSearch
                                        ? AppColors.textSub
                                        : AppColors.primaryBlue),
                              size: 28.sp,
                            ),
                          )
                        : null,
                    suffixIconConstraints: BoxConstraints(
                      minWidth: 56.w,
                      minHeight: 80.h,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.w,
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
              strokeWidth: 3.w,
            ),
            SizedBox(height: 16.h),
            Text(
              'กำลังค้นหา...',
              style: TextStyle(color: AppColors.textSub, fontSize: 14.sp),
            ),
          ],
        ),
      );
    }

    if (!hasSearched) {
      return Padding(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
        child: Align(
          alignment: Alignment.topCenter,
          child: AppEmptyCard(
            icon: Icons.search_rounded,
            title: 'ค้นหายา',
            subtitle: 'ค้นหายาเพื่อดูข้อมูลรายละเอียด',
            iconColor: AppColors.textSublest,
            borderColor: AppColors.blueBorder,
            borderRadius: 10.r,
            borderWidth: 2.w,
          ),
        ),
      );
    }

    if (results.isEmpty) {
      return Padding(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
        child: Align(
          alignment: Alignment.topCenter,
          child: AppEmptyCard(
            icon: Icons.search_off_rounded,
            title: 'ไม่พบรายการยา',
            subtitle: 'ไม่พบยาที่คุณค้นหา กรุณาลองตรวจสอบชื่อยาอีกครั้ง',
            iconColor: AppColors.textSublest,
            borderColor: AppColors.blueBorder,
            borderRadius: 10.r,
            borderWidth: 2.w,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.r),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        return _buildMedicationCard(item);
      },
    );
  }

  Widget _buildMedicationCard(Medication medication) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
          side: BorderSide(color: AppColors.blueBorder, width: 2.w),
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
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: Row(
              children: [
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayTradeName(
                          medication.tradenameTh,
                          medication.tradenameEn,
                        ),
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      if (displayDoseForm(
                            medication.doseFormTh,
                            medication.doseFormEn,
                          ) !=
                          null) ...[
                        Text(
                          'รูปแบบยา: ${displayDoseForm(medication.doseFormTh, medication.doseFormEn)}',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: AppColors.textSub,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.h),
                      ],
                      Text(
                        'สรรพคุณ: ${medication.indication ?? "-"}',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: AppColors.textSub,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (medication.categoryUse != null &&
                          medication.categoryUse!.isNotEmpty) ...[
                        SizedBox(height: 2.h),
                        Text(
                          'การใช้ประโยชน์: ${medication.categoryUse}',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: AppColors.textSub,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.textSub, size: 24.sp),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
