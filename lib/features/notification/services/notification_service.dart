import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../core/repositories/notification_repository.dart';

class NotificationService {
  final NotificationRepository _notificationRepository;

  NotificationService({NotificationRepository? notificationRepository})
      : _notificationRepository = notificationRepository ?? NotificationRepository();

  // Add Notification for a Specific User
  Future<void> addUserNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? relatedId,
  }) async {
    try {
      await _notificationRepository.addUserNotification(userId, {
        'title': title,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': type,
        'relatedId': relatedId,
      });
    } catch (e) {
      debugPrint('Error adding user notification: $e');
    }
  }

  // Add Notification for Admins
  Future<void> addAdminNotification({
    required String title,
    required String message,
    required String type,
    String? relatedId,
  }) async {
    try {
      await _notificationRepository.addAdminNotification({
        'title': title,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': type,
        'relatedId': relatedId,
      });
    } catch (e) {
      debugPrint('Error adding admin notification: $e');
    }
  }
}
