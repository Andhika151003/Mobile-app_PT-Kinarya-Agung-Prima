import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/notification/models/notification_model.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore;

  NotificationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ==== ADMIN NOTIFICATIONS ====

  Stream<List<NotificationModel>> getAdminNotificationsStream() {
    return _firestore
        .collection('admin_notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => NotificationModel.fromFirestore(doc)).toList();
    });
  }

  Stream<int> getAdminUnreadCountStream() {
    return _firestore
        .collection('admin_notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> markAdminNotificationAsRead(String notificationId) async {
    await _firestore
        .collection('admin_notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> markAllAdminNotificationsAsRead() async {
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

  Future<void> deleteAdminNotification(String notificationId) async {
    await _firestore.collection('admin_notifications').doc(notificationId).delete();
  }

  Future<void> addAdminNotification(Map<String, dynamic> data) async {
    await _firestore.collection('admin_notifications').add(data);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getAdminNotificationsSnapshotStream() {
    return _firestore
        .collection('admin_notifications')
        .where('timestamp', isGreaterThan: Timestamp.now())
        .snapshots();
  }

  // ==== USER NOTIFICATIONS ====

  Stream<List<NotificationModel>> getUserNotificationsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => NotificationModel.fromFirestore(doc)).toList();
    });
  }

  Stream<int> getUserUnreadCountStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> markUserNotificationAsRead(String userId, String notificationId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> markAllUserNotificationsAsRead(String userId) async {
    final query = await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (var doc in query.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  Future<void> deleteUserNotification(String userId, String notificationId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }

  Future<void> addUserNotification(String userId, Map<String, dynamic> data) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add(data);
  }

  Future<void> broadcastNotificationToAllUsers(Map<String, dynamic> data) async {
    final usersSnapshot = await _firestore.collection('users').get();
      
    final batch = _firestore.batch();
    for (var userDoc in usersSnapshot.docs) {
      final notifRef = userDoc.reference.collection('notifications').doc();
      batch.set(notifRef, data);
    }
    await batch.commit();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getUserNotificationsSnapshotStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('timestamp', isGreaterThan: Timestamp.now())
        .snapshots();
  }
}
