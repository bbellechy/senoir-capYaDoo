import 'dart:io';
import 'package:flutter/material.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:capyadoo/features/pillbox/controller/pill_box_controller.dart';
import 'package:capyadoo/features/pillbox/presentation/pages/pill_box_add_page.dart';
import 'package:capyadoo/features/pillbox/presentation/pages/pill_box_detail_page.dart';
import 'package:capyadoo/core/widgets/app_empty_card.dart';

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
          // Premium Header
          Container(
            height: 220,
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
                    right: -50,
                    top: -50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
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
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    top: 0,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.medication_liquid_outlined,
                          color: Colors.white70,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'กล่องยา',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Sarabun',
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'กล่องยาทั้งหมด',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                GestureDetector(
                  onTap: _navigateToAddPage,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'สร้างใหม่',
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
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
                if (_controller.isLoading && _controller.pillBoxes.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_controller.pillBoxes.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: AppEmptyCard(
                        title: 'ยังไม่มีกล่องยา',
                        subtitle: 'สร้างกล่องยาใหม่เพื่อเริ่มต้นใช้งาน',
                        onAddPressed: _navigateToAddPage,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _controller.pillBoxes.length,
                  itemBuilder: (context, index) {
                    final box = _controller.pillBoxes[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.blue.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () => _navigateToDetail(box.id!),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(8),
                                  image: box.imagePath != null
                                      ? DecorationImage(
                                          image: FileImage(
                                            File(box.imagePath!),
                                          ),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: box.imagePath == null
                                    ? Icon(
                                        Icons.shopping_bag,
                                        color: AppColors.primaryBlue,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      box.name,
                                      style: TextStyle(
                                        color: AppColors.primaryBlue,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.link,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${box.medicationIds.length} รายการยา',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                color: Colors.grey,
                                onPressed: () => _editBox(box.id!),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                ),
                                color: Colors.red[300],
                                onPressed: () => _deleteBox(box.id!),
                              ),
                            ],
                          ),
                        ),
                      ),
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
