import 'package:flutter/material.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:capyadoo/core/routing/app_router.dart';
import 'package:capyadoo/core/widgets/app_logo.dart';
import 'package:capyadoo/features/profile/presentation/widgets/pin_service.dart';

class PinUnlockPage extends StatefulWidget {
  const PinUnlockPage({super.key});

  @override
  State<PinUnlockPage> createState() => _PinUnlockPageState();
}

class _PinUnlockPageState extends State<PinUnlockPage> {
  final List<String> _digits = [];
  bool _isLoading = true;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _loadPinState();
  }

  Future<void> _loadPinState() async {
    final enabled = await PinService.isPinEnabled();
    final hasPin = await PinService.hasPin();

    if (!mounted) return;

    if (!enabled || !hasPin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, AppRouter.mainRoute);
      });
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _onDigitTap(String digit) async {
    if (_isLoading || _isChecking) return;
    if (_digits.length >= 6) return;

    setState(() {
      _digits.add(digit);
    });

    if (_digits.length == 6) {
      await _verifyPin();
    }
  }

  void _onBackspaceTap() {
    if (_isLoading || _isChecking || _digits.isEmpty) return;

    setState(() {
      _digits.removeLast();
    });
  }

  Future<void> _verifyPin() async {
    setState(() {
      _isChecking = true;
    });

    final success = await PinService.verifyPin(_digits.join());

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacementNamed(context, AppRouter.mainRoute);
      return;
    }

    setState(() {
      _digits.clear();
      _isChecking = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'PIN ไม่ถูกต้อง กรุณาลองใหม่',
          style: TextStyle(fontFamily: 'Sarabun'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.authGradient),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(48.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const AppLogo(size: 80),
                        const SizedBox(height: 32),
                        const Text(
                          'ใส่ PIN เพื่อเข้าใช้งาน',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'กรอกรหัส PIN 6 หลักเพื่อปลดล็อกแอป',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSub,
                            fontFamily: 'Sarabun',
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(6, (index) {
                            final filled = index < _digits.length;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 18,
                              height: 18,
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: filled
                                    ? AppColors.primaryBlue
                                    : Colors.white,
                                border: Border.all(
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 28),
                        _PinKeyboard(
                          onDigitTap: _onDigitTap,
                          onBackspaceTap: _onBackspaceTap,
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _PinKeyboard extends StatelessWidget {
  final Future<void> Function(String digit) onDigitTap;
  final VoidCallback onBackspaceTap;

  const _PinKeyboard({required this.onDigitTap, required this.onBackspaceTap});

  @override
  Widget build(BuildContext context) {
    return Column(
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
            const Expanded(child: SizedBox()),
            _buildKey(
              child: const Text(
                '0',
                style: TextStyle(
                  fontFamily: 'Sarabun',
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlue,
                ),
              ),
              onTap: () => onDigitTap('0'),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: _buildBackspaceKey(onTap: onBackspaceTap),
              ),
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
                color: AppColors.primaryBlue,
              ),
            ),
            onTap: () => onDigitTap(digits[i]),
          ),
          if (i < digits.length - 1) const SizedBox(width: 22),
        ],
      ],
    );
  }

  Widget _buildKey({required Widget child, required VoidCallback onTap}) {
    return _PressableKey(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 86,
        height: 86,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primaryBlue),
          color: Colors.transparent,
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }

  Widget _buildBackspaceKey({required VoidCallback onTap}) {
    return _PressableKey(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: const SizedBox(
        width: 86,
        height: 86,
        child: Center(
          child: Icon(
            Icons.backspace_outlined,
            color: AppColors.textSub,
            size: 30,
          ),
        ),
      ),
    );
  }
}

class _PressableKey extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final BorderRadius borderRadius;

  const _PressableKey({
    required this.child,
    required this.onTap,
    required this.borderRadius,
  });

  @override
  State<_PressableKey> createState() => _PressableKeyState();
}

class _PressableKeyState extends State<_PressableKey> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value) return;
    setState(() {
      _isPressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) {
        _setPressed(false);
        widget.onTap();
      },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 80),
        scale: _isPressed ? 0.94 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            color: _isPressed
                ? Colors.white.withOpacity(0.08)
                : Colors.transparent,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
