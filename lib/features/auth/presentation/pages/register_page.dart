import 'package:flutter/material.dart';
import 'package:capyadoo/core/widgets/app_input_text.dart';
import 'package:capyadoo/core/widgets/app_button.dart';
import 'package:capyadoo/core/widgets/app_logo.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:capyadoo/core/services/auth_service.dart';

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
              padding: const EdgeInsets.all(48.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    const AppLogo(size: 80),
                    const SizedBox(height: 24),

                    // Title
                    const Text(
                      'ลงทะเบียนเข้าใช้งาน',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // First Name Field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ชื่อจริง',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 8),
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
                    const SizedBox(height: 16),

                    // Last Name Field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'นามสกุล',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 8),
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
                    const SizedBox(height: 16),

                    // Username Field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ชื่อผู้ใช้งาน',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 8),
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
                    const SizedBox(height: 16),

                    // Password Field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'รหัสผ่าน',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 8),
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
                          const SizedBox(height: 10),
                          _buildInlinePasswordRulesPanel(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password Field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ยืนยันรหัสผ่าน',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 8),
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
                          const SizedBox(height: 10),
                          _buildInlineConfirmRulesPanel(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Register Button
                    _isLoading
                        ? const CircularProgressIndicator()
                        : AppButton(
                            text: 'ลงทะเบียน',
                            onPressed: _handleRegister,
                          ),
                    const SizedBox(height: 16),

                    // Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'มีบัญชีแล้ว? ',
                          style: TextStyle(
                            color: AppColors.textSub,
                            fontSize: 16,
                          ),
                        ),
                        TextButton(
                          onPressed: _navigateToLogin,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'เข้าสู่ระบบ',
                            style: TextStyle(
                              color: AppColors.primaryBlue,
                              fontSize: 16,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.subBlue,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'รหัสผ่านต้องประกอบไปด้วย',
            style: TextStyle(
              fontFamily: 'Sarabun',
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
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
          const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Text(
              'รหัสผ่านไม่ตรงกัน',
              style: TextStyle(
                fontFamily: 'Sarabun',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            ),
          ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.subBlue,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'รหัสผ่านต้องประกอบไปด้วย',
                style: TextStyle(
                  fontFamily: 'Sarabun',
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isSatisfied ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isSatisfied ? Colors.green : AppColors.textSublest,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Sarabun',
                fontSize: 15,
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
