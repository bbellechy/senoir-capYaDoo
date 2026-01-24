import 'package:flutter/material.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:capyadoo/core/model/medication_notification.dart';
import 'package:capyadoo/features/notifications/controller/notification_controller.dart';
import 'package:capyadoo/features/notifications/presentation/widgets/empty_notification_state.dart';
import 'package:capyadoo/features/notifications/presentation/widgets/notification_list_item.dart';

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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text(
          'คุณต้องการลบการแจ้งเตือน ${_selectedIds.length} รายการใช่หรือไม่?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Delete all selected notifications
    for (final id in _selectedIds.toList()) {
      await _controller.deleteNotification(id);
    }

    setState(() {
      _selectedIds.clear();
      _isDeleteMode = false;
    });
  }

  Future<void> _navigateToAddNotification() async {
    final result = await Navigator.pushNamed(context, '/notifications/add');

    if (result == true) {
      _loadNotifications();
    }
  }

  Future<void> _navigateToEditNotification(
    MedicationNotification notification,
  ) async {
    if (_isDeleteMode) return;

    final result = await Navigator.pushNamed(
      context,
      '/notifications/edit',
      arguments: notification,
    );

    if (result == true) {
      _loadNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isDeleteMode
              ? '${_selectedIds.length} รายการที่เลือก'
              : 'การแจ้งเตือน',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: _controller.notifications.isNotEmpty
            ? IconButton(
                icon: Icon(_isDeleteMode ? Icons.close : Icons.delete_outline),
                onPressed: _toggleDeleteMode,
                tooltip: _isDeleteMode ? 'ยกเลิก' : 'ลบ',
              )
            : null,
        actions: [
          if (_isDeleteMode && _selectedIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteSelected,
              tooltip: 'ลบที่เลือก',
            )
          else if (!_isDeleteMode && _controller.notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _navigateToAddNotification,
              tooltip: 'เพิ่มการแจ้งเตือน',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        color: AppColors.primaryBlue,
        child: _buildBody(),
      ),
      floatingActionButton:
          !_isDeleteMode && _controller.notifications.isNotEmpty
          ? FloatingActionButton(
              onPressed: _navigateToAddNotification,
              backgroundColor: AppColors.primaryBlue,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_controller.isLoading && _controller.notifications.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryBlue),
      );
    }

    if (_controller.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _controller.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadNotifications,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
              ),
              child: const Text('ลองอีกครั้ง'),
            ),
          ],
        ),
      );
    }

    if (_controller.notifications.isEmpty) {
      return EmptyNotificationState(onAddPressed: _navigateToAddNotification);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: _controller.notifications.length,
      itemBuilder: (context, index) {
        final notification = _controller.notifications[index];
        final isSelected = _selectedIds.contains(notification.id);

        if (_isDeleteMode) {
          return _buildDeleteModeItem(notification, isSelected);
        }

        return NotificationListItem(
          notification: notification,
          onToggle: (value) {
            _controller.toggleNotification(notification);
          },
          onTap: () => _navigateToEditNotification(notification),
        );
      },
    );
  }

  Widget _buildDeleteModeItem(
    MedicationNotification notification,
    bool isSelected,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? const BorderSide(color: AppColors.primaryBlue, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Checkbox
            Checkbox(
              value: isSelected,
              onChanged: (value) => _toggleSelection(notification.id!),
              activeColor: AppColors.primaryBlue,
            ),
            const SizedBox(width: 12),

            // Notification icon
            GestureDetector(
              onTap: () => _toggleSelection(notification.id!),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.medication,
                  color: AppColors.primaryBlue,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Notification details
            Expanded(
              child: GestureDetector(
                onTap: () => _toggleSelection(notification.id!),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.medicationName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Days
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          notification.getDayNames().join(', '),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Times
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            notification.getFormattedTimes().join(', '),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
