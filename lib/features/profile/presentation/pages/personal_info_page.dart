import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:capyadoo/core/providers/auth_provider.dart';
import 'package:capyadoo/core/services/auth_service.dart';
import 'package:capyadoo/core/validators/password_validation.dart';
import 'package:capyadoo/core/widgets/app_input_text.dart';

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneNumberController = TextEditingController();

  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthProvider>().loadProfile();
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  void _syncControllersFromUser() {
    if (_isEditing) return;

    final user = context.read<AuthProvider>().user;
    final nextFullName = user?.fullName ?? '';
    final nextUsername = user?.username ?? '';
    final nextPhoneNumber = user?.phoneNumber ?? '';

    final isSame =
        _fullNameController.text == nextFullName &&
        _usernameController.text == nextUsername &&
        _phoneNumberController.text == nextPhoneNumber;

    if (isSame) return;

    _fullNameController.text = nextFullName;
    _usernameController.text = nextUsername;
    _phoneNumberController.text = nextPhoneNumber;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final normalizedPhone = PasswordValidation.normalizeThaiPhone(
        _phoneNumberController.text,
      );
      final success = await AuthService.updateProfile(
        fullName: _fullNameController.text.trim(),
        username: _usernameController.text.trim(),
        phoneNumber: normalizedPhone,
      );

      if (!mounted) return;

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกข้อมูลไม่สำเร็จ กรุณาลองใหม่')),
        );
        return;
      }

      await context.read<AuthProvider>().loadProfile();

      if (!mounted) return;
      setState(() {
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกข้อมูลส่วนตัวสำเร็จ')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isLoadingProfile = context.watch<AuthProvider>().isLoadingProfile;
    _syncControllersFromUser();

    final hasVisibleData =
        _fullNameController.text.trim().isNotEmpty ||
        _usernameController.text.trim().isNotEmpty ||
        _phoneNumberController.text.trim().isNotEmpty;

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
                                'ข้อมูลผู้ใช้งาน',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Sarabun',
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
              padding: const EdgeInsets.fromLTRB(32, 20, 32, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text(
                          'ข้อมูลผู้ใช้งาน',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontFamily: 'Sarabun',
                            fontWeight: FontWeight.w700,
                            fontSize: 24,
                          ),
                        ),
                        const Spacer(),
                        if (!_isEditing)
                          TextButton(
                            onPressed: _isSaving
                                ? null
                                : () {
                                    setState(() {
                                      _isEditing = true;
                                    });
                                  },
                            child: Text(
                              'แก้ไข',
                              style: const TextStyle(
                                color: AppColors.primaryBlue,
                                fontFamily: 'Sarabun',
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _buildEditableField(
                      label: 'ชื่อ-นามสกุล',
                      controller: _fullNameController,
                      enabled: _isEditing,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'กรุณากรอกชื่อ-นามสกุล';
                        }
                        return null;
                      },
                    ),
                    const _InfoDivider(),
                    _buildEditableField(
                      label: 'ชื่อผู้ใช้งาน',
                      controller: _usernameController,
                      enabled: _isEditing,
                      validator: _validateLowercaseUsername,
                    ),
                    const _InfoDivider(),
                    _buildEditableField(
                      label: 'เบอร์โทรศัพท์',
                      controller: _phoneNumberController,
                      enabled: _isEditing,
                      keyboardType: TextInputType.phone,
                      validator: PasswordValidation.validateThaiPhone,
                    ),
                    if (_isEditing) ...[
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: OutlinedButton(
                                onPressed: _isSaving
                                    ? null
                                    : () {
                                        setState(() {
                                          _isEditing = false;
                                          _syncControllersFromUser();
                                        });
                                      },
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF4F4F4),
                                  side: const BorderSide(
                                    color: Color(0xFFCCCCCC),
                                    width: 1.2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'ยกเลิก',
                                  style: TextStyle(
                                    color: Color(0xFF666666),
                                    fontFamily: 'Sarabun',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: ElevatedButton(
                                onPressed: _isSaving ? null : _save,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryBlue,
                                  disabledBackgroundColor:
                                      AppColors.textSublest,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: _isSaving
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : const Text(
                                        'บันทึก',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'Sarabun',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (!_isEditing &&
                        user == null &&
                        !isLoadingProfile &&
                        !hasVisibleData)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'ไม่พบข้อมูลผู้ใช้',
                          style: TextStyle(
                            fontFamily: 'Sarabun',
                            color: AppColors.textSub,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _validateLowercaseUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'กรุณากรอกชื่อผู้ใช้งาน';
    }

    final trimmed = value.trim();
    if (trimmed != trimmed.toLowerCase()) {
      return 'กรุณากรอกชื่อผู้ใช้งานเป็นตัวพิมพ์เล็กเท่านั้น';
    }

    return null;
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Sarabun',
              fontSize: 16,
              color: AppColors.textSub,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (enabled)
            AppInputText(
              controller: controller,
              enabled: enabled,
              keyboardType: keyboardType,
              validator: validator,
              hintText: '',
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 50),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    controller.text.trim().isNotEmpty
                        ? controller.text.trim()
                        : '—',
                    style: const TextStyle(
                      fontFamily: 'Sarabun',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoDivider extends StatelessWidget {
  const _InfoDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: AppColors.textSublest);
  }
}
