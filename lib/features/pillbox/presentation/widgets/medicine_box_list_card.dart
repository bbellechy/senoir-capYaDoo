import 'dart:io';

import 'package:flutter/material.dart';
import 'package:capyadoo/core/constants/app_colors.dart';

/// List card สำหรับกล่องยา - มีไอคอน, ชื่อ, จำนวนรายการยา, ปุ่มแก้ไข/ลบ
class MedicineBoxListCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final String? imagePath;
  final String name;
  final int medicineCount;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const MedicineBoxListCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    this.imagePath,
    required this.name,
    required this.medicineCount,
    this.onEdit,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.blueBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              _buildLeadingVisual(),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.medication,
                          size: 16,
                          color: AppColors.textSub,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$medicineCount รายการยา',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSub,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action buttons
              if (onEdit != null)
                _ActionButton(
                  icon: Icons.create_rounded,
                  color: AppColors.textSub,
                  onTap: onEdit,
                ),
              if (onEdit != null && onDelete != null) const SizedBox(width: 8),
              if (onDelete != null)
                _ActionButton(
                  icon: Icons.delete_rounded,
                  color: AppColors.error,
                  onTap: onDelete,
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isNetworkPath(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  Widget _buildLeadingVisual() {
    final path = imagePath?.trim();
    if (path == null || path.isEmpty) {
      return _buildFallbackIcon();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 64,
        height: 64,
        child: _isNetworkPath(path)
            ? Image.network(
                path,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildFallbackIcon(),
              )
            : Image.file(
                File(path),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildFallbackIcon(),
              ),
      ),
    );
  }

  Widget _buildFallbackIcon() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: iconBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 32, color: iconColor),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.blueBorder, width: 1),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}
