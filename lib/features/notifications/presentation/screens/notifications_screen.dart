import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../widgets/notification_item.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Mock notification data
  static const List<Map<String, dynamic>> mockNotifications = [
    {
      'id': '1',
      'type': 'order_confirmed',
      'title': 'Đơn hàng được xác nhận',
      'message': 'Đơn hàng #ABC123 của bạn đã được xác nhận',
      'icon': Icons.check_circle,
      'color': AppColors.success,
      'timestamp': '2 giờ trước',
      'isRead': false,
    },
    {
      'id': '2',
      'type': 'order_shipped',
      'title': 'Đơn hàng đang được giao',
      'message': 'Đơn hàng #ABC122 của bạn đang được giao',
      'icon': Icons.local_shipping,
      'color': AppColors.secondary,
      'timestamp': '5 giờ trước',
      'isRead': false,
    },
    {
      'id': '3',
      'type': 'promotion',
      'title': 'Khuyến mãi đặc biệt',
      'message': 'Giảm 30% cho tất cả sản phẩm thể dục - Hôm nay chỉ',
      'icon': Icons.local_offer,
      'color': AppColors.primary,
      'timestamp': '1 ngày trước',
      'isRead': true,
    },
    {
      'id': '4',
      'type': 'payment_success',
      'title': 'Thanh toán thành công',
      'message': 'Thanh toán 1.500.000đ cho đơn hàng #ABC121 thành công',
      'icon': Icons.credit_card,
      'color': AppColors.success,
      'timestamp': '2 ngày trước',
      'isRead': true,
    },
    {
      'id': '5',
      'type': 'back_in_stock',
      'title': 'Sản phẩm có hàng trở lại',
      'message': 'Sản phẩm "Tạ tay 5kg" mà bạn yêu thích đã có hàng',
      'icon': Icons.inventory_2,
      'color': AppColors.primary,
      'timestamp': '3 ngày trước',
      'isRead': true,
    },
  ];

  String _selectedFilter = 'all'; // all, unread

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filteredNotifications = _selectedFilter == 'unread'
        ? mockNotifications
            .where((n) => n['isRead'] == false)
            .toList()
        : mockNotifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        elevation: 0,
        actions: [
          if (filteredNotifications.any((n) => n['isRead'] == false))
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: const Text('Đánh dấu tất cả đã đọc'),
                  onTap: _markAllAsRead,
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pageHorizontal,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Tất cả'),
                  selected: _selectedFilter == 'all',
                  onSelected: (_) => setState(() => _selectedFilter = 'all'),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Chưa đọc'),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${mockNotifications.where((n) => n['isRead'] == false).length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  selected: _selectedFilter == 'unread',
                  onSelected: (_) => setState(() => _selectedFilter = 'unread'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),

          // Notifications list
          Expanded(
            child: filteredNotifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_off_outlined,
                          size: 64,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Không có thông báo',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.pageHorizontal,
                    ),
                    itemCount: filteredNotifications.length,
                    itemBuilder: (context, index) {
                      final notification = filteredNotifications[index];
                      return NotificationItem(
                        notification: notification,
                        onTap: () => _markAsRead(notification['id']),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _markAsRead(String notificationId) {
    // TODO: Implement mark as read
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đánh dấu thông báo đã đọc')),
    );
  }

  void _markAllAsRead() {
    // TODO: Implement mark all as read
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đánh dấu tất cả thông báo đã đọc')),
    );
  }
}

