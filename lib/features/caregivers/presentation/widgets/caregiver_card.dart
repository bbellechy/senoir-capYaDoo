import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// การ์ดแสดงรายชื่อผู้ดูแล
class CaregiverCard extends StatelessWidget {
  final String name;
  final String username;
  final VoidCallback onDelete;

  const CaregiverCard({
    super.key,
    required this.name,
    required this.username,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.blueBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // ไอคอนผู้ใช้
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              color: AppColors.primaryBlue,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),

          // ข้อมูล
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Sarabun',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  username,
                  style: const TextStyle(
                    fontFamily: 'Sarabun',
                    fontSize: 14,
                    color: AppColors.textSub,
                  ),
                ),
              ],
            ),
          ),

          // ปุ่มลบ
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete, color: Color(0xFFE57373), size: 24),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFE57373).withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
