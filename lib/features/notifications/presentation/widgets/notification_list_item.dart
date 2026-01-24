import 'package:flutter/material.dart';
import 'package:capyadoo/core/model/medication_notification.dart';

class NotificationListItem extends StatelessWidget {
  final MedicationNotification notification;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;
  final bool isDeleteMode;
  final bool isSelected;
  final ValueChanged<bool?>? onSelectionChanged;

  const NotificationListItem({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onToggle,
    this.isDeleteMode = false,
    this.isSelected = false,
    this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Checkbox for delete mode
            if (isDeleteMode)
              Checkbox(value: isSelected, onChanged: onSelectionChanged),

            // Content area - unified tap target
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isDeleteMode ? null : onTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 8,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.medication,
                            color: Colors.blue.shade700,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification.medicationName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notification.formattedDays,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                notification.formattedTimes,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Switch - NOT wrapped, completely independent
            if (!isDeleteMode)
              Switch(
                value: notification.isEnabled,
                onChanged: (value) => onToggle(value),
              ),
          ],
        ),
      ),
    );
  }
}
