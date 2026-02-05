import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

enum MedicineConfirmationStatus { pending, taken, overdue }

class MedicineConfirmationButton extends StatelessWidget {
  final MedicineConfirmationStatus status;
  final VoidCallback? onConfirm;

  const MedicineConfirmationButton({
    super.key,
    required this.status,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case MedicineConfirmationStatus.pending:
        return SizedBox(
          height: 40,
          child: ElevatedButton(
            onPressed: onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: AppColors.whitelist,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'ยืนยันการทาน',
              style: TextStyle(
                fontFamily: 'Sarabun',
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );

      case MedicineConfirmationStatus.taken:
        return Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.success,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              const Text(
                'ทานแล้ว',
                style: TextStyle(
                  fontFamily: 'Sarabun',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );

      case MedicineConfirmationStatus.overdue:
        return Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text(
              'เกินกำหนด',
              style: TextStyle(
                fontFamily: 'Sarabun',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        );
    }
  }
}
