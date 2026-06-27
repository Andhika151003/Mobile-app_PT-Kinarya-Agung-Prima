import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:ecommerce/features/notification/controllers/notif_admin_controller.dart';
import 'package:ecommerce/features/notification/models/notification_model.dart';
import 'package:ecommerce/features/notification/services/notification_service.dart';
import 'package:ecommerce/features/notification/services/push_notification_service.dart';

void main() {
  late FakeFirebaseFirestore mockFirestore;
  late NotificationAdminController adminController;
  late NotificationService notificationService;

  setUp(() {
    mockFirestore = FakeFirebaseFirestore();
    adminController = NotificationAdminController(firestore: mockFirestore);
    notificationService = NotificationService(firestore: mockFirestore);
  });

  group('NotificationModel Unit Tests', () {
    test('fromFirestore dengan data lengkap', () async {
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

    test('fromFirestore menggunakan nilai default jika field kosong', () async {
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

    test('toFirestore mengembalikan Map yang benar', () {
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

  group('NotificationAdminController - Controller Methods', () {
    test('getNotifications mengembalikan notifikasi terurut descending by timestamp', () async {
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

    test('getNotifications dengan type order', () async {
      await mockFirestore.collection('admin_notifications').doc('notif_order').set({
        'title': 'Pesanan Baru Masuk!',
        'message': 'Pesanan ORD-001 telah dibuat oleh Toko ABC.',
        'timestamp': Timestamp.now(),
        'isRead': false,
        'type': 'order',
        'relatedId': 'ORD-001',
      });

      final list = await adminController.getNotifications().first;

      expect(list.length, 1);
      expect(list[0].type, 'order');
      expect(list[0].title, 'Pesanan Baru Masuk!');
      expect(list[0].relatedId, 'ORD-001');
    });

    test('getNotifications dengan type complaint', () async {
      await mockFirestore.collection('admin_notifications').doc('notif_complaint').set({
        'title': 'Komplain Baru!',
        'message': 'Ada komplain baru untuk pesanan ORD-002: Barang Rusak.',
        'timestamp': Timestamp.now(),
        'isRead': false,
        'type': 'complaint',
        'relatedId': 'ORD-002',
      });

      final list = await adminController.getNotifications().first;

      expect(list.length, 1);
      expect(list[0].type, 'complaint');
      expect(list[0].title, 'Komplain Baru!');
      expect(list[0].relatedId, 'ORD-002');
    });

    test('getNotifications dengan type system', () async {
      await mockFirestore.collection('admin_notifications').doc('notif_system').set({
        'title': 'Sistem Update',
        'message': 'Aplikasi akan diperbarui pada pukul 02.00 WIB.',
        'timestamp': Timestamp.now(),
        'isRead': false,
        'type': 'system',
      });

      final list = await adminController.getNotifications().first;

      expect(list.length, 1);
      expect(list[0].type, 'system');
      expect(list[0].title, 'Sistem Update');
    });

    test('getUnreadCount mengembalikan jumlah notifikasi unread', () async {
      await mockFirestore.collection('admin_notifications').doc('notif_1').set({
        'isRead': false, 'timestamp': Timestamp.now(),
      });
      await mockFirestore.collection('admin_notifications').doc('notif_2').set({
        'isRead': true, 'timestamp': Timestamp.now(),
      });
      await mockFirestore.collection('admin_notifications').doc('notif_3').set({
        'isRead': false, 'timestamp': Timestamp.now(),
      });

      final count = await adminController.getUnreadCount().first;
      expect(count, 2);
    });

    test('markAsRead mengubah isRead notifikasi tertentu menjadi true', () async {
      await mockFirestore.collection('admin_notifications').doc('notif_target').set({
        'isRead': false,
        'timestamp': Timestamp.now(),
      });

      await adminController.markAsRead('notif_target');

      final doc = await mockFirestore.collection('admin_notifications').doc('notif_target').get();
      expect(doc.data()?['isRead'], true);
    });

    test('markAllAsRead mengubah semua notifikasi unread menjadi true', () async {
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

  group('NotificationService', () {
    test('addUserNotification membuat notifikasi di subcollection user dengan type order', () async {
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

    test('addUserNotification dengan type promo', () async {
      await notificationService.addUserNotification(
        userId: 'retailer_456',
        title: 'Promo Spesial Hari Ini!',
        message: 'Jangan lewatkan diskon 50%. Cek sekarang!',
        type: 'promo',
        relatedId: 'PROMO_001',
      );

      final query = await mockFirestore
          .collection('users')
          .doc('retailer_456')
          .collection('notifications')
          .get();

      expect(query.docs.length, 1);
      expect(query.docs[0].data()['type'], 'promo');
      expect(query.docs[0].data()['title'], 'Promo Spesial Hari Ini!');
    });

    test('addAdminNotification membuat notifikasi admin dengan type order (pesanan baru)', () async {
      await notificationService.addAdminNotification(
        title: 'Pesanan Baru Masuk!',
        message: 'Pesanan ORD-7766 telah dibuat oleh Toko ABC.',
        type: 'order',
        relatedId: 'ORD-7766',
      );

      final query = await mockFirestore.collection('admin_notifications').get();

      expect(query.docs.length, 1);
      final data = query.docs[0].data();
      expect(data['title'], 'Pesanan Baru Masuk!');
      expect(data['message'], contains('ORD-7766'));
      expect(data['isRead'], false);
      expect(data['type'], 'order');
      expect(data['relatedId'], 'ORD-7766');
    });

    test('addAdminNotification dengan type complaint (komplain baru)', () async {
      await notificationService.addAdminNotification(
        title: 'Komplain Baru!',
        message: 'Ada komplain baru untuk pesanan ORD-7788: Barang Rusak.',
        type: 'complaint',
        relatedId: 'ORD-7788',
      );

      final query = await mockFirestore.collection('admin_notifications').get();

      expect(query.docs.length, 1);
      expect(query.docs[0].data()['type'], 'complaint');
      expect(query.docs[0].data()['title'], 'Komplain Baru!');
    });

    test('addAdminNotification dengan type system', () async {
      await notificationService.addAdminNotification(
        title: 'Pemeliharaan Sistem',
        message: 'Sistem akan down pada pukul 02.00 - 04.00 WIB.',
        type: 'system',
      );

      final query = await mockFirestore.collection('admin_notifications').get();

      expect(query.docs.length, 1);
      expect(query.docs[0].data()['type'], 'system');
      expect(query.docs[0].data()['title'], 'Pemeliharaan Sistem');
    });
  });

  group('PushNotificationService Admin-related', () {
    late PushNotificationService pushNotificationService;

    setUp(() {
      pushNotificationService = PushNotificationService();
      pushNotificationService.setupMocks(firestore: mockFirestore);
    });

    test('sendNotificationToAdmin dengan type order (pesanan baru)', () async {
      await pushNotificationService.sendNotificationToAdmin(
        title: 'Pesanan Baru Masuk!',
        message: 'Pesanan ORD-001 telah dibuat.',
        type: 'order',
        relatedId: 'ORD-001',
      );

      final query = await mockFirestore.collection('admin_notifications').get();
      expect(query.docs.length, 1);
      final data = query.docs[0].data();
      expect(data['title'], 'Pesanan Baru Masuk!');
      expect(data['type'], 'order');
      expect(data['relatedId'], 'ORD-001');
    });

    test('sendNotificationToAdmin dengan type complaint', () async {
      await pushNotificationService.sendNotificationToAdmin(
        title: 'Komplain Baru!',
        message: 'Ada komplain baru: Barang Rusak.',
        type: 'complaint',
        relatedId: 'ORD-002',
      );

      final query = await mockFirestore.collection('admin_notifications').get();
      expect(query.docs.length, 1);
      expect(query.docs[0].data()['type'], 'complaint');
      expect(query.docs[0].data()['title'], 'Komplain Baru!');
    });

    test('sendNotificationToAdmin dengan type system', () async {
      await pushNotificationService.sendNotificationToAdmin(
        title: 'Update Sistem',
        message: 'Versi baru tersedia.',
        type: 'system',
      );

      final query = await mockFirestore.collection('admin_notifications').get();
      expect(query.docs.length, 1);
      expect(query.docs[0].data()['type'], 'system');
    });

    test('broadcastNotification mengirim notifikasi type promo ke semua user', () async {
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
      expect(q1.docs[0].data()['type'], 'promo');

      expect(q2.docs.length, 1);
      expect(q2.docs[0].data()['title'], 'Promo Akhir Tahun');
      expect(q2.docs[0].data()['type'], 'promo');
    });
  });
}
