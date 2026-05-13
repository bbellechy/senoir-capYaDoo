import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:capyadoo/features/notifications/presentation/widgets/unified_selection_dialog.dart';
import 'package:capyadoo/core/services/auth_service.dart';

class PillSelectionWidget extends StatefulWidget {
  final String? initialValue;
  final String? initialImagePath;
  final Function(String name, String? imagePath) onSelected;

  const PillSelectionWidget({
    super.key,
    this.initialValue,
    this.initialImagePath,
    required this.onSelected,
  });

  @override
  State<PillSelectionWidget> createState() => _PillSelectionWidgetState();
}

class _PillSelectionWidgetState extends State<PillSelectionWidget> {
  String? _selectedName;
  String? _selectedImagePath;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _selectedName = widget.initialValue;
    _selectedImagePath = widget.initialImagePath;
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    try {
      final profile = await AuthService.getProfile();
      if (!mounted) return;
      setState(() {
        _userId = profile?.id;
      });
    } catch (_) {
      // ignore
    }
  }

  void _showSelectionDialog() async {
    if (_userId == null || _userId!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่พบข้อมูลผู้ใช้ กรุณาลองใหม่')),
        );
      }
      return;
    }
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => UnifiedSelectionDialog(
        userId: _userId!,
        title: 'เลือกยาหรือกล่องยา',
        showBoxes: true,
        showMasterMedications: false,
        allowFreeText: false,
        loadAllMedicationsOnOpen: true,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedName = result['name'];
        _selectedImagePath = result['imagePath'];
      });
      widget.onSelected(_selectedName!, _selectedImagePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      text: 'เลือกยา/กล่องยา ',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      children: const [
                        TextSpan(
                          text: '*',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  GestureDetector(
                    onTap: _showSelectionDialog,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.grey[300]!, width: 1.w),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedName ??
                                  (_userId == null
                                      ? 'กำลังโหลดข้อมูล...'
                                      : 'เลือกยาหรือกล่องยา'),
                              style: TextStyle(
                                color: _selectedName != null
                                    ? Colors.black87
                                    : Colors.grey[500],
                                fontSize: 16.sp,
                              ),
                            ),
                          ),
                          Icon(Icons.arrow_drop_down, color: Colors.grey[600], size: 24.sp),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_selectedName != null) ...[
          SizedBox(height: 8.h),
          Text(
            '*หากเลือกกล่องยาจะแจ้งเตือนสำหรับยาทุกตัวในกล่อง',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}
