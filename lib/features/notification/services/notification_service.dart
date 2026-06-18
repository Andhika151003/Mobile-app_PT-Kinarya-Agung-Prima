import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final FirebaseFirestore _firestore;

  NotificationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Add Notification for a Specific User
  Future<void> addUserNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? relatedId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
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
      await _firestore.collection('admin_notifications').add({
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
