import 'package:flutter/material.dart';
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
        const SnackBar(
          content: Text(
            'เปลี่ยนรหัสผ่านสำเร็จ',
            style: TextStyle(fontFamily: 'Sarabun'),
          ),
        ),
      );
      Navigator.pop(context);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'ไม่สามารถเปลี่ยนรหัสผ่านได้',
          style: TextStyle(fontFamily: 'Sarabun'),
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
            height: 160,
            decoration: const BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  Positioned(
                    right: -50,
                    top: -50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -30,
                    bottom: -30,
                    child: Container(
                      width: 140,
                      height: 140,
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
                        padding: const EdgeInsets.only(
                          left: 30,
                          right: 30,
                          bottom: 20,
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back_ios,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const Expanded(
                              child: Text(
                                'เปลี่ยนรหัสผ่าน',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 48),
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
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Form(
                    key: _formKey,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.blueBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'เปลี่ยนรหัสผ่านของคุณ',
                            style: TextStyle(
                              fontFamily: 'Sarabun',
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _buildFieldLabel('รหัสผ่านปัจจุบัน'),
                          const SizedBox(height: 8),
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
                          const SizedBox(height: 16),
                          _buildFieldLabel('รหัสผ่านใหม่'),
                          const SizedBox(height: 8),
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
                            const SizedBox(height: 10),
                            _buildInlineNewRulesPanel(),
                          ],
                          const SizedBox(height: 16),
                          _buildFieldLabel('ยืนยันรหัสผ่านใหม่'),
                          const SizedBox(height: 8),
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
                            const SizedBox(height: 10),
                            _buildInlineConfirmRulesPanel(),
                          ],
                          const SizedBox(height: 22),
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
      style: const TextStyle(
        fontFamily: 'Sarabun',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryBlue,
      ),
    );
  }

  Widget _buildInlineNewRulesPanel() {
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

  Widget _buildRuleItem(String label, bool passed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: passed
                  ? AppColors.success.withOpacity(0.2)
                  : AppColors.textSub.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              passed ? Icons.check_rounded : Icons.close_rounded,
              size: 16,
              color: passed ? AppColors.success : AppColors.textSub,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Sarabun',
                fontSize: 15,
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
