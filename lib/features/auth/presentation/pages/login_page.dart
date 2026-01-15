import 'package:flutter/material.dart';
import 'package:capyadoo/core/widgets/app_input_text.dart';
import 'package:capyadoo/core/widgets/app_button.dart';
import 'package:capyadoo/core/widgets/app_logo.dart';
import 'package:capyadoo/core/constants/app_colors.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      // TODO: Implement login logic
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('กำลังเข้าสู่ระบบ...')));
    }
  }

  void _navigateToRegister() {
    Navigator.pushNamed(context, '/register');
  }

  void _handleForgotPassword() {
    // TODO: Implement forgot password
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('ฟีเจอร์ลืมรหัสผ่าน')));
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
                    const SizedBox(height: 32),

                    // Title
                    const Text(
                      'เข้าสู่ระบบ',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 32),

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
                    const SizedBox(height: 20),

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
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'กรุณากรอกรหัสผ่าน';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _handleForgotPassword,
                            child: const Text(
                              'ลืมรหัสผ่าน?',
                              style: TextStyle(
                                color: AppColors.primaryBlue,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Login Button
                    AppButton(text: 'เข้าสู่ระบบ', onPressed: _handleLogin),
                    const SizedBox(height: 16),

                    // Register Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'ยังไม่มีบัญชี? ',
                          style: TextStyle(
                            color: AppColors.textSub,
                            fontSize: 16,
                          ),
                        ),
                        TextButton(
                          onPressed: _navigateToRegister,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'ลงทะเบียน',
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
}
