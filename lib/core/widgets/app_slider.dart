import 'package:flutter/material.dart';
import 'package:capyadoo/core/constants/app_colors.dart';

class AppSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double>? onChanged;
  final double min;
  final double max;
  final int? divisions;
  final String? label;
  final String? minLabel;
  final String? maxLabel;
  final bool enabled;
  final bool showValue;
  final bool isRequired;

  const AppSlider({
    super.key,
    required this.value,
    this.onChanged,
    this.min = 1.0,
    this.max = 10.0,
    this.divisions,
    this.label,
    this.minLabel,
    this.maxLabel,
    this.enabled = true,
    this.showValue = true,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Row(
            children: [
              Text(
                label!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Sarabun',
                ),
              ),
              if (isRequired)
                const Text(
                  ' *',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                    fontFamily: 'Sarabun',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.offwhite,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              if (showValue)
                Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
              if (showValue) const SizedBox(height: 8),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.primaryBlue,
                  inactiveTrackColor: Colors.grey[300],
                  thumbColor: AppColors.primaryBlue,
                  overlayColor: AppColors.primaryBlue.withOpacity(0.2),
                  trackHeight: 6.0,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 16.0,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 28.0,
                  ),
                  valueIndicatorColor: AppColors.primaryBlue,
                  valueIndicatorTextStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                child: Slider(
                  value: value,
                  min: min,
                  max: max,
                  divisions: divisions ?? (max - min).toInt(),
                  onChanged: enabled ? onChanged : null,
                ),
              ),
              if (minLabel != null || maxLabel != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        minLabel ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        maxLabel ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class AppRangeSlider extends StatelessWidget {
  final RangeValues values;
  final ValueChanged<RangeValues>? onChanged;
  final double min;
  final double max;
  final int? divisions;
  final String? label;
  final String? minLabel;
  final String? maxLabel;
  final bool enabled;
  final bool showValues;
  final bool isRequired;

  const AppRangeSlider({
    super.key,
    required this.values,
    this.onChanged,
    this.min = 0.0,
    this.max = 100.0,
    this.divisions,
    this.label,
    this.minLabel,
    this.maxLabel,
    this.enabled = true,
    this.showValues = true,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Row(
            children: [
              Text(
                label!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Sarabun',
                ),
              ),
              if (isRequired)
                const Text(
                  ' *',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                    fontFamily: 'Sarabun',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              if (showValues)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      values.start.toInt().toString(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const Text(
                      ' - ',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      values.end.toInt().toString(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
              if (showValues) const SizedBox(height: 8),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.primaryBlue,
                  inactiveTrackColor: Colors.grey[300],
                  thumbColor: AppColors.primaryBlue,
                  overlayColor: AppColors.primaryBlue.withOpacity(0.2),
                  trackHeight: 6.0,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 16.0,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 28.0,
                  ),
                  rangeThumbShape: const RoundRangeSliderThumbShape(
                    enabledThumbRadius: 16.0,
                  ),
                  valueIndicatorColor: AppColors.primaryBlue,
                  valueIndicatorTextStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                child: RangeSlider(
                  values: values,
                  min: min,
                  max: max,
                  divisions: divisions ?? (max - min).toInt(),
                  onChanged: enabled ? onChanged : null,
                ),
              ),
              if (minLabel != null || maxLabel != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        minLabel ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        maxLabel ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
