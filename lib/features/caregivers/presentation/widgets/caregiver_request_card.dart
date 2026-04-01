import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// การ์ดแสดงคำขอจากผู้ดูแล
class CaregiverRequestCard extends StatelessWidget {
  final String name;
  final String username;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const CaregiverRequestCard({
    super.key,
    required this.name,
    required this.username,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFA726), width: 1.5),
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
              color: const Color(0xFFFFA726).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Color(0xFFFFA726), size: 28),
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
                    fontSize: 16,
                    color: AppColors.textSub,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'ขอเข้าถึงข้อมูลของคุณ',
                  style: TextStyle(
                    fontFamily: 'Sarabun',
                    fontSize: 14,
                    color: AppColors.noonIcon,
                  ),
                ),
              ],
            ),
          ),

          // ปุ่ม
          Column(
            children: [
              SizedBox(
                width: 80,
                height: 36,
                child: ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.zero,
                    elevation: 0,
                  ),
                  child: const Text(
                    'ยอมรับ',
                    style: TextStyle(
                      fontFamily: 'Sarabun',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 80,
                height: 36,
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text(
                    'ปฏิเสธ',
                    style: TextStyle(
                      fontFamily: 'Sarabun',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
