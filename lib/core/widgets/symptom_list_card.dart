import 'package:flutter/material.dart';
import 'package:capyadoo/core/constants/app_colors.dart';

/// List card สำหรับบันทึกอาการ - มี badge ระดับ, หัวข้อ, รายละเอียด, ปุ่มแก้ไข/ลบ
class SymptomListCard extends StatelessWidget {
  final int level; // ระดับ 1-10
  final String title;
  final String description;
  final String dateTime;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const SymptomListCard({
    super.key,
    required this.level,
    required this.title,
    required this.description,
    required this.dateTime,
    this.onEdit,
    this.onDelete,
    this.onTap,
  }) : assert(level >= 1 && level <= 10, 'Level must be between 1 and 10');

  /// คำนวณสีตามระดับ 1-10
  /// ระดับ 1-3: เขียว
  /// ระดับ 4-7: เหลือง (ไล่สีจากเขียว-เหลือง-ส้ม)
  /// ระดับ 8-10: แดง (ไล่สีจากส้ม-แดง)
  static Color getLevelColor(int level) {
    if (level < 1) level = 1;
    if (level > 10) level = 10;

    // ระดับ 1-3: เขียว
    if (level <= 3) {
      return Colors.green[600]!;
    }
    // ระดับ 4-7: เหลือง-ส้ม
    else if (level <= 7) {
      // ไล่สีจากเขียว → เหลือง → ส้ม
      final progress = (level - 4) / 3; // 0.0 ถึง 1.0
      if (progress < 0.5) {
        // 4-5: เขียว → เหลือง
        return Color.lerp(
          Colors.green[600]!,
          Colors.yellow[700]!,
          progress * 2,
        )!;
      } else {
        // 6-7: เหลือง → ส้ม
        return Color.lerp(
          Colors.yellow[700]!,
          Colors.orange[700]!,
          (progress - 0.5) * 2,
        )!;
      }
    }
    // ระดับ 8-10: แดง
    else {
      // ไล่สีจากส้ม → แดง
      final progress = (level - 8) / 2; // 0.0 ถึง 1.0
      return Color.lerp(Colors.orange[700]!, Colors.red[600]!, progress)!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final levelColor = getLevelColor(level);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.whitelist,
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Level badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: levelColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: levelColor, width: 1.5),
                    ),
                    child: Text(
                      'ระดับ $level/10',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: levelColor,
                      ),
                    ),
                  ),
                  const Spacer(),

                  // Action buttons
                  if (onEdit != null)
                    _ActionButton(
                      icon: Icons.edit,
                      color: AppColors.textSub,
                      onTap: onEdit,
                    ),
                  if (onEdit != null && onDelete != null)
                    const SizedBox(width: 8),
                  if (onDelete != null)
                    _ActionButton(
                      icon: Icons.delete,
                      color: AppColors.error,
                      onTap: onDelete,
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                description,
                style: TextStyle(fontSize: 16, color: AppColors.textSub),
              ),
              const SizedBox(height: 4),

              // DateTime
              Text(
                dateTime,
                style: TextStyle(fontSize: 16, color: AppColors.textSub),
              ),
            ],
          ),
        ),
      ),
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
