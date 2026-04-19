import 'package:flutter/material.dart';
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
            height: 160,
            width: double.infinity,
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
                                'ตั้งค่า PIN',
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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
              child: Column(
                children: [
                  Text(
                    _isConfirmStep ? 'ยืนยันรหัส PIN' : 'ใส่รหัส PIN',
                    style: const TextStyle(
                      fontFamily: 'Sarabun',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (index) {
                      final filled = index < _currentPin.length;
                      return Container(
                        width: 18,
                        height: 18,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: filled ? AppColors.primaryBlue : Colors.white,
                          border: Border.all(color: AppColors.primaryBlue),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 26),
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
        const SizedBox(height: 12),
        _buildNumberRow(['4', '5', '6']),
        const SizedBox(height: 12),
        _buildNumberRow(['7', '8', '9']),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 86),
            _buildKey(
              child: const Text(
                '0',
                style: TextStyle(
                  fontFamily: 'Sarabun',
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSub,
                ),
              ),
              onTap: () => onNumberTap('0'),
            ),
            const SizedBox(width: 22),
            _buildKey(
              child: const Icon(
                Icons.backspace_outlined,
                color: AppColors.textSub,
                size: 30,
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
              style: const TextStyle(
                fontFamily: 'Sarabun',
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: AppColors.textSub,
              ),
            ),
            onTap: () => onNumberTap(digits[i]),
          ),
          if (i < digits.length - 1) const SizedBox(width: 22),
        ],
      ],
    );
  }

  Widget _buildKey({required Widget child, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(40),
      onTap: onTap,
      child: Container(
        width: 86,
        height: 86,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.textSublest),
          color: Colors.transparent,
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}
