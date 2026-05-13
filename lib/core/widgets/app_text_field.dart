import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:capyadoo/core/constants/app_colors.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int? maxLines;
  final int? maxLength;
  final bool enabled;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final bool isRequired;

  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.inputFormatters,
    this.validator,
    this.focusNode,
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
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Sarabun',
                ),
              ),
              if (isRequired)
                Text(
                  ' *',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                    fontFamily: 'Sarabun',
                  ),
                ),
            ],
          ),
          SizedBox(height: 8.h),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: maxLines,
          maxLength: maxLength,
          enabled: enabled,
          readOnly: readOnly,
          onChanged: onChanged,
          onTap: onTap,
          focusNode: focusNode,
          inputFormatters: inputFormatters,
          validator:
              validator ??
              (isRequired
                  ? (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'กรุณากรอกข้อมูล';
                      }
                      return null;
                    }
                  : null),
          style: TextStyle(fontSize: 16.sp, fontFamily: 'Sarabun'),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 16.sp, color: Colors.grey[400], fontFamily: 'Sarabun'),
            errorText: errorText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: AppColors.primaryBlue, width: 2.w),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: Colors.red, width: 2.w),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 16.h,
            ),
            counterText: '',
          ),
        ),
        if (maxLength != null) ...[
          SizedBox(height: 4.h),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${controller?.text.length ?? 0}/$maxLength',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
          ),
        ],
      ],
    );
  }
}

class AppLongTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final bool isRequired;
  final int? maxLines;

  const AppLongTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.onChanged,
    this.validator,
    this.isRequired = false,
    this.maxLines,
  });

  @override
  State<AppLongTextField> createState() => _AppLongTextFieldState();
}

class _AppLongTextFieldState extends State<AppLongTextField> {
  late TextEditingController _controller;
  static const int maxLength = 200;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_updateState);
  }

  @override
  void dispose() {
    _controller.removeListener(_updateState);
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _updateState() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: _controller,
      label: widget.label,
      hint: widget.hint,
      errorText: widget.errorText,
      maxLines: widget.maxLines ?? 5,
      maxLength: maxLength,
      keyboardType: TextInputType.multiline,
      onChanged: widget.onChanged,
      validator: widget.validator,
      isRequired: widget.isRequired,
    );
  }
}
