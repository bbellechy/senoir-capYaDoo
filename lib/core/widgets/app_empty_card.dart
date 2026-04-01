import 'package:flutter/material.dart';
import 'package:capyadoo/core/constants/app_colors.dart';

class AppEmptyCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? icon;
  final VoidCallback? onAddPressed;
  final Color? iconColor;
  final Color? borderColor;
  final double borderRadius;
  final double borderWidth;

  const AppEmptyCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon,
    this.onAddPressed,
    this.iconColor,
    this.borderColor,
    this.borderRadius = 24,
    this.borderWidth = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.whitelist,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? AppColors.blueBorder,
          width: borderWidth,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon ?? Icons.medication_liquid_outlined,
            size: 80,
            color: AppColors.textSublest,
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textSub,
              fontFamily: 'Sarabun',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSub,
              fontFamily: 'Sarabun',
            ),
            textAlign: TextAlign.center,
          ),
          if (onAddPressed != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAddPressed,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'เพิ่มข้อมูล',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
