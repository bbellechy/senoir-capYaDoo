import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:capyadoo/core/providers/auth_provider.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:capyadoo/core/widgets/delete_dialog.dart';
import 'package:capyadoo/core/routing/app_router.dart';
import 'package:capyadoo/core/services/notification_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
            height: 175,
            width: double.infinity,
            color: AppColors.primaryBlue,
            child: SafeArea(
              bottom: false,
              child: const Align(
                alignment: Alignment.center,
                child: Text(
                  'โปรไฟล์',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Sarabun',
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.primaryBlue,
                    child: const Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.fullName ?? 'ผู้ใช้งาน',
                    style: const TextStyle(
                      fontSize: 24,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user?.username ?? '—',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textSub,
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildSettingsCard(),
                  const SizedBox(height: 14),
                  _buildLogoutButton(),
                  const SizedBox(height: 10),
                  const Text(
                    'เวอร์ชัน 1.0.0',
                    style: TextStyle(
                      fontFamily: 'Sarabun',
                      color: AppColors.textSub,
                      fontSize: 14,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.blueBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            child: Text(
              'การตั้งค่า',
              style: TextStyle(
                fontFamily: 'Sarabun',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
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
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'การแจ้งเตือน',
                        style: TextStyle(
                          fontFamily: 'Sarabun',
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSub,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'เปิด/ปิด การแจ้งเตือน',
                        style: TextStyle(
                          fontFamily: 'Sarabun',
                          fontSize: 16,
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
                  trackOutlineColor: MaterialStateProperty.resolveWith((
                    states,
                  ) {
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
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Sarabun',
                  fontSize: 20,
                  color: AppColors.textSub,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSub),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.red, AppColors.error],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.error.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'ออกจากระบบ',
                style: TextStyle(
                  fontFamily: 'Sarabun',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Colors.white,
                  letterSpacing: 0.2,
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
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Divider(height: 1, thickness: 1, color: AppColors.textSublest),
    );
  }
}
