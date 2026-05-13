import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
          SnackBar(content: Text('บันทึกข้อมูลไม่สำเร็จ กรุณาลองใหม่', style: TextStyle(fontFamily: 'Sarabun', fontSize: 14.sp))),
        );
        return;
      }

      await context.read<AuthProvider>().loadProfile();

      if (!mounted) return;
      setState(() {
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('บันทึกข้อมูลส่วนตัวสำเร็จ', style: TextStyle(fontFamily: 'Sarabun', fontSize: 14.sp))),
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
                              icon: Icon(
                                Icons.arrow_back_ios,
                                color: Colors.white,
                                size: 24.sp,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Expanded(
                              child: Text(
                                'ข้อมูลผู้ใช้งาน',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32.sp,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Sarabun',
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
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(32.w, 20.h, 32.w, 24.h),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          'ข้อมูลผู้ใช้งาน',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontFamily: 'Sarabun',
                            fontWeight: FontWeight.w700,
                            fontSize: 24.sp,
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
                              style: TextStyle(
                                color: AppColors.primaryBlue,
                                fontFamily: 'Sarabun',
                                fontWeight: FontWeight.w700,
                                fontSize: 18.sp,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 6.h),
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
                      SizedBox(height: 18.h),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 46.h,
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
                                  side: BorderSide(
                                    color: const Color(0xFFCCCCCC),
                                    width: 1.2.w,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                ),
                                child: Text(
                                  'ยกเลิก',
                                  style: TextStyle(
                                    color: const Color(0xFF666666),
                                    fontFamily: 'Sarabun',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16.sp,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: SizedBox(
                              height: 46.h,
                              child: ElevatedButton(
                                onPressed: _isSaving ? null : _save,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryBlue,
                                  disabledBackgroundColor:
                                      AppColors.textSublest,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                ),
                                child: _isSaving
                                    ? SizedBox(
                                        width: 20.w,
                                        height: 20.h,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.w,
                                          valueColor:
                                              const AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : Text(
                                        'บันทึก',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'Sarabun',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16.sp,
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
                      Padding(
                        padding: EdgeInsets.only(top: 8.h),
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
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Sarabun',
              fontSize: 16.sp,
              color: AppColors.textSub,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
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
              constraints: BoxConstraints(minHeight: 50.h),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 14.h,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    controller.text.trim().isNotEmpty
                        ? controller.text.trim()
                        : '—',
                    style: TextStyle(
                      fontFamily: 'Sarabun',
                      fontSize: 16.sp,
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
    return Divider(height: 1.h, thickness: 1.h, color: AppColors.textSublest);
  }
}
