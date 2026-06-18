import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ecommerce/features/notification/controllers/notif_user_controller.dart';
import 'package:ecommerce/features/notification/models/notification_model.dart';
import 'package:ecommerce/features/notification/services/push_notification_service.dart';

// Keep the legacy dummy class to avoid breaking existing/legacy test scenarios
class NotifUserController {
  Map<String, String> buildUserNotification(
    String type,
    Map<String, String> data,
  ) {
    switch (type) {
      case 'transaction_approved':
        return {
          'title': 'Pembayaran Diverifikasi',
          'body':
              'Pembayaran untuk transaksi ${data['transactionId']} telah disetujui Admin.',
        };
      case 'delivery_approved':
        return {
          'title': 'Pengiriman Disetujui',
          'body':
              'Pengiriman untuk pesanan ${data['orderId']} sedang dalam proses pengiriman.',
        };
      case 'delivery_rejected':
        return {
          'title': 'Pengiriman Ditolak',
          'body':
              'Pengiriman untuk pesanan ${data['orderId']} ditolak. Alasan: ${data['reason']}',
        };
      case 'cancellation_accepted':
        return {
          'title': 'Pembatalan Disetujui',
          'body': 'Permintaan pembatalan telah disetujui Admin.',
        };
      case 'cancellation_rejected':
        return {
          'title': 'Pembatalan Ditolak',
          'body': 'Pesanan tetap diproses.',
        };
      default:
        return {'title': '', 'body': ''};
    }
  }
}

class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

void main() {
  late NotifUserController legacyController;
  late FakeFirebaseFirestore mockFirestore;
  late MockFirebaseAuth mockAuth;
  late NotificationUserController userController;
  late MockFirebaseMessaging mockFcm;
  late PushNotificationService pushNotificationService;

  setUpAll(() {
    registerFallbackValue(const Duration(seconds: 5));
  });

  setUp(() {
    legacyController = NotifUserController();
    mockFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    userController = NotificationUserController(firestore: mockFirestore, auth: mockAuth);
    mockFcm = MockFirebaseMessaging();
    pushNotificationService = PushNotificationService();
    pushNotificationService.setupMocks(
      firestore: mockFirestore,
      auth: mockAuth,
      fcm: mockFcm,
    );
  });

  group('TC-04: Approve Transaksi (Legacy)', () {
    test('Notifikasi ke user: pembayaran diverifikasi', () {
      final data = {'transactionId': 'TRX25040001'};
      final result = legacyController.buildUserNotification(
        'transaction_approved',
        data,
      );

      expect(result['title'], 'Pembayaran Diverifikasi');
      expect(result['body'], contains('TRX25040001'));
      expect(result['body'], contains('disetujui Admin'));
    });
  });

  group('TC-06: Approve Delivery (Legacy)', () {
    test('Notifikasi pengiriman disetujui', () {
      final data = {'orderId': 'ORD-5785'};
      final result = legacyController.buildUserNotification(
        'delivery_approved',
        data,
      );

      expect(result['title'], 'Pengiriman Disetujui');
      expect(result['body'], contains('ORD-5785'));
      expect(
        result['body'],
        contains('sedang dalam proses pengiriman'),
      );
    });
  });

  group('TC-07: Reject Delivery (Legacy)', () {
    test('Notifikasi penolakan dengan alasan', () {
      final data = {'orderId': 'ORD-5786', 'reason': 'Stok tidak tersedia'};
      final result = legacyController.buildUserNotification(
        'delivery_rejected',
        data,
      );

      expect(result['title'], 'Pengiriman Ditolak');
      expect(result['body'], contains('ORD-5786'));
      expect(result['body'], contains('Stok tidak tersedia'));
    });
  });

  group('Accept & Reject Cancellation (Legacy)', () {
    test('Accept cancellation', () {
      final data = {'orderId': 'ORD-5787'};
      final result = legacyController.buildUserNotification(
        'cancellation_accepted',
        data,
      );

      expect(result['title'], 'Pembatalan Disetujui');
      expect(result['body'], contains('telah disetujui Admin'));
    });

    test('Reject cancellation', () {
      final data = {'orderId': 'ORD-5789'};
      final result = legacyController.buildUserNotification(
        'cancellation_rejected',
        data,
      );

      expect(result['title'], 'Pembatalan Ditolak');
      expect(result['body'], contains('Pesanan tetap diproses'));
    });
  });

  group('NotificationUserController - Unauthenticated State', () {
    test('getNotifications mengembalikan stream kosong jika user belum login', () async {
      // Mock auth currentUser is null
      final list = await userController.getNotifications().first;
      expect(list, isEmpty);
    });

    test('getUnreadCount mengembalikan 0 jika user belum login', () async {
      final count = await userController.getUnreadCount().first;
      expect(count, 0);
    });

    test('markAsRead return tanpa error jika user belum login', () async {
      await userController.markAsRead('some_notif_id');
      // No exception thrown
    });

    test('markAllAsRead return tanpa error jika user belum login', () async {
      await userController.markAllAsRead();
      // No exception thrown
    });

    test('deleteNotification return tanpa error jika user belum login', () async {
      await userController.deleteNotification('some_notif_id');
      // No exception thrown
    });
  });

  group('NotificationUserController - Authenticated State', () {
    const uid = 'user_123';
    late MockUser mockUser;

    setUp(() async {
      mockUser = MockUser(uid: uid, email: 'user@example.com');
      mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
      userController = NotificationUserController(firestore: mockFirestore, auth: mockAuth);
    });

    test('getNotifications mengembalikan notifikasi milik user terurut descending', () async {
      final notifPath = mockFirestore.collection('users').doc(uid).collection('notifications');

      await notifPath.doc('n_old').set({
        'title': 'Old Alert',
        'message': 'Yesterday',
        'timestamp': Timestamp.fromDate(DateTime(2026, 6, 17, 12, 0)),
        'isRead': false,
        'type': 'system',
      });

      await notifPath.doc('n_new').set({
        'title': 'New Alert',
        'message': 'Today',
        'timestamp': Timestamp.fromDate(DateTime(2026, 6, 18, 12, 0)),
        'isRead': false,
        'type': 'system',
      });

      final list = await userController.getNotifications().first;

      expect(list.length, 2);
      expect(list[0].id, 'n_new');
      expect(list[1].id, 'n_old');
    });

    test('getUnreadCount mengembalikan jumlah notifikasi unread milik user', () async {
      final notifPath = mockFirestore.collection('users').doc(uid).collection('notifications');

      await notifPath.doc('n_1').set({'isRead': false, 'timestamp': Timestamp.now()});
      await notifPath.doc('n_2').set({'isRead': true, 'timestamp': Timestamp.now()});
      await notifPath.doc('n_3').set({'isRead': false, 'timestamp': Timestamp.now()});

      final count = await userController.getUnreadCount().first;
      expect(count, 2);
    });

    test('markAsRead mengubah status isRead notifikasi user tertentu menjadi true', () async {
      final notifPath = mockFirestore.collection('users').doc(uid).collection('notifications');
      await notifPath.doc('n_target').set({'isRead': false, 'timestamp': Timestamp.now()});

      await userController.markAsRead('n_target');

      final doc = await notifPath.doc('n_target').get();
      expect(doc.data()?['isRead'], true);
    });

    test('markAllAsRead mengubah seluruh status isRead notifikasi user menjadi true', () async {
      final notifPath = mockFirestore.collection('users').doc(uid).collection('notifications');

      await notifPath.doc('n_1').set({'isRead': false});
      await notifPath.doc('n_2').set({'isRead': false});
      await notifPath.doc('n_already_read').set({'isRead': true});

      await userController.markAllAsRead();

      final doc1 = await notifPath.doc('n_1').get();
      final doc2 = await notifPath.doc('n_2').get();
      final doc3 = await notifPath.doc('n_already_read').get();

      expect(doc1.data()?['isRead'], true);
      expect(doc2.data()?['isRead'], true);
      expect(doc3.data()?['isRead'], true);
    });

    test('deleteNotification menghapus notifikasi dari subcollection user', () async {
      final notifPath = mockFirestore.collection('users').doc(uid).collection('notifications');
      await notifPath.doc('n_delete').set({'title': 'Delete Me'});

      await userController.deleteNotification('n_delete');

      final doc = await notifPath.doc('n_delete').get();
      expect(doc.exists, false);
    });
  });

  group('PushNotificationService User-related Unit Tests', () {
    const uid = 'retailer_456';
    late MockUser mockUser;

    test('saveTokenToFirestore tidak melakukan apa pun jika user belum login', () async {
      mockAuth = MockFirebaseAuth(); // not logged in
      pushNotificationService.setupMocks(firestore: mockFirestore, auth: mockAuth, fcm: mockFcm);

      await pushNotificationService.saveTokenToFirestore();

      // Ensure no users were added or edited
      final query = await mockFirestore.collection('users').get();
      expect(query.docs, isEmpty);
    });

    test('saveTokenToFirestore menyimpan token FCM ke dokumen user saat terautentikasi', () async {
      mockUser = MockUser(uid: uid, email: 'retailer@example.com');
      mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
      pushNotificationService.setupMocks(firestore: mockFirestore, auth: mockAuth, fcm: mockFcm);

      when(() => mockFcm.getToken()).thenAnswer((_) async => 'fcm_token_xyz');

      await pushNotificationService.saveTokenToFirestore();

      final doc = await mockFirestore.collection('users').doc(uid).get();
      expect(doc.exists, true);
      expect(doc.data()?['fcmToken'], 'fcm_token_xyz');
      expect(doc.data()?['lastTokenUpdate'], isA<Timestamp>());
    });

    test('clearToken menghapus field fcmToken dari dokumen user saat logout', () async {
      mockUser = MockUser(uid: uid, email: 'retailer@example.com');
      mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
      pushNotificationService.setupMocks(firestore: mockFirestore, auth: mockAuth, fcm: mockFcm);

      // Seed token first
      await mockFirestore.collection('users').doc(uid).set({'fcmToken': 'existing_token'});

      await pushNotificationService.clearToken();

      // Note: clearToken executes update with FieldValue.delete()
      final doc = await mockFirestore.collection('users').doc(uid).get();
      expect(doc.data()?.containsKey('fcmToken'), false);
    });

    test('sendNotificationToUser menambahkan dokumen ke subcollection notifications user', () async {
      await pushNotificationService.sendNotificationToUser(
        userId: 'user_target',
        title: 'Pesanan Terkirim',
        message: 'Pesanan Anda ORD-123 sedang dikirim',
        type: 'order',
        relatedId: 'ORD-123',
      );

      final query = await mockFirestore
          .collection('users')
          .doc('user_target')
          .collection('notifications')
          .get();

      expect(query.docs.length, 1);
      final data = query.docs[0].data();
      expect(data['title'], 'Pesanan Terkirim');
      expect(data['message'], contains('ORD-123'));
      expect(data['isRead'], false);
      expect(data['type'], 'order');
      expect(data['relatedId'], 'ORD-123');
    });
  });
}
