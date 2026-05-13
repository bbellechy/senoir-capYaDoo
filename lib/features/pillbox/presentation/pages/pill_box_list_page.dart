import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:capyadoo/features/pillbox/controller/pill_box_controller.dart';
import 'package:capyadoo/features/pillbox/presentation/pages/pill_box_add_page.dart';
import 'package:capyadoo/features/pillbox/presentation/pages/pill_box_detail_page.dart';
import 'package:capyadoo/core/widgets/app_empty_card.dart';
import 'package:capyadoo/features/pillbox/presentation/widgets/medicine_box_list_card.dart';
import 'package:capyadoo/core/config/api_config.dart';

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
        title: Text('ยืนยันการลบ', style: TextStyle(fontSize: 18.sp)),
        content: Text('คุณต้องการลบกล่องยานี้ใช่หรือไม่?', style: TextStyle(fontSize: 16.sp)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก', style: TextStyle(fontSize: 16.sp)),
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
                      content: Text(
                        _controller.error ?? 'Error deleting box',
                        style: TextStyle(fontFamily: 'Sarabun', fontSize: 14.sp),
                      ),
                    ),
                  );
                }
              }
            },
            child: Text('ลบ', style: TextStyle(color: Colors.red, fontSize: 16.sp)),
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
            height: 160.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32.r),
                bottomRight: Radius.circular(32.r),
              ),
            ),
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
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                          left: 30.w,
                          right: 30.w,
                          bottom: 20.h,
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.arrow_back_ios,
                                color: Colors.white,
                                size: 24.sp,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Expanded(
                              child: Text(
                                'กล่องยา',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32.sp,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Sarabun',
                                ),
                              ),
                            ),
                            SizedBox(width: 48.w),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(24.r),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'กล่องยาทั้งหมด',
                  style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _navigateToAddPage,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'สร้างกล่องยา',
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w600,
                            fontSize: 22.sp,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Icon(
                          Icons.add_circle,
                          color: AppColors.primaryBlue,
                          size: 24.sp,
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
                    padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: AppEmptyCard(
                        icon: Icons.inventory_2_outlined,
                        title: 'ยังไม่มีกล่องยา',
                        subtitle: 'สร้างกล่องยาใหม่เพื่อเริ่มต้นใช้งาน',
                        iconColor: AppColors.textSublest,
                        borderColor: AppColors.blueBorder,
                        borderRadius: 10.r,
                        borderWidth: 2.w,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: _controller.pillBoxes.length,
                  itemBuilder: (context, index) {
                    final box = _controller.pillBoxes[index];
                    return MedicineBoxListCard(
                      icon: Icons.shopping_bag,
                      iconColor: AppColors.primaryBlue,
                      iconBackgroundColor: const Color(0xFFE3F2FD),
                      imagePath: _resolveImagePath(box.imagePath),
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

  String? _resolveImagePath(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;

    if (path.contains(':') ||
        path.startsWith('/') ||
        path.contains('Documents/') ||
        path.contains('data/user/')) {
      return path;
    }

    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '${ApiConfig.baseUrl}/$cleanPath';
  }
}
