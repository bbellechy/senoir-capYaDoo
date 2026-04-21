import 'package:flutter/material.dart';
import 'package:capyadoo/core/routing/app_router.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:capyadoo/core/services/auth_service.dart';
import 'package:capyadoo/core/widgets/app_button.dart';
import 'package:capyadoo/core/widgets/app_input_text.dart';
import 'package:capyadoo/core/validators/password_validation.dart';
import 'package:capyadoo/core/model/forgot_password_reset_args.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  _PasswordField _activeField = _PasswordField.none;
  ForgotPasswordResetArgs? _resetArgs;
  bool _isArgsLoaded = false;

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(_refresh);
    _confirmPasswordController.addListener(_refresh);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isArgsLoaded) return;
    _isArgsLoaded = true;

    final args =
        ModalRoute.of(context)?.settings.arguments as ForgotPasswordResetArgs?;
    _resetArgs = args;

    if (_resetArgs == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณายืนยัน OTP ก่อนตั้งรหัสผ่านใหม่')),
        );
        Navigator.pushReplacementNamed(
          context,
          AppRouter.forgotPasswordOtpRoute,
        );
      });
    }
  }

  @override
  void dispose() {
    _newPasswordController.removeListener(_refresh);
    _confirmPasswordController.removeListener(_refresh);
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
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

  bool get _showNewRulesPanel => _activeField == _PasswordField.newPassword;
  bool get _showConfirmRulesPanel =>
      _activeField == _PasswordField.confirmPassword;
  bool get _allRequirementsMet =>
      _hasMinLength && _hasSpecial && _hasDigit && _confirmMatches;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_resetArgs == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await AuthService.resetPasswordWithOtpToken(
        resetToken: _resetArgs!.resetToken,
        newPassword: _newPasswordController.text,
        confirmNewPassword: _confirmPasswordController.text,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('รีเซ็ตรหัสผ่านสำเร็จ')));
        Navigator.pushReplacementNamed(context, AppRouter.loginRoute);
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('รีเซ็ตรหัสผ่านไม่สำเร็จ กรุณาลองใหม่')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SizedBox.expand(
        child: Container(
          decoration: const BoxDecoration(gradient: AppColors.authGradient),
          child: SafeArea(
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Form(
                        key: _formKey,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 78),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ลืมรหัสผ่าน',
                                style: TextStyle(
                                  fontFamily: 'Sarabun',
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(height: 20),
                              _buildFieldLabel('รหัสผ่านใหม่'),
                              const SizedBox(height: 8),
                              AppInputText(
                                controller: _newPasswordController,
                                hintText: 'กรอกรหัสผ่านใหม่',
                                isPassword: true,
                                onTap: () {
                                  setState(() {
                                    _activeField = _PasswordField.newPassword;
                                  });
                                },
                                validator: (value) =>
                                    PasswordValidation.validateRequiredPassword(
                                      value,
                                      requiredMessage: 'กรุณากรอกรหัสผ่านใหม่',
                                    ),
                              ),
                              if (_showNewRulesPanel) ...[
                                const SizedBox(height: 10),
                                _buildInlineNewRulesPanel(),
                              ],
                              const SizedBox(height: 18),
                              _buildFieldLabel('ยืนยันรหัสผ่านใหม่'),
                              const SizedBox(height: 8),
                              AppInputText(
                                controller: _confirmPasswordController,
                                hintText: 'ยืนยันรหัสผ่านใหม่',
                                isPassword: true,
                                onTap: () {
                                  setState(() {
                                    _activeField =
                                        _PasswordField.confirmPassword;
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
                              const SizedBox(height: 18),
                              SizedBox(
                                width: double.infinity,
                                child: AppButton(
                                  text: 'บันทึกรหัสผ่านใหม่',
                                  isLoading: _isLoading,
                                  backgroundColor: AppColors.primaryBlue,
                                  textColor: Colors.white,
                                  onPressed: _submit,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  top: 4,
                  child: IconButton(
                    padding: const EdgeInsets.all(18),
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: AppColors.primaryBlue,
                    ),
                    onPressed: () {
                      Navigator.pushReplacementNamed(
                        context,
                        AppRouter.forgotPasswordOtpRoute,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
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

enum _PasswordField { none, newPassword, confirmPassword }
