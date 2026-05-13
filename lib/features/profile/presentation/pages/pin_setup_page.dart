import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:capyadoo/features/profile/presentation/widgets/pin_service.dart';

class PinSetupPage extends StatefulWidget {
  const PinSetupPage({super.key});

  @override
  State<PinSetupPage> createState() => _PinSetupPageState();
}

class _PinSetupPageState extends State<PinSetupPage> {
  String _currentPin = '';
  String? _firstPin;
  bool _isConfirmStep = false;

  Future<void> _onNumberTap(String digit) async {
    if (_currentPin.length >= 6) return;

    setState(() {
      _currentPin += digit;
    });

    if (_currentPin.length == 6) {
      await Future.delayed(const Duration(milliseconds: 120));
      await _onSixDigitsEntered();
    }
  }

  Future<void> _onSixDigitsEntered() async {
    if (!_isConfirmStep) {
      setState(() {
        _firstPin = _currentPin;
        _currentPin = '';
        _isConfirmStep = true;
      });
      _showSnackBar('กรุณาใส่ PIN อีกครั้งเพื่อยืนยัน');
      return;
    }

    if (_firstPin == _currentPin) {
      await PinService.savePin(_currentPin);
      await PinService.setPinEnabled(true);
      if (!mounted) return;
      _showSnackBar('ตั้งค่า PIN สำเร็จ');
      Navigator.pop(context, true);
      return;
    }

    setState(() {
      _currentPin = '';
      _firstPin = null;
      _isConfirmStep = false;
    });
    _showSnackBar('PIN ไม่ตรงกัน กรุณาลองใหม่');
  }

  void _onBackspaceTap() {
    if (_currentPin.isEmpty) return;
    setState(() {
      _currentPin = _currentPin.substring(0, _currentPin.length - 1);
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Sarabun')),
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
            width: double.infinity,
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
                              icon: const Icon(
                                Icons.arrow_back_ios,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Expanded(
                              child: Text(
                                'ตั้งค่า PIN',
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
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 80.h, 16.w, 16.h),
              child: Column(
                children: [
                  Text(
                    _isConfirmStep ? 'ยืนยันรหัส PIN' : 'ใส่รหัส PIN',
                    style: TextStyle(
                      fontFamily: 'Sarabun',
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 28.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (index) {
                      final filled = index < _currentPin.length;
                      return Container(
                        width: 18.w,
                        height: 18.h,
                        margin: EdgeInsets.symmetric(horizontal: 6.w),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: filled ? AppColors.primaryBlue : Colors.white,
                          border: Border.all(color: AppColors.primaryBlue, width: 1.w),
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: 26.h),
                  Expanded(
                    child: _PinKeyboard(
                      onNumberTap: _onNumberTap,
                      onBackspaceTap: _onBackspaceTap,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PinKeyboard extends StatelessWidget {
  final Future<void> Function(String digit) onNumberTap;
  final VoidCallback onBackspaceTap;

  const _PinKeyboard({required this.onNumberTap, required this.onBackspaceTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _buildNumberRow(['1', '2', '3']),
        SizedBox(height: 12.h),
        _buildNumberRow(['4', '5', '6']),
        SizedBox(height: 12.h),
        _buildNumberRow(['7', '8', '9']),
        SizedBox(height: 12.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 86.w),
            _buildKey(
              child: Text(
                '0',
                style: TextStyle(
                  fontFamily: 'Sarabun',
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSub,
                ),
              ),
              onTap: () => onNumberTap('0'),
            ),
            SizedBox(width: 22.w),
            _buildKey(
              child: Icon(
                Icons.backspace_outlined,
                color: AppColors.textSub,
                size: 30.sp,
              ),
              onTap: onBackspaceTap,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNumberRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < digits.length; i++) ...[
          _buildKey(
            child: Text(
              digits[i],
              style: TextStyle(
                fontFamily: 'Sarabun',
                fontSize: 28.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textSub,
              ),
            ),
            onTap: () => onNumberTap(digits[i]),
          ),
          if (i < digits.length - 1) SizedBox(width: 22.w),
        ],
      ],
    );
  }

  Widget _buildKey({required Widget child, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(40.r),
      onTap: onTap,
      child: Container(
        width: 86.w,
        height: 86.h,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.textSublest, width: 1.w),
          color: Colors.transparent,
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}
