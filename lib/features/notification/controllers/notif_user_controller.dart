import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';
import '../../../core/repositories/notification_repository.dart';

class NotificationUserController {
  final FirebaseAuth _auth;
  final NotificationRepository _notificationRepository;

  NotificationUserController({
    FirebaseAuth? auth,
    NotificationRepository? notificationRepository,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _notificationRepository = notificationRepository ?? NotificationRepository();

  Stream<List<NotificationModel>> getNotifications() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _notificationRepository.getUserNotificationsStream(user.uid);
  }

  Stream<int> getUnreadCount() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(0);

    return _notificationRepository.getUserUnreadCountStream(user.uid);
  }

  Future<void> markAsRead(String notificationId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _notificationRepository.markUserNotificationAsRead(user.uid, notificationId);
  }

  Future<void> markAllAsRead() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _notificationRepository.markAllUserNotificationsAsRead(user.uid);
  }

  Future<void> deleteNotification(String notificationId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _notificationRepository.deleteUserNotification(user.uid, notificationId);
  }
}
