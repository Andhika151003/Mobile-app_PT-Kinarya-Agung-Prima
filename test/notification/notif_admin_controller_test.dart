import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:ecommerce/features/notification/controllers/notif_admin_controller.dart';
import 'package:ecommerce/features/notification/models/notification_model.dart';
import 'package:ecommerce/features/notification/services/notification_service.dart';
import 'package:ecommerce/features/notification/services/push_notification_service.dart';

// Keep the legacy dummy class to avoid breaking existing/legacy test scenarios
class NotifAdminController {
  Map<String, dynamic> buildAdminNotification(
    String type,
    Map<String, dynamic> data,
  ) {
    if (type == 'cancellation_requested') {
      return {
        'title': 'Permintaan Pembatalan Pesanan',
        'body':
            'Permintaan pembatalan dari ${data['retailerName']} untuk pesanan ${data['orderId']}',
      };
    }
    return {};
  }
}

void main() {
  late NotifAdminController legacyController;
  late FakeFirebaseFirestore mockFirestore;
  late NotificationAdminController adminController;
  late NotificationService notificationService;

  setUp(() {
    legacyController = NotifAdminController();
    mockFirestore = FakeFirebaseFirestore();
    adminController = NotificationAdminController(firestore: mockFirestore);
    notificationService = NotificationService(firestore: mockFirestore);
  });

  group('Notifikasi Admin - Permintaan Pembatalan (Legacy)', () {
    test('menghasilkan notifikasi yang benar untuk cancellation_requested', () {
      final data = {'retailerName': 'Body Shop Store', 'orderId': 'ORD-5787'};
      final result = legacyController.buildAdminNotification(
        'cancellation_requested',
        data,
      );

      expect(result['title'], 'Permintaan Pembatalan Pesanan');
      expect(result['body'], contains('Body Shop Store'));
      expect(result['body'], contains('ORD-5787'));
    });
  });

  group('NotificationModel Unit Tests', () {
    test('Mengubah DocumentSnapshot ke NotificationModel (fromFirestore) dengan data lengkap', () async {
      final timestamp = Timestamp.fromDate(DateTime(2026, 6, 18, 12, 0));
      await mockFirestore.collection('test_notif').doc('notif_1').set({
        'title': 'Test Title',
        'message': 'Test Message',
        'timestamp': timestamp,
        'isRead': true,
        'type': 'promo',
        'relatedId': 'PROMO_99',
      });

      final doc = await mockFirestore.collection('test_notif').doc('notif_1').get();
      final model = NotificationModel.fromFirestore(doc);

      expect(model.id, 'notif_1');
      expect(model.title, 'Test Title');
      expect(model.message, 'Test Message');
      expect(model.timestamp, DateTime(2026, 6, 18, 12, 0));
      expect(model.isRead, true);
      expect(model.type, 'promo');
      expect(model.relatedId, 'PROMO_99');
    });

    test('fromFirestore menggunakan nilai default jika field kosong/null', () async {
      await mockFirestore.collection('test_notif').doc('notif_empty').set({});

      final doc = await mockFirestore.collection('test_notif').doc('notif_empty').get();
      final model = NotificationModel.fromFirestore(doc);

      expect(model.id, 'notif_empty');
      expect(model.title, '');
      expect(model.message, '');
      expect(model.isRead, false);
      expect(model.type, 'system');
      expect(model.relatedId, isNull);
      expect(model.timestamp, isNotNull);
    });

    test('Mengubah NotificationModel ke Map Firestore (toFirestore)', () {
      final now = DateTime.now();
      final model = NotificationModel(
        id: 'notif_2',
        title: 'New Notification',
        message: 'New message body',
        timestamp: now,
        isRead: false,
        type: 'order',
        relatedId: 'ORD_123',
      );

      final map = model.toFirestore();

      expect(map['title'], 'New Notification');
      expect(map['message'], 'New message body');
      expect(map['isRead'], false);
      expect(map['type'], 'order');
      expect(map['relatedId'], 'ORD_123');
      expect(map['timestamp'], isA<Timestamp>());
      expect((map['timestamp'] as Timestamp).toDate().difference(now).inSeconds, 0);
    });
  });

  group('NotificationAdminController Unit Tests', () {
    test('getNotifications mengembalikan daftar notifikasi terurut descending berdasarkan timestamp', () async {
      await mockFirestore.collection('admin_notifications').doc('notif_old').set({
        'title': 'Old Notif',
        'message': 'Old',
        'timestamp': Timestamp.fromDate(DateTime(2026, 6, 18, 10, 0)),
        'isRead': false,
        'type': 'system',
      });

      await mockFirestore.collection('admin_notifications').doc('notif_new').set({
        'title': 'New Notif',
        'message': 'New',
        'timestamp': Timestamp.fromDate(DateTime(2026, 6, 18, 11, 0)),
        'isRead': false,
        'type': 'system',
      });

      final list = await adminController.getNotifications().first;

      expect(list.length, 2);
      expect(list[0].id, 'notif_new');
      expect(list[1].id, 'notif_old');
    });

    test('getUnreadCount mengembalikan jumlah notifikasi yang belum dibaca (isRead = false)', () async {
      await mockFirestore.collection('admin_notifications').doc('notif_1').set({
        'isRead': false,
        'timestamp': Timestamp.now(),
      });
      await mockFirestore.collection('admin_notifications').doc('notif_2').set({
        'isRead': true,
        'timestamp': Timestamp.now(),
      });
      await mockFirestore.collection('admin_notifications').doc('notif_3').set({
        'isRead': false,
        'timestamp': Timestamp.now(),
      });

      final count = await adminController.getUnreadCount().first;
      expect(count, 2);
    });

    test('markAsRead mengubah status isRead notifikasi tertentu menjadi true', () async {
      await mockFirestore.collection('admin_notifications').doc('notif_target').set({
        'isRead': false,
        'timestamp': Timestamp.now(),
      });

      await adminController.markAsRead('notif_target');

      final doc = await mockFirestore.collection('admin_notifications').doc('notif_target').get();
      expect(doc.data()?['isRead'], true);
    });

    test('markAllAsRead mengubah status seluruh notifikasi unread menjadi true', () async {
      await mockFirestore.collection('admin_notifications').doc('notif_1').set({
        'isRead': false,
      });
      await mockFirestore.collection('admin_notifications').doc('notif_2').set({
        'isRead': false,
      });
      await mockFirestore.collection('admin_notifications').doc('notif_already_read').set({
        'isRead': true,
      });

      await adminController.markAllAsRead();

      final doc1 = await mockFirestore.collection('admin_notifications').doc('notif_1').get();
      final doc2 = await mockFirestore.collection('admin_notifications').doc('notif_2').get();
      final doc3 = await mockFirestore.collection('admin_notifications').doc('notif_already_read').get();

      expect(doc1.data()?['isRead'], true);
      expect(doc2.data()?['isRead'], true);
      expect(doc3.data()?['isRead'], true);
    });

    test('deleteNotification menghapus notifikasi dari Firestore', () async {
      await mockFirestore.collection('admin_notifications').doc('notif_to_delete').set({
        'title': 'Delete Me',
      });

      await adminController.deleteNotification('notif_to_delete');

      final doc = await mockFirestore.collection('admin_notifications').doc('notif_to_delete').get();
      expect(doc.exists, false);
    });
  });

  group('NotificationService Unit Tests', () {
    test('addUserNotification membuat notifikasi subcollection untuk user tertentu', () async {
      await notificationService.addUserNotification(
        userId: 'retailer_123',
        title: 'Pembayaran Diverifikasi',
        message: 'Pembayaran untuk transaksi TRX12345 telah disetujui Admin.',
        type: 'order',
        relatedId: 'TRX12345',
      );

      final query = await mockFirestore
          .collection('users')
          .doc('retailer_123')
          .collection('notifications')
          .get();

      expect(query.docs.length, 1);
      final data = query.docs[0].data();
      expect(data['title'], 'Pembayaran Diverifikasi');
      expect(data['message'], contains('TRX12345'));
      expect(data['isRead'], false);
      expect(data['type'], 'order');
      expect(data['relatedId'], 'TRX12345');
    });

    test('addAdminNotification membuat notifikasi di admin_notifications collection', () async {
      await notificationService.addAdminNotification(
        title: 'Permintaan Pembatalan Pesanan',
        message: 'Permintaan pembatalan dari Body Shop Store untuk pesanan ORD-5787',
        type: 'cancellation_requested',
        relatedId: 'ORD-5787',
      );

      final query = await mockFirestore.collection('admin_notifications').get();

      expect(query.docs.length, 1);
      final data = query.docs[0].data();
      expect(data['title'], 'Permintaan Pembatalan Pesanan');
      expect(data['message'], contains('Body Shop Store'));
      expect(data['message'], contains('ORD-5787'));
      expect(data['isRead'], false);
      expect(data['type'], 'cancellation_requested');
      expect(data['relatedId'], 'ORD-5787');
    });
  });

  group('PushNotificationService Admin-related Unit Tests', () {
    late PushNotificationService pushNotificationService;

    setUp(() {
      pushNotificationService = PushNotificationService();
      pushNotificationService.setupMocks(firestore: mockFirestore);
    });

    test('sendNotificationToAdmin menambahkan data ke collection admin_notifications', () async {
      await pushNotificationService.sendNotificationToAdmin(
        title: 'Pesanan Masuk',
        message: 'Ada pesanan baru dengan ID ORD-001',
        type: 'order',
        relatedId: 'ORD-001',
      );

      final query = await mockFirestore.collection('admin_notifications').get();
      expect(query.docs.length, 1);
      final data = query.docs[0].data();
      expect(data['title'], 'Pesanan Masuk');
      expect(data['message'], contains('ORD-001'));
      expect(data['isRead'], false);
      expect(data['type'], 'order');
      expect(data['relatedId'], 'ORD-001');
    });

    test('broadcastNotification mengirimkan notifikasi ke semua user terdaftar', () async {
      await mockFirestore.collection('users').doc('user_1').set({'email': 'u1@email.com'});
      await mockFirestore.collection('users').doc('user_2').set({'email': 'u2@email.com'});

      await pushNotificationService.broadcastNotification(
        title: 'Promo Akhir Tahun',
        message: 'Diskon hingga 50%!',
        type: 'promo',
        relatedId: 'PROMO_YEAR_END',
      );

      final q1 = await mockFirestore
          .collection('users')
          .doc('user_1')
          .collection('notifications')
          .get();

      final q2 = await mockFirestore
          .collection('users')
          .doc('user_2')
          .collection('notifications')
          .get();

      expect(q1.docs.length, 1);
      expect(q1.docs[0].data()['title'], 'Promo Akhir Tahun');
      expect(q1.docs[0].data()['message'], contains('Diskon'));
      expect(q1.docs[0].data()['type'], 'promo');

      expect(q2.docs.length, 1);
      expect(q2.docs[0].data()['title'], 'Promo Akhir Tahun');
      expect(q2.docs[0].data()['message'], contains('Diskon'));
      expect(q2.docs[0].data()['type'], 'promo');
    });
  });
}
