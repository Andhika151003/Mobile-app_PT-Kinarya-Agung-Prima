import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ecommerce/features/notification/controllers/notif_user_controller.dart';
import 'package:ecommerce/features/notification/models/notification_model.dart';
import 'package:ecommerce/features/notification/services/push_notification_service.dart';

class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

void main() {
  late FakeFirebaseFirestore mockFirestore;
  late MockFirebaseAuth mockAuth;
  late NotificationUserController userController;
  late MockFirebaseMessaging mockFcm;
  late PushNotificationService pushNotificationService;

  setUpAll(() {
    registerFallbackValue(const Duration(seconds: 5));
  });

  setUp(() {
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

  group('NotificationUserController - Unauthenticated State', () {
    test('getNotifications mengembalikan stream kosong jika user null', () async {
      final list = await userController.getNotifications().first;
      expect(list, isEmpty);
    });

    test('getUnreadCount mengembalikan 0 jika user null', () async {
      final count = await userController.getUnreadCount().first;
      expect(count, 0);
    });

    test('markAsRead return tanpa error jika user null', () async {
      await userController.markAsRead('some_notif_id');
    });

    test('markAllAsRead return tanpa error jika user null', () async {
      await userController.markAllAsRead();
    });

    test('deleteNotification return tanpa error jika user null', () async {
      await userController.deleteNotification('some_notif_id');
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

    test('getNotifications mengembalikan notifikasi user terurut descending', () async {
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

    test('getNotifications dengan type order (pembayaran, pengiriman, pembatalan)', () async {
      final notifPath = mockFirestore.collection('users').doc(uid).collection('notifications');

      await notifPath.doc('n_order').set({
        'title': 'Pembayaran Diterima',
        'message': 'Pembayaran untuk pesanan ORD-123 telah kami konfirmasi.',
        'timestamp': Timestamp.now(),
        'isRead': false,
        'type': 'order',
        'relatedId': 'ORD-123',
      });

      final list = await userController.getNotifications().first;
      expect(list.length, 1);
      expect(list[0].type, 'order');
      expect(list[0].title, 'Pembayaran Diterima');
      expect(list[0].relatedId, 'ORD-123');
    });

    test('getNotifications dengan type promo', () async {
      final notifPath = mockFirestore.collection('users').doc(uid).collection('notifications');

      await notifPath.doc('n_promo').set({
        'title': 'Promo Spesial Hari Ini!',
        'message': 'Diskon hingga 50% untuk semua produk.',
        'timestamp': Timestamp.now(),
        'isRead': false,
        'type': 'promo',
        'relatedId': 'PROMO_001',
      });

      final list = await userController.getNotifications().first;
      expect(list.length, 1);
      expect(list[0].type, 'promo');
      expect(list[0].title, 'Promo Spesial Hari Ini!');
      expect(list[0].relatedId, 'PROMO_001');
    });

    test('getNotifications dengan type complaint', () async {
      final notifPath = mockFirestore.collection('users').doc(uid).collection('notifications');

      await notifPath.doc('n_complaint').set({
        'title': 'Komplain Diproses',
        'message': 'Komplain Anda untuk pesanan ORD-456 sedang diproses.',
        'timestamp': Timestamp.now(),
        'isRead': false,
        'type': 'complaint',
        'relatedId': 'ORD-456',
      });

      final list = await userController.getNotifications().first;
      expect(list.length, 1);
      expect(list[0].type, 'complaint');
      expect(list[0].title, 'Komplain Diproses');
      expect(list[0].relatedId, 'ORD-456');
    });

    test('getUnreadCount mengembalikan jumlah notifikasi unread', () async {
      final notifPath = mockFirestore.collection('users').doc(uid).collection('notifications');

      await notifPath.doc('n_1').set({'isRead': false, 'timestamp': Timestamp.now()});
      await notifPath.doc('n_2').set({'isRead': true, 'timestamp': Timestamp.now()});
      await notifPath.doc('n_3').set({'isRead': false, 'timestamp': Timestamp.now()});

      final count = await userController.getUnreadCount().first;
      expect(count, 2);
    });

    test('markAsRead mengubah isRead notifikasi tertentu menjadi true', () async {
      final notifPath = mockFirestore.collection('users').doc(uid).collection('notifications');
      await notifPath.doc('n_target').set({'isRead': false, 'timestamp': Timestamp.now()});

      await userController.markAsRead('n_target');

      final doc = await notifPath.doc('n_target').get();
      expect(doc.data()?['isRead'], true);
    });

    test('markAllAsRead mengubah semua notifikasi unread menjadi true', () async {
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

  group('PushNotificationService User-related', () {
    const uid = 'retailer_456';
    late MockUser mockUser;

    test('saveTokenToFirestore tidak melakukan apa pun jika user belum login', () async {
      mockAuth = MockFirebaseAuth();
      pushNotificationService.setupMocks(firestore: mockFirestore, auth: mockAuth, fcm: mockFcm);

      await pushNotificationService.saveTokenToFirestore();

      final query = await mockFirestore.collection('users').get();
      expect(query.docs, isEmpty);
    });

    test('saveTokenToFirestore menyimpan FCM token ke dokumen user saat login', () async {
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

    test('clearToken menghapus field fcmToken dari dokumen user', () async {
      mockUser = MockUser(uid: uid, email: 'retailer@example.com');
      mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
      pushNotificationService.setupMocks(firestore: mockFirestore, auth: mockAuth, fcm: mockFcm);

      await mockFirestore.collection('users').doc(uid).set({'fcmToken': 'existing_token'});

      await pushNotificationService.clearToken();

      final doc = await mockFirestore.collection('users').doc(uid).get();
      expect(doc.data()?.containsKey('fcmToken'), false);
    });

    test('sendNotificationToUser dengan type order (pembayaran diterima)', () async {
      await pushNotificationService.sendNotificationToUser(
        userId: 'user_target',
        title: 'Pembayaran Diterima',
        message: 'Pembayaran untuk pesanan ORD-123 telah dikonfirmasi.',
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
      expect(data['title'], 'Pembayaran Diterima');
      expect(data['type'], 'order');
      expect(data['relatedId'], 'ORD-123');
    });

    test('sendNotificationToUser dengan type promo', () async {
      await pushNotificationService.sendNotificationToUser(
        userId: 'user_target',
        title: 'Promo Akhir Pekan',
        message: 'Diskon 30% untuk semua item!',
        type: 'promo',
        relatedId: 'PROMO_WEEKEND',
      );

      final query = await mockFirestore
          .collection('users')
          .doc('user_target')
          .collection('notifications')
          .get();

      expect(query.docs.length, 1);
      expect(query.docs[0].data()['type'], 'promo');
      expect(query.docs[0].data()['title'], 'Promo Akhir Pekan');
    });

    test('sendNotificationToUser dengan type complaint', () async {
      await pushNotificationService.sendNotificationToUser(
        userId: 'user_target',
        title: 'Komplain Diproses',
        message: 'Komplain Anda sedang ditinjau admin.',
        type: 'complaint',
        relatedId: 'ORD-456',
      );

      final query = await mockFirestore
          .collection('users')
          .doc('user_target')
          .collection('notifications')
          .get();

      expect(query.docs.length, 1);
      expect(query.docs[0].data()['type'], 'complaint');
      expect(query.docs[0].data()['title'], 'Komplain Diproses');
    });
  });
}
