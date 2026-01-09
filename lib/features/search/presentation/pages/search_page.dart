import 'package:flutter/material.dart';
import '../../../../core/model/medication.dart';
import '../../../../core/services/search_master_medication_api.dart';
import 'medication_detail_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  bool loading = false;
  List<Medication> results = [];

  void search() async {
    if (_searchController.text.isEmpty) {
      setState(() => results = []);
      return;
    }

    setState(() => loading = true);

    try {
      results = await SearchMedicationApi.search(
        _searchController.text,
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ค้นหาไม่สำเร็จ')),
      );
    }

    setState(() => loading = false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF6),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('ค้นหายา'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => search(),
              decoration: InputDecoration(
                hintText: 'ค้นหายาที่ต้องการ...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          if (loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),

          Expanded(
            child: ListView.builder(
              itemCount: results.length,
              itemBuilder: (context, index) {
                final m = results[index];

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MedicationDetailPage(
                          medication: m,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.tradenameTh,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            m.tradenameEn,
                            style:
                                const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text('สรรพคุณ: ${m.indication}'),
                          Text('ข้อบ่งใช้: ${m.categoryUse}'),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
