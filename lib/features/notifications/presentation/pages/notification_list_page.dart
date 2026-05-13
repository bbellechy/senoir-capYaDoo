import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:capyadoo/core/model/medication_notification.dart';
import 'package:capyadoo/features/notifications/controller/notification_controller.dart';
import 'package:capyadoo/core/widgets/app_empty_card.dart';
import 'package:capyadoo/core/widgets/delete_dialog.dart';
import 'package:capyadoo/features/notifications/presentation/widgets/notification_list_item.dart';
import 'package:capyadoo/features/notifications/presentation/pages/add_notification_page.dart';
import 'package:capyadoo/features/notifications/presentation/pages/edit_notification_page.dart';

class NotificationListPage extends StatefulWidget {
  const NotificationListPage({super.key});

  @override
  State<NotificationListPage> createState() => _NotificationListPageState();
}

class _NotificationListPageState extends State<NotificationListPage> {
  final NotificationController _controller = NotificationController();
  bool _isInitialized = false;
  bool _isDeleteMode = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (!_isInitialized) {
      _isInitialized = true;
      _controller.addListener(_onControllerUpdate);
    }
    await _controller.loadNotifications();
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  void _toggleDeleteMode() {
    setState(() {
      _isDeleteMode = !_isDeleteMode;
    });
  }

  Future<void> _deleteNotificationItem(String id) async {
    final confirmed = await showDeleteDialog(
      context,
      title: 'ยืนยันการลบ',
      message:
          'คุณแน่ใจหรือไม่ว่าต้องการลบข้อมูลนี้ ?\nการดำเนินการนี้ไม่สามารถย้อนกลับได้',
    );

    if (confirmed != true) return;

    await _controller.deleteNotification(id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                      'การแจ้งเตือน',
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

          // Header Bar with Actions
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                if (_isDeleteMode)
                  ElevatedButton(
                    onPressed: _toggleDeleteMode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 10.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    child: Text(
                      'เสร็จสิ้น',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else
                  TextButton(
                    onPressed: _controller.notifications.isEmpty
                        ? null
                        : _toggleDeleteMode,
                    child: Text(
                      'ลบ',
                      style: TextStyle(
                        color: AppColors.textSub,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'การแจ้งเตือนทั้งหมด',
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w600),
                  ),
                ),
                SizedBox(width: 8.w),
                TextButton(
                  onPressed: () => _navigateToAdd(context),
                  child: Row(
                    children: [
                      Text(
                        'เพิ่ม',
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(
                        Icons.add_circle,
                        color: AppColors.primaryBlue,
                        size: 24.sp,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadNotifications,
              color: AppColors.primaryBlue,
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToAdd(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddNotificationPage()),
    );
    if (result == true) _loadNotifications();
  }

  void _navigateToEdit(
    BuildContext context,
    MedicationNotification notification,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditNotificationPage(notification: notification),
      ),
    );
    if (result == true) _loadNotifications();
  }

  Widget _buildBody() {
    if (_controller.isLoading && _controller.notifications.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryBlue),
      );
    }

    if (_controller.notifications.isEmpty) {
      return Padding(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
        child: Align(
          alignment: Alignment.topCenter,
          child: AppEmptyCard(
            icon: Icons.notifications_off_outlined,
            title: 'ยังไม่มีการแจ้งเตือน',
            subtitle: 'เพิ่มการแจ้งเตือนเพื่อไม่ให้พลาดการทานยา',
            iconColor: AppColors.textSublest,
            borderColor: AppColors.blueBorder,
            borderRadius: 10.r,
            borderWidth: 2.w,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
      itemCount: _controller.notifications.length,
      itemBuilder: (context, index) {
        final notification = _controller.notifications[index];
        return NotificationListItem(
          notification: notification,
          isDeleteMode: _isDeleteMode,
          onDelete: notification.id == null
              ? null
              : () => _deleteNotificationItem(notification.id!),
          onTap: () => _navigateToEdit(context, notification),
          onToggle: (val) => _controller.toggleNotification(notification),
        );
      },
    );
  }
}
