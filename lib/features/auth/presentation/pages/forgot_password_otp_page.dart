import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:capyadoo/core/routing/app_router.dart';
import 'package:capyadoo/core/services/auth_service.dart';
import 'package:capyadoo/core/validators/password_validation.dart';
import 'package:capyadoo/core/widgets/app_button.dart';
import 'package:capyadoo/core/widgets/app_input_text.dart';

class ForgotPasswordOtpPage extends StatefulWidget {
  const ForgotPasswordOtpPage({super.key});

  @override
  State<ForgotPasswordOtpPage> createState() => _ForgotPasswordOtpPageState();
}

class _ForgotPasswordOtpPageState extends State<ForgotPasswordOtpPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  bool _isSendingOtp = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSendingOtp = true;
    });

    try {
      final normalizedPhone = PasswordValidation.normalizeThaiPhone(
        _phoneController.text,
      );
      final result = await AuthService.requestForgotPasswordOtp(
        phoneNumber: normalizedPhone,
      );

      if (!mounted) return;

      if (result.success) {
        Navigator.pushNamed(
          context,
          AppRouter.forgotPasswordOtpVerifyRoute,
          arguments: {'phoneNumber': normalizedPhone},
        );
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'ไม่สามารถส่ง OTP ได้')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingOtp = false;
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
                  padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 24.h),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Form(
                        key: _formKey,
                        child: Padding(
                          padding: EdgeInsets.only(top: 78.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ลืมรหัสผ่าน',
                                style: TextStyle(
                                  fontFamily: 'Sarabun',
                                  fontSize: 28.sp,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  height: 1.0,
                                ),
                              ),
                              SizedBox(height: 20.h),
                              _buildFieldLabel('เบอร์โทรศัพท์'),
                              SizedBox(height: 8.h),
                              AppInputText(
                                controller: _phoneController,
                                hintText: 'กรอกเบอร์โทรศัพท์',
                                keyboardType: TextInputType.phone,
                                validator: PasswordValidation.validateThaiPhone,
                              ),
                              SizedBox(height: 18.h),
                              SizedBox(
                                width: double.infinity,
                                child: AppButton(
                                  text: 'ส่ง OTP',
                                  isLoading: _isSendingOtp,
                                  backgroundColor: AppColors.primaryBlue,
                                  textColor: Colors.white,
                                  onPressed: _sendOtp,
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
                  left: 8.w,
                  top: 4.h,
                  child: IconButton(
                    padding: EdgeInsets.all(18.r),
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: AppColors.primaryBlue,
                      size: 24.sp,
                    ),
                    onPressed: () {
                      Navigator.pushReplacementNamed(
                        context,
                        AppRouter.loginRoute,
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
      style: TextStyle(
        fontFamily: 'Sarabun',
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryBlue,
      ),
    );
  }
}
