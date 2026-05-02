import 'package:ecommerce/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controllers/notif_user_controller.dart';
import '../models/notification_model.dart';

class NotificationUserView extends StatefulWidget {
  const NotificationUserView({super.key});

  @override
  State<NotificationUserView> createState() => _NotificationUserViewState();
}

class _NotificationUserViewState extends State<NotificationUserView> {
  final NotificationUserController _controller = NotificationUserController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Notifikasi',
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
              'Baca Semua',
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
                    'Belum ada notifikasi',
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
        icon = Icons.shopping_bag_outlined;
        iconColor = Colors.blue;
        bgColor = Colors.blue.withValues(alpha: 0.1);
        break;
      case 'promo':
        icon = Icons.local_offer_outlined;
        iconColor = Colors.orange;
        bgColor = Colors.orange.withValues(alpha: 0.1);
        break;
      case 'complaint':
        icon = Icons.support_agent_outlined;
        iconColor = Colors.purple;
        bgColor = Colors.purple.withValues(alpha: 0.1);
        break;
      default:
        icon = Icons.notifications_outlined;
        iconColor = Colors.grey;
        bgColor = Colors.grey.withValues(alpha: 0.1);
    }

    return GestureDetector(
      onTap: () {
        if (!notif.isRead) {
          _controller.markAsRead(notif.id);
        }
        // Handle navigation based on type if needed
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notif.isRead ? Colors.white : AppColors.primary.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notif.isRead ? Colors.transparent : AppColors.primary.withValues(alpha: 0.1),
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
                            fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.w800,
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      if (!notif.isRead)
                        Container(
                          width: 8,
                          height: 8,
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
                      color: Colors.grey[600],
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('MMM dd, HH:mm').format(notif.timestamp),
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
