import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// การ์ดแสดงคำขอหรือการ้องของผู้ใช้งาน (สำหรับผู้ดูแล)
class UserRequestCard extends StatelessWidget {
  final String name;
  final String username;
  final bool isPending;
  final VoidCallback? onCancel;

  const UserRequestCard({
    super.key,
    required this.name,
    required this.username,
    this.isPending = false,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.whitelist,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.noonBorder, width: 1.5),
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
              color: AppColors.noon,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              color: AppColors.noonIcon,
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
                if (isPending) ...[
                  const SizedBox(height: 4),
                  const Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: AppColors.noonIcon,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'รอการยอมรับจากผู้ใช้งาน...',
                        style: TextStyle(
                          fontFamily: 'Sarabun',
                          fontSize: 12,
                          color: AppColors.noonIcon,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // ปุ่ม
          if (isPending && onCancel != null)
            SizedBox(
              width: 90,
              height: 36,
              child: OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.blueEmpty,
                  foregroundColor: AppColors.textSub,
                  side: const BorderSide(color: AppColors.blueBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.close, size: 16, color: AppColors.textSub),
                    SizedBox(width: 4),
                    Text(
                      'ยกเลิก',
                      style: TextStyle(
                        fontFamily: 'Sarabun',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
