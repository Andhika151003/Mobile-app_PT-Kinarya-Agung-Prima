import 'package:ecommerce/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controllers/notif_admin_controller.dart';
import '../models/notification_model.dart';
import '../../order/views/order_detail_admin_view.dart';

class NotificationAdminView extends StatefulWidget {
  final NotificationAdminController? controller;
  const NotificationAdminView({super.key, this.controller});

  @override
  State<NotificationAdminView> createState() => _NotificationAdminViewState();
}

class _NotificationAdminViewState extends State<NotificationAdminView> {
  late final NotificationAdminController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? NotificationAdminController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Admin Notifications',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          TextButton(
            onPressed: () => _controller.markAllAsRead(),
            child: const Text(
              'Mark All Read',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _controller.getNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_outlined,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No admin notifications',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return _buildNotificationItem(notif);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notif) {
    IconData icon;
    Color iconColor;
    Color bgColor;

    switch (notif.type) {
      case 'order':
        icon = Icons.shopping_cart_outlined;
        iconColor = Colors.green;
        bgColor = Colors.green.withValues(alpha: 0.1);
        break;
      case 'complaint':
        icon = Icons.error_outline;
        iconColor = Colors.red;
        bgColor = Colors.red.withValues(alpha: 0.1);
        break;
      case 'system':
        icon = Icons.settings_outlined;
        iconColor = Colors.grey;
        bgColor = Colors.grey.withValues(alpha: 0.1);
        break;
      default:
        icon = Icons.notifications_outlined;
        iconColor = Colors.blue;
        bgColor = Colors.blue.withValues(alpha: 0.1);
    }

    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) => _controller.deleteNotification(notif.id),
      child: GestureDetector(
        onTap: () {
          if (!notif.isRead) {
            _controller.markAsRead(notif.id);
          }
          if (notif.relatedId != null && notif.type == 'order') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OrderDetailAdminView(orderId: notif.relatedId!),
              ),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notif.isRead ? Colors.white : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: notif.isRead ? const Color(0xFFE5E7EB) : AppColors.primary.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: TextStyle(
                              fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (!notif.isRead)
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif.message,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('MMM dd, HH:mm').format(notif.timestamp),
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
