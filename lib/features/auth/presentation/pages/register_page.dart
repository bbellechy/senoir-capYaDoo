import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:capyadoo/core/widgets/app_input_text.dart';
import 'package:capyadoo/core/widgets/app_button.dart';
import 'package:capyadoo/core/widgets/app_logo.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:capyadoo/core/services/auth_service.dart';
import 'package:capyadoo/core/validators/password_validation.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  _RegisterField _activeField = _RegisterField.none;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_refresh);
    _confirmPasswordController.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneNumberController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _hasMinLength =>
      PasswordValidation.hasMinLength(_passwordController.text);
  bool get _hasSpecial =>
      PasswordValidation.hasSpecialCharacter(_passwordController.text);
  bool get _hasDigit => PasswordValidation.hasDigit(_passwordController.text);

  bool get _confirmHasMinLength =>
      PasswordValidation.hasMinLength(_confirmPasswordController.text);
  bool get _confirmHasSpecial =>
      PasswordValidation.hasSpecialCharacter(_confirmPasswordController.text);
  bool get _confirmHasDigit =>
      PasswordValidation.hasDigit(_confirmPasswordController.text);

  bool get _confirmMatches => PasswordValidation.matches(
    _confirmPasswordController.text,
    _passwordController.text,
  );

  bool get _showPasswordRulesPanel =>
      _activeField == _RegisterField.password &&
      _passwordController.text.isNotEmpty;

  bool get _showConfirmRulesPanel =>
      _activeField == _RegisterField.confirmPassword &&
      _confirmPasswordController.text.isNotEmpty;

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final fullName =
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';
      final success = await AuthService.register(
        _usernameController.text.trim(),
        fullName,
        PasswordValidation.normalizeThaiPhone(_phoneNumberController.text),
        _passwordController.text,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          // AuthService.register automatically logs in on success
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่สามารถลงทะเบียนได้ กรุณาลองใหม่')),
          );
        }
      }
    }
  }

  void _navigateToLogin() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.authGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(48.0.r),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    AppLogo(size: 80.sp),
                    SizedBox(height: 24.h),

                    // Title
                    Text(
                      'ลงทะเบียนเข้าใช้งาน',
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    SizedBox(height: 32.h),

                    // First Name Field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ชื่อจริง',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        AppInputText(
                          controller: _firstNameController,
                          hintText: 'กรอกชื่อจริง',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'กรุณากรอกชื่อจริง';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),

                    // Last Name Field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'นามสกุล',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        AppInputText(
                          controller: _lastNameController,
                          hintText: 'กรอกนามสกุล',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'กรุณากรอกนามสกุล';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),

                    // Username Field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ชื่อผู้ใช้งาน',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        AppInputText(
                          controller: _usernameController,
                          hintText: 'กรอกชื่อผู้ใช้งาน',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'กรุณากรอกชื่อผู้ใช้งาน';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),

                    // Phone Field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'เบอร์โทรศัพท์',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        AppInputText(
                          controller: _phoneNumberController,
                          hintText: 'กรอกเบอร์โทรศัพท์',
                          keyboardType: TextInputType.phone,
                          validator: PasswordValidation.validateThaiPhone,
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),

                    // Password Field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'รหัสผ่าน',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        AppInputText(
                          controller: _passwordController,
                          hintText: 'กรอกรหัสผ่าน',
                          isPassword: true,
                          onTap: () {
                            setState(() {
                              _activeField = _RegisterField.password;
                            });
                          },
                          validator:
                              PasswordValidation.validateRequiredPassword,
                        ),
                        if (_showPasswordRulesPanel) ...[
                          SizedBox(height: 10.h),
                          _buildInlinePasswordRulesPanel(),
                        ],
                      ],
                    ),
                    SizedBox(height: 16.h),

                    // Confirm Password Field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ยืนยันรหัสผ่าน',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        AppInputText(
                          controller: _confirmPasswordController,
                          hintText: 'กรอกรหัสผ่านอีกครั้ง',
                          isPassword: true,
                          onTap: () {
                            setState(() {
                              _activeField = _RegisterField.confirmPassword;
                            });
                          },
                          validator: (value) =>
                              PasswordValidation.validateConfirmPassword(
                                value,
                                _passwordController.text,
                                requiredMessage: 'กรุณายืนยันรหัสผ่าน',
                                mismatchMessage: 'รหัสผ่านไม่ตรงกัน',
                              ),
                        ),
                        if (_showConfirmRulesPanel) ...[
                          SizedBox(height: 10.h),
                          _buildInlineConfirmRulesPanel(),
                        ],
                      ],
                    ),
                    SizedBox(height: 32.h),

                    // Register Button
                    _isLoading
                        ? const CircularProgressIndicator()
                        : AppButton(
                            text: 'ลงทะเบียน',
                            onPressed: _handleRegister,
                          ),
                    SizedBox(height: 16.h),

                    // Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'มีบัญชีแล้ว? ',
                          style: TextStyle(
                            color: AppColors.textSub,
                            fontSize: 16.sp,
                          ),
                        ),
                        TextButton(
                          onPressed: _navigateToLogin,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'เข้าสู่ระบบ',
                            style: TextStyle(
                              color: AppColors.primaryBlue,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInlinePasswordRulesPanel() {
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

  Widget _buildRuleItem(String text, bool isSatisfied) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Icon(
            isSatisfied ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isSatisfied ? Colors.green : AppColors.textSublest,
            size: 20.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Sarabun',
                fontSize: 15.sp,
                color: isSatisfied ? AppColors.textPrimary : AppColors.textSub,
                fontWeight: isSatisfied ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _RegisterField { none, password, confirmPassword }
