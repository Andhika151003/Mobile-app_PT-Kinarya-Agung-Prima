import '../models/notification_model.dart';
import '../../../core/repositories/notification_repository.dart';

class NotificationAdminController {
  final NotificationRepository _notificationRepository;

  NotificationAdminController({NotificationRepository? notificationRepository})
      : _notificationRepository = notificationRepository ?? NotificationRepository();

  Stream<List<NotificationModel>> getNotifications() {
    return _notificationRepository.getAdminNotificationsStream();
  }

  Stream<int> getUnreadCount() {
    return _notificationRepository.getAdminUnreadCountStream();
  }

  Future<void> markAsRead(String notificationId) async {
    await _notificationRepository.markAdminNotificationAsRead(notificationId);
  }

  Future<void> markAllAsRead() async {
    await _notificationRepository.markAllAdminNotificationsAsRead();
  }

  Future<void> deleteNotification(String notificationId) async {
    await _notificationRepository.deleteAdminNotification(notificationId);
  }
}
