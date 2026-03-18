import 'package:flutter/material.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:capyadoo/core/model/medication_notification.dart';
import 'package:capyadoo/features/notifications/controller/notification_controller.dart';
import 'package:capyadoo/core/widgets/app_empty_card.dart';
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
  final Set<String> _selectedIds = {};

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
      if (!_isDeleteMode) {
        _selectedIds.clear();
      }
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;

    final confirmed = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      pageBuilder: (context, anim1, anim2) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'ยืนยันการลบ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'คุณแน่ใจหรือไม่ว่าต้องการลบข้อมูลนี้? การดำเนินการนี้ไม่สามารถย้อนกลับได้',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text(
                          'ยกเลิก',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'ลบ',
                          style: TextStyle(color: Colors.white),
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
    );

    if (confirmed != true) return;

    for (final id in _selectedIds.toList()) {
      await _controller.deleteNotification(id);
    }

    setState(() {
      _selectedIds.clear();
      _isDeleteMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Premium Header
          Container(
            height: 175,
            width: double.infinity,
            color: AppColors.primaryBlue,
            child: SafeArea(
              bottom: false,
              child: Align(
                alignment: Alignment.center,
                child: const Text(
                  'การแจ้งเตือน',
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

          // Header Bar with Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _controller.notifications.isEmpty
                      ? null
                      : _toggleDeleteMode,
                  child: Text(
                    _isDeleteMode ? 'เสร็จสิ้น' : 'ลบ',
                    style: TextStyle(
                      color: _isDeleteMode
                          ? AppColors.primaryBlue
                          : Colors.grey[600],
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Text(
                  'การแจ้งเตือนทั้งหมด',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                TextButton(
                  onPressed: () => _navigateToAdd(context),
                  child: Row(
                    children: [
                      Text(
                        'เพิ่ม',
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.add_circle,
                        color: AppColors.primaryBlue,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (_isDeleteMode && _selectedIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ElevatedButton.icon(
                onPressed: _deleteSelected,
                icon: const Icon(Icons.delete, color: Colors.white),
                label: const Text(
                  'ลบรายการที่เลือก',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Align(
          alignment: Alignment.topCenter,
          child: AppEmptyCard(
            icon: Icons.notifications_off_outlined,
            title: 'ยังไม่มีการแจ้งเตือน',
            subtitle: 'เพิ่มการแจ้งเตือนเพื่อไม่ให้พลาดการทานยา',
            iconColor: AppColors.textSublest,
            borderColor: AppColors.blueBorder,
            borderRadius: 10,
            borderWidth: 2,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _controller.notifications.length,
      itemBuilder: (context, index) {
        final notification = _controller.notifications[index];
        return NotificationListItem(
          notification: notification,
          isDeleteMode: _isDeleteMode,
          isSelected: _selectedIds.contains(notification.id),
          onSelectionChanged: (val) => _toggleSelection(notification.id!),
          onTap: () => _navigateToEdit(context, notification),
          onToggle: (val) => _controller.toggleNotification(notification),
        );
      },
    );
  }
}
