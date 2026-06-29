import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import '../../../core/firebase_provider.dart';

class NotificationAdminController {
  final FirebaseFirestore _firestore = AppFirebase.firestore;

  Stream<List<NotificationModel>> getNotifications() {
    return _firestore
        .collection('admin_notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => NotificationModel.fromFirestore(doc)).toList();
    });
  }

  Stream<int> getUnreadCount() {
    return _firestore
        .collection('admin_notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> markAsRead(String notificationId) async {
    await _firestore
        .collection('admin_notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> markAllAsRead() async {
    final query = await _firestore
        .collection('admin_notifications')
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (var doc in query.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  Future<void> deleteNotification(String notificationId) async {
    await _firestore
        .collection('admin_notifications')
        .doc(notificationId)
        .delete();
  }
}
