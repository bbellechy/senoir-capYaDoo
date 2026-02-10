import 'package:flutter/material.dart';
import 'package:capyadoo/core/constants/app_colors.dart';

/// แสดงบทบาทของผู้ใช้งาน (ผู้ใช้งาน, ผู้ดูแล)
class RoleSection extends StatelessWidget {
  final bool isCaregiver;

  const RoleSection({super.key, required this.isCaregiver});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ดูข้อมูลยาของผู้ป่วยในความดูแล',
          style: TextStyle(
            fontFamily: 'Sarabun',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.person,
                    color: AppColors.textPrimary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'บทบาทของคุณ',
                    style: TextStyle(
                      fontFamily: 'Sarabun',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildRoleChip('ผู้ใช้งาน', AppColors.primaryBlue),
                  if (isCaregiver) ...[
                    const SizedBox(width: 8),
                    _buildRoleChip('ผู้ดูแล', const Color(0xFF4CAF50)),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoleChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Sarabun',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }
}
