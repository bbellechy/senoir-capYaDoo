import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:capyadoo/core/providers/auth_provider.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:capyadoo/core/widgets/delete_dialog.dart';
import 'package:capyadoo/core/routing/app_router.dart';
import 'package:capyadoo/core/services/notification_service.dart';
import 'package:capyadoo/features/profile/presentation/pages/pin_settings_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();
  }

  Future<void> _loadNotificationPreference() async {
    final enabled = await NotificationService.isPhoneNotificationsEnabled();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = enabled;
    });
  }

  Future<void> _onToggleNotifications(bool value) async {
    setState(() {
      _notificationsEnabled = value;
    });

    await NotificationService.setPhoneNotificationsEnabled(value);

    if (!value) {
      await NotificationService.cancelAllNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      backgroundColor: AppColors.offwhite,
      body: Column(
        children: [
          // Premium Header
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
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      'โปรไฟล์',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36.sp,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Sarabun',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.r),
              child: Column(
                children: [
                  SizedBox(height: 20.h),
                  CircleAvatar(
                    radius: 48.r,
                    backgroundColor: AppColors.primaryBlue,
                    child: Icon(
                      Icons.person,
                      size: 60.sp,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    user?.fullName ?? 'ผู้ใช้งาน',
                    style: TextStyle(
                      fontSize: 24.sp,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    user?.username ?? '—',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: AppColors.textSub,
                    ),
                  ),
                  SizedBox(height: 30.h),
                  _buildSettingsCard(),
                  SizedBox(height: 14.h),
                  _buildLogoutButton(),
                  SizedBox(height: 10.h),
                  Text(
                    'เวอร์ชัน 1.0.0',
                    style: TextStyle(
                      fontFamily: 'Sarabun',
                      color: AppColors.textSub,
                      fontSize: 14.sp,
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

  Widget _buildSettingsCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.blueBorder, width: 1.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 4.h),
            child: Text(
              'การตั้งค่า',
              style: TextStyle(
                fontFamily: 'Sarabun',
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          _buildArrowTile(
            title: 'ข้อมูลผู้ใช้งาน',
            onTap: () {
              Navigator.pushNamed(context, AppRouter.personalInfoRoute);
            },
          ),
          const _SettingsDivider(),
          _buildArrowTile(
            title: 'เปลี่ยนรหัสผ่าน',
            onTap: () {
              Navigator.pushNamed(context, AppRouter.changePasswordRoute);
            },
          ),
          const _SettingsDivider(),
          _buildArrowTile(
            title: 'ตั้งค่า PIN เข้าใช้งาน',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PinSettingsPage()),
              );
            },
          ),
          const _SettingsDivider(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 10.h),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'การแจ้งเตือน',
                        style: TextStyle(
                          fontFamily: 'Sarabun',
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSub,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'เปิด/ปิด การแจ้งเตือน',
                        style: TextStyle(
                          fontFamily: 'Sarabun',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSub,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _notificationsEnabled,
                  activeColor: Colors.white,
                  activeTrackColor: AppColors.primaryBlue,
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: AppColors.textSublest,
                  trackOutlineColor: MaterialStateProperty.resolveWith((states) {
                    if (states.contains(MaterialState.selected)) {
                      return Colors.transparent;
                    }
                    return AppColors.textSublest;
                  }),
                  onChanged: _onToggleNotifications,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArrowTile({required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 12.h),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: 'Sarabun',
                  fontSize: 20.sp,
                  color: AppColors.textSub,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textSub, size: 24.sp),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: () async {
          final confirm = await showDeleteDialog(
            context,
            title: 'ยืนยันการออกจากระบบ',
            message: 'คุณแน่ใจหรือไม่ว่าต้องการออกจากระบบ?',
            confirmText: 'ยืนยัน',
          );

          if (!confirm) return;

          await context.read<AuthProvider>().logout();
          if (context.mounted) {
            Navigator.pushReplacementNamed(context, '/login');
          }
        },
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.red, AppColors.error],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.error.withOpacity(0.25),
                blurRadius: 12.r,
                offset: Offset(0, 6.h),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32.w,
                height: 32.h,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.logout_rounded,
                  size: 18.sp,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                'ออกจากระบบ',
                style: TextStyle(
                  fontFamily: 'Sarabun',
                  fontWeight: FontWeight.w700,
                  fontSize: 18.sp,
                  color: Colors.white,
                  letterSpacing: 0.2.w,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Divider(height: 1.h, thickness: 1.h, color: AppColors.textSublest),
    );
  }
}
