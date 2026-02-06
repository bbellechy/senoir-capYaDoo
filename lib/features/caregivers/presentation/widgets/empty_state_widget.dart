import 'package:flutter/material.dart';
import 'package:capyadoo/core/constants/app_colors.dart';

/// Widget แสดงเมื่อไม่มีข้อมูล
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final double width;
  final bool showBorder;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.buttonText,
    this.onButtonPressed,
    this.width = double.infinity,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: showBorder
            ? Border.all(color: AppColors.blueBorder, width: 1.5)
            : null,
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: buttonText != null ? 64 : 48,
            color: Colors.grey[400],
          ),
          SizedBox(height: buttonText != null ? 16 : 12),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Sarabun',
              fontSize: buttonText != null ? 16 : 14,
              fontWeight: buttonText != null
                  ? FontWeight.w600
                  : FontWeight.normal,
              color: buttonText != null
                  ? AppColors.textPrimary
                  : AppColors.textSub,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: 'Sarabun',
              fontSize: buttonText != null ? 14 : 12,
              color: AppColors.textSub,
            ),
            textAlign: TextAlign.center,
          ),
          if (buttonText != null && onButtonPressed != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: 200,
              height: 44,
              child: ElevatedButton(
                onPressed: onButtonPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.person_add, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      buttonText!,
                      style: const TextStyle(
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
        ],
      ),
    );
  }
}
