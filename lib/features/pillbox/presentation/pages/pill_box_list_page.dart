import 'dart:io';
import 'package:flutter/material.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:capyadoo/features/pillbox/controller/pill_box_controller.dart';
import 'package:capyadoo/features/pillbox/presentation/pages/pill_box_add_page.dart';
import 'package:capyadoo/features/pillbox/presentation/pages/pill_box_detail_page.dart';

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
    // Need to find the box object or pass ID
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
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'กล่องยา',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w500,
            fontFamily: 'Sarabun',
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'กล่องยาทั้งหมด',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: _navigateToAddPage,
                  child: Row(
                    children: [
                      Text(
                        'สร้างกล่องยาใหม่',
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w600,
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
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.medication,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'ไม่มีกล่องยา',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
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
