import 'package:flutter/material.dart';
import 'package:capyadoo/core/constants/app_colors.dart';

class AppEmptyCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? icon;
  final VoidCallback? onAddPressed;

  const AppEmptyCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon,
    this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F7FF), // Very light blue as in image
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFD0E4FF), // Light blue border
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon ?? Icons.medication_liquid_outlined,
            size: 80,
            color: Colors.black12, // Subtle grey icon as in image
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
              fontFamily: 'Sarabun',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[500],
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
