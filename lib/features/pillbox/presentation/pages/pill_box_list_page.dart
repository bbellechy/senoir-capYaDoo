import 'package:flutter/material.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:capyadoo/features/pillbox/controller/pill_box_controller.dart';
import 'package:capyadoo/features/pillbox/presentation/pages/pill_box_add_page.dart';
import 'package:capyadoo/features/pillbox/presentation/pages/pill_box_detail_page.dart';
import 'package:capyadoo/core/widgets/app_empty_card.dart';
import 'package:capyadoo/features/pillbox/presentation/widgets/medicine_box_list_card.dart';

class PillBoxListPage extends StatefulWidget {
  const PillBoxListPage({super.key});

  @override
  State<PillBoxListPage> createState() => _PillBoxListPageState();
}

class _PillBoxListPageState extends State<PillBoxListPage> {
  final PillBoxController _controller = PillBoxController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _controller.loadPillBoxes();
    if (mounted) setState(() {});
  }

  void _navigateToAddPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PillBoxAddPage()),
    );
    if (result == true) {
      _loadData();
    }
  }

  void _navigateToDetail(String boxId) async {
    final box = _controller.pillBoxes.firstWhere((b) => b.id == boxId);
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PillBoxDetailPage(pillBox: box)),
    );
    if (result == true) {
      _loadData();
    }
  }

  void _editBox(String boxId) async {
    final box = _controller.pillBoxes.firstWhere((b) => b.id == boxId);
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PillBoxAddPage(existingBox: box)),
    );
    if (result == true) {
      _loadData();
    }
  }

  void _deleteBox(String boxId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text('คุณต้องการลบกล่องยานี้ใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _controller.deletePillBox(boxId);
              if (success) {
                _loadData();
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_controller.error ?? 'Error deleting box'),
                    ),
                  );
                }
              }
            },
            child: const Text('ลบ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            height: 140,
            width: double.infinity,
            color: AppColors.primaryBlue,
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
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Expanded(
                          child: Text(
                            'กล่องยา',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Sarabun',
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Text(
                  'กล่องยาทั้งหมด',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _navigateToAddPage,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'สร้างกล่องยา',
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w600,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.add_circle,
                          color: AppColors.primaryBlue,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, child) {
                if (_controller.pillBoxes.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: AppEmptyCard(
                        icon: Icons.inventory_2_outlined,
                        title: 'ยังไม่มีกล่องยา',
                        subtitle: 'สร้างกล่องยาใหม่เพื่อเริ่มต้นใช้งาน',
                        iconColor: AppColors.textSublest,
                        borderColor: AppColors.blueBorder,
                        borderRadius: 10,
                        borderWidth: 2,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _controller.pillBoxes.length,
                  itemBuilder: (context, index) {
                    final box = _controller.pillBoxes[index];
                    return MedicineBoxListCard(
                      icon: Icons.shopping_bag,
                      iconColor: AppColors.primaryBlue,
                      iconBackgroundColor: const Color(0xFFE3F2FD),
                      name: box.name,
                      medicineCount: box.medicationIds.length,
                      onTap: () => _navigateToDetail(box.id!),
                      onEdit: () => _editBox(box.id!),
                      onDelete: () => _deleteBox(box.id!),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
