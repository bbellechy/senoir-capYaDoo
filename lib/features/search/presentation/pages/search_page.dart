import 'package:flutter/material.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import '../../../../core/model/medication.dart';
import '../../../../core/model/user_medication.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../features/notifications/data/medication_search_service.dart';
import '../../../../core/widgets/speech_to_text_field.dart';
import 'medication_detail_page.dart';

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
  String? _userId;
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

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    try {
      final profile = await AuthService.getProfile();
      if (mounted) {
        setState(() {
          _userId = profile?.id;
        });
      }
    } catch (e) {
      print('Error loading user ID: $e');
    }
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

      // Parallel searches
      final List<Future> futures = [];
      if (_userId != null && _userId!.isNotEmpty) {
        futures.add(_searchService.searchUserMedications(_userId!, query));
      }
      futures.add(_searchService.searchMasterMedications(query));

      final searchResults = await Future.wait(futures);

      // Check if this is still the latest search
      if (currentSearchId != _lastSearchId) return;

      final List<dynamic> combinedResults = [];
      final Set<String> seenIds = {};

      // 1. Process User Medications first (highest priority)
      if (_userId != null && _userId!.isNotEmpty) {
        final List<UserMedication> userMeds =
            searchResults[0] as List<UserMedication>;
        for (var med in userMeds) {
          combinedResults.add(med);
          if (med.id != null) seenIds.add(med.id!);
          // Also block by master ID if available to prevent doubles
          if (med.masterMedicationEntity?.id != null) {
            seenIds.add(med.masterMedicationEntity!.id!);
          }
        }
      }

      // 2. Process Master Medications
      final List<Medication> masterMeds =
          (_userId != null && _userId!.isNotEmpty)
          ? searchResults[1] as List<Medication>
          : searchResults[0] as List<Medication>;

      for (var med in masterMeds) {
        if (med.id != null && !seenIds.contains(med.id)) {
          combinedResults.add(med);
          seenIds.add(med.id!);
        } else if (med.id == null) {
          final medName = med.name.toLowerCase();
          bool alreadyIn = combinedResults.any((m) {
            if (m is UserMedication)
              return m.displayName.toLowerCase() == medName;
            if (m is Medication) return m.name.toLowerCase() == medName;
            return false;
          });
          if (!alreadyIn) combinedResults.add(med);
        }
      }

      if (mounted) {
        setState(() {
          results = combinedResults;
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
            height: 140,
            decoration: const BoxDecoration(color: AppColors.primaryBlue),
            child: SafeArea(
              bottom: false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 30,
                      right: 30,
                      bottom: 20,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'ค้นหายา',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Sarabun',
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
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 50),
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 30),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFBBDEFB), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.medical_services_outlined,
                size: 70,
                color: Colors.grey.shade500,
              ),
              const SizedBox(height: 20),
              Text(
                'ค้นหายาเพื่อดูข้อมูลรายละเอียด',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'ไม่พบข้อมูลยา',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ลองค้นหาด้วยคำอื่น',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
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

  Widget _buildMedicationCard(dynamic item) {
    // Handle both Medication and UserMedication
    Medication medication;
    String subtitle;
    bool isUserMedication = false;

    if (item is Medication) {
      medication = item;
      subtitle = 'ยากลาง';
    } else if (item is UserMedication) {
      // Convert UserMedication to Medication for display
      medication = Medication(
        id: item.id,
        tradenameTh: item.displayName,
        tradenameEn: item.masterMedicationEntity?.tradenameEn,
        indication: item.masterMedicationEntity?.indication,
        categoryUse: item.masterMedicationEntity?.categoryUse,
      );
      subtitle = 'ยาของคุณ';
      isUserMedication = true;
    } else {
      return const SizedBox.shrink();
    }
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
                // Container(
                //   padding: const EdgeInsets.all(12),
                //   decoration: BoxDecoration(
                //     color: Colors.blue.shade50,
                //     borderRadius: BorderRadius.circular(10),
                //   ),
                //   child: Icon(
                //     Icons.medication,
                //     color: Colors.blue.shade600,
                //     size: 28,
                //   ),
                // ),
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
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isUserMedication
                              ? AppColors.primaryBlue
                              : Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'สรรพคุณ: ${medication.indication ?? "-"}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'ข้อบ่งใช้: ${medication.categoryUse ?? "-"}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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
