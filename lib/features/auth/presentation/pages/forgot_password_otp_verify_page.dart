import 'dart:async';

import 'package:flutter/material.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:capyadoo/core/routing/app_router.dart';
import 'package:capyadoo/core/services/auth_service.dart';
import 'package:capyadoo/core/widgets/app_button.dart';
import 'package:capyadoo/core/model/forgot_password_reset_args.dart';

class ForgotPasswordOtpVerifyPage extends StatefulWidget {
  const ForgotPasswordOtpVerifyPage({super.key});

  @override
  State<ForgotPasswordOtpVerifyPage> createState() =>
      _ForgotPasswordOtpVerifyPageState();
}

class _ForgotPasswordOtpVerifyPageState
    extends State<ForgotPasswordOtpVerifyPage> {
  static const int _otpLength = 6;
  static const int _resendCooldownSeconds = 60;

  final List<TextEditingController> _otpControllers = List.generate(
    _otpLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(
    _otpLength,
    (_) => FocusNode(),
  );

  String? _phoneNumber;
  bool _isArgsLoaded = false;
  bool _isVerifyingOtp = false;
  bool _isResendingOtp = false;
  int _secondsLeft = _resendCooldownSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isArgsLoaded) return;
    _isArgsLoaded = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _phoneNumber = args['phoneNumber']?.toString();
    } else if (args is Map) {
      _phoneNumber = args['phoneNumber']?.toString();
    } else {
      try {
        final dynamic dynamicArgs = args;
        _phoneNumber = dynamicArgs?.phoneNumber?.toString();
      } catch (_) {
        _phoneNumber = null;
      }
    }

    if (_phoneNumber == null || _phoneNumber!.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(
          context,
          AppRouter.forgotPasswordOtpRoute,
        );
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() {
      _secondsLeft = _resendCooldownSeconds;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() {
          _secondsLeft = 0;
        });
        return;
      }
      setState(() {
        _secondsLeft--;
      });
    });
  }

  String get _otpCode =>
      _otpControllers.map((controller) => controller.text).join();

  bool get _isOtpComplete => _otpCode.length == _otpLength;

  void _handleOtpInputChanged(int index, String value) {
    if (value.length > 1) {
      _otpControllers[index].text = value.substring(value.length - 1);
      _otpControllers[index].selection = const TextSelection.collapsed(
        offset: 1,
      );
    }

    if (_otpControllers[index].text.isNotEmpty && index < _otpLength - 1) {
      _otpFocusNodes[index + 1].requestFocus();
    }

    setState(() {});
  }

  Future<void> _resendOtp() async {
    if (_phoneNumber == null || _secondsLeft > 0 || _isResendingOtp) return;

    setState(() {
      _isResendingOtp = true;
    });

    try {
      final result = await AuthService.requestForgotPasswordOtp(
        phoneNumber: _phoneNumber!,
      );

      if (!mounted) return;

      if (result.success) {
        _startCooldown();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'ส่ง OTP อีกครั้งเรียบร้อย'),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'ไม่สามารถส่ง OTP อีกครั้งได้'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isResendingOtp = false;
        });
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (_phoneNumber == null || !_isOtpComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอก OTP ให้ครบ 6 หลัก')),
      );
      return;
    }

    setState(() {
      _isVerifyingOtp = true;
    });

    try {
      final result = await AuthService.verifyForgotPasswordOtp(
        phoneNumber: _phoneNumber!,
        otpCode: _otpCode,
      );

      if (!mounted) return;

      if (!result.success || result.resetToken == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'OTP ไม่ถูกต้องหรือหมดอายุ'),
          ),
        );
        return;
      }

      Navigator.pushReplacementNamed(
        context,
        AppRouter.forgotPasswordRoute,
        arguments: ForgotPasswordResetArgs(
          phoneNumber: _phoneNumber!,
          resetToken: result.resetToken!,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isVerifyingOtp = false;
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
                      child: Padding(
                        padding: const EdgeInsets.only(top: 78),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'กรอกรหัส OTP',
                              style: TextStyle(
                                fontFamily: 'Sarabun',
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _phoneNumber == null
                                  ? ''
                                  : 'เราได้ส่ง OTP ไปที่ $_phoneNumber',
                              style: const TextStyle(
                                fontFamily: 'Sarabun',
                                fontSize: 15,
                                color: AppColors.textSub,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(_otpLength, (index) {
                                return SizedBox(
                                  width: 46,
                                  child: TextField(
                                    controller: _otpControllers[index],
                                    focusNode: _otpFocusNodes[index],
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    maxLength: 1,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontFamily: 'Sarabun',
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                    decoration: InputDecoration(
                                      counterText: '',
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(
                                          color: AppColors.textSublest,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(
                                          color: AppColors.textSublest,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(
                                          color: AppColors.primaryBlue,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    onChanged: (value) =>
                                        _handleOtpInputChanged(index, value),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                const Text(
                                  'ไม่ได้รับรหัส? ',
                                  style: TextStyle(
                                    fontFamily: 'Sarabun',
                                    color: AppColors.textSub,
                                  ),
                                ),
                                TextButton(
                                  onPressed:
                                      (_secondsLeft == 0 && !_isResendingOtp)
                                      ? _resendOtp
                                      : null,
                                  child: Text(
                                    _secondsLeft == 0
                                        ? (_isResendingOtp
                                              ? 'กำลังขอ...'
                                              : 'ขอรหัส OTP อีกครั้ง')
                                        : 'ขอรหัสใหม่ได้ใน ${_secondsLeft}s',
                                    style: const TextStyle(
                                      fontFamily: 'Sarabun',
                                      color: AppColors.primaryBlue,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: AppButton(
                                text: 'ยืนยัน OTP',
                                isLoading: _isVerifyingOtp,
                                backgroundColor: AppColors.primaryBlue,
                                textColor: Colors.white,
                                onPressed: _verifyOtp,
                              ),
                            ),
                          ],
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
}
