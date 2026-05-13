import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:capyadoo/core/services/auth_service.dart';
import 'package:capyadoo/core/widgets/app_button.dart';
import 'package:capyadoo/core/widgets/app_input_text.dart';
import 'package:capyadoo/core/validators/password_validation.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  _PasswordField _activeField = _PasswordField.none;

  @override
  void initState() {
    super.initState();
    _currentPasswordController.addListener(_refresh);
    _newPasswordController.addListener(_refresh);
    _confirmPasswordController.addListener(_refresh);
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  bool get _hasMinLength =>
      PasswordValidation.hasMinLength(_newPasswordController.text);
  bool get _hasSpecial =>
      PasswordValidation.hasSpecialCharacter(_newPasswordController.text);
  bool get _hasDigit =>
      PasswordValidation.hasDigit(_newPasswordController.text);

  bool get _confirmHasMinLength =>
      PasswordValidation.hasMinLength(_confirmPasswordController.text);
  bool get _confirmHasSpecial =>
      PasswordValidation.hasSpecialCharacter(_confirmPasswordController.text);
  bool get _confirmHasDigit =>
      PasswordValidation.hasDigit(_confirmPasswordController.text);

  bool get _confirmMatches => PasswordValidation.matches(
    _confirmPasswordController.text,
    _newPasswordController.text,
  );

  bool get _currentDiffers =>
      _currentPasswordController.text.isNotEmpty &&
      _currentPasswordController.text != _newPasswordController.text;

  bool get _allRequirementsMet =>
      _hasMinLength &&
      _hasSpecial &&
      _hasDigit &&
      _currentDiffers &&
      _confirmMatches;

  bool get _showNewRulesPanel =>
      _activeField == _PasswordField.newPassword &&
      _newPasswordController.text.isNotEmpty;

  bool get _showConfirmRulesPanel =>
      _activeField == _PasswordField.confirmPassword &&
      _confirmPasswordController.text.isNotEmpty;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await AuthService.changePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
      confirmNewPassword: _confirmPasswordController.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'เปลี่ยนรหัสผ่านสำเร็จ',
            style: TextStyle(fontFamily: 'Sarabun', fontSize: 14.sp),
          ),
        ),
      );
      Navigator.pop(context);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'ไม่สามารถเปลี่ยนรหัสผ่านได้',
          style: TextStyle(fontFamily: 'Sarabun', fontSize: 14.sp),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offwhite,
      body: Column(
        children: [
          Container(
            height: 160.h,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32.r),
                bottomRight: Radius.circular(32.r),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  Positioned(
                    right: -50.w,
                    top: -50.h,
                    child: Container(
                      width: 200.w,
                      height: 200.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -30.w,
                    bottom: -30.h,
                    child: Container(
                      width: 140.w,
                      height: 140.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                          left: 30.w,
                          right: 30.w,
                          bottom: 20.h,
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.arrow_back_ios,
                                color: Colors.white,
                                size: 24.sp,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Expanded(
                              child: Text(
                                'เปลี่ยนรหัสผ่าน',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            SizedBox(width: 48.w),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 24.h),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 760.w),
                  child: Form(
                    key: _formKey,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(22.r),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: AppColors.blueBorder, width: 1.5.w),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 14.r,
                            offset: Offset(0, 6.h),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'เปลี่ยนรหัสผ่านของคุณ',
                            style: TextStyle(
                              fontFamily: 'Sarabun',
                              fontSize: 28.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 18.h),
                          _buildFieldLabel('รหัสผ่านปัจจุบัน'),
                          SizedBox(height: 8.h),
                          AppInputText(
                            controller: _currentPasswordController,
                            hintText: 'กรอกรหัสผ่าน',
                            isPassword: true,
                            onTap: () {
                              setState(() {
                                _activeField = _PasswordField.currentPassword;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'กรุณากรอกรหัสผ่านปัจจุบัน';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16.h),
                          _buildFieldLabel('รหัสผ่านใหม่'),
                          SizedBox(height: 8.h),
                          AppInputText(
                            controller: _newPasswordController,
                            hintText: 'กรอกรหัสผ่าน',
                            isPassword: true,
                            onTap: () {
                              setState(() {
                                _activeField = _PasswordField.newPassword;
                              });
                            },
                            validator: (value) {
                              final passwordError =
                                  PasswordValidation.validateRequiredPassword(
                                    value,
                                    requiredMessage: 'กรุณากรอกรหัสผ่านใหม่',
                                  );
                              if (passwordError != null) {
                                return passwordError;
                              }
                              return PasswordValidation.validateDifferentFromCurrent(
                                value,
                                _currentPasswordController.text,
                              );
                            },
                          ),
                          if (_showNewRulesPanel) ...[
                            SizedBox(height: 10.h),
                            _buildInlineNewRulesPanel(),
                          ],
                          SizedBox(height: 16.h),
                          _buildFieldLabel('ยืนยันรหัสผ่านใหม่'),
                          SizedBox(height: 8.h),
                          AppInputText(
                            controller: _confirmPasswordController,
                            hintText: 'กรอกรหัสผ่าน',
                            isPassword: true,
                            onTap: () {
                              setState(() {
                                _activeField = _PasswordField.confirmPassword;
                              });
                            },
                            validator: (value) =>
                                PasswordValidation.validateConfirmPassword(
                                  value,
                                  _newPasswordController.text,
                                ),
                          ),
                          if (_showConfirmRulesPanel) ...[
                            SizedBox(height: 10.h),
                            _buildInlineConfirmRulesPanel(),
                          ],
                          SizedBox(height: 22.h),
                          SizedBox(
                            width: double.infinity,
                            child: AppButton(
                              text: 'เปลี่ยนรหัสผ่าน',
                              isLoading: _isLoading,
                              onPressed: _allRequirementsMet ? _submit : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Sarabun',
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryBlue,
      ),
    );
  }

  Widget _buildInlineNewRulesPanel() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.subBlue,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'รหัสผ่านต้องประกอบไปด้วย',
            style: TextStyle(
              fontFamily: 'Sarabun',
              fontSize: 17.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 6.h),
          _buildRuleItem('อย่างน้อย 8 ตัวอักษร', _hasMinLength),
          _buildRuleItem('ตัวอักษรพิเศษ อย่างน้อย 1 ตัว', _hasSpecial),
          _buildRuleItem('ตัวเลข 0-9 อย่างน้อย 1 ตัว', _hasDigit),
        ],
      ),
    );
  }

  Widget _buildInlineConfirmRulesPanel() {
    final mismatch =
        _confirmPasswordController.text.isNotEmpty && !_confirmMatches;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (mismatch)
          Padding(
            padding: EdgeInsets.only(bottom: 6.h),
            child: Text(
              'รหัสผ่านไม่ตรงกัน',
              style: TextStyle(
                fontFamily: 'Sarabun',
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            ),
          ),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: AppColors.subBlue,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'รหัสผ่านต้องประกอบไปด้วย',
                style: TextStyle(
                  fontFamily: 'Sarabun',
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 6.h),
              _buildRuleItem('อย่างน้อย 8 ตัวอักษร', _confirmHasMinLength),
              _buildRuleItem(
                'ตัวอักษรพิเศษ อย่างน้อย 1 ตัว',
                _confirmHasSpecial,
              ),
              _buildRuleItem('ตัวเลข 0-9 อย่างน้อย 1 ตัว', _confirmHasDigit),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRuleItem(String label, bool passed) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        children: [
          Container(
            width: 24.w,
            height: 24.h,
            decoration: BoxDecoration(
              color: passed
                  ? AppColors.success.withOpacity(0.2)
                  : AppColors.textSub.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              passed ? Icons.check_rounded : Icons.close_rounded,
              size: 16.sp,
              color: passed ? AppColors.success : AppColors.textSub,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Sarabun',
                fontSize: 15.sp,
                height: 1.2,
                color: passed ? AppColors.textPrimary : AppColors.textSub,
                fontWeight: passed ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _PasswordField { none, currentPassword, newPassword, confirmPassword }
