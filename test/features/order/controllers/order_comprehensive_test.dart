import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:ecommerce/features/order/controllers/order_user_controller.dart';
import 'package:ecommerce/features/order/controllers/order_admin_controller.dart';
import 'package:ecommerce/features/order/controllers/order_cs_controller.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ecommerce/features/notification/services/push_notification_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MockPushNotificationService extends Mock implements PushNotificationService {}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late OrderUserController userController;
  late OrderAdminController adminController;
  late OrderCsController csController;
  late MockPushNotificationService mockPushNotificationService;

  setUpAll(() {
    try {
      dotenv.loadFromString(envString: 'FCM_SERVER_KEY=dummy\nBACKEND_URL=mock');
    } catch (_) {
      // Ignore if not available
    }
  });

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockPushNotificationService = MockPushNotificationService();

    // Mock notification service
    when(() => mockPushNotificationService.sendNotificationToUser(
          userId: any(named: 'userId'),
          title: any(named: 'title'),
          message: any(named: 'message'),
          type: any(named: 'type'),
          relatedId: any(named: 'relatedId'),
        )).thenAnswer((_) async => true);

    when(() => mockPushNotificationService.sendNotificationToAdmin(
          title: any(named: 'title'),
          message: any(named: 'message'),
          type: any(named: 'type'),
          relatedId: any(named: 'relatedId'),
        )).thenAnswer((_) async => true);

    userController = OrderUserController(
      firestore: fakeFirestore,
      pushNotificationService: mockPushNotificationService,
      backendUrl: 'https://mock.url', // Provide backendUrl to avoid DotEnv usage
    );

    adminController = OrderAdminController(
      firestore: fakeFirestore,
      pushNotificationService: mockPushNotificationService,
    );

    csController = OrderCsController(
      firestore: fakeFirestore,
    );
  });

  group('Unit Test: Modul Pesanan (Order) - TC-96 s/d TC-107', () {
    
    test('TC-96: Ritel melihat daftar pesanan yang dia order', () async {
      await fakeFirestore.collection('orders').doc('ORD-001').set({
        'orderId': 'ORD-001',
        'userId': 'retailer_1',
        'status': 'Ordered',
        'createdAt': Timestamp.now(),
      });
      await fakeFirestore.collection('orders').doc('ORD-002').set({
        'orderId': 'ORD-002',
        'userId': 'retailer_2',
        'status': 'Ordered',
        'createdAt': Timestamp.now(),
      });

      final stream = userController.getUserOrdersStream('retailer_1');
      final snapshot = await stream.first;

      expect(snapshot.docs.length, 1);
      expect(snapshot.docs[0]['orderId'], 'ORD-001');
    });

    test('TC-97: Ritel melihat detail pesanan', () async {
      await fakeFirestore.collection('orders').doc('ORD-DETAIL').set({
        'orderId': 'ORD-DETAIL',
        'userId': 'retailer_1',
        'fullName': 'Toko Berkah',
        'total': 500000,
      });

      final detail = await userController.getOrderById('ORD-DETAIL');
      expect(detail, isNotNull);
      expect(detail!['fullName'], 'Toko Berkah');
    });

    test('TC-98: Validasi pencarian pesanan dengan data yang tidak valid (Empty State)', () {
      final allOrders = [
        {'orderId': 'ORD-1', 'fullName': 'Retailer A'},
        {'orderId': 'ORD-2', 'fullName': 'Retailer B'},
      ];
      
      final results = adminController.filterAndSearchOrders(allOrders, 'All', 'NonExistentOrder');
      expect(results, isEmpty);
    });

    test('TC-100: Admin melihat seluruh daftar pesanan dari berbagai ritel', () async {
      await fakeFirestore.collection('orders').doc('ORD-1').set({
        'userId': 'R1',
        'createdAt': Timestamp.now(),
      });
      await fakeFirestore.collection('orders').doc('ORD-2').set({
        'userId': 'R2',
        'createdAt': Timestamp.now(),
      });

      final allOrders = await adminController.getAllOrdersAdmin();
      expect(allOrders.length, 2);
    });

    test('TC-101: Admin memperbarui seluruh status pesanan (Ordered, Paid, Shipped, Delivered, Cancelled, Expired)', () async {
      final statusesToTest = ['Ordered', 'Paid', 'Shipped', 'Delivered', 'Cancelled', 'Expired'];

      for (var targetStatus in statusesToTest) {
        final orderId = 'ORD-UPDATE-$targetStatus';
        await fakeFirestore.collection('orders').doc(orderId).set({
          'orderId': orderId,
          'status': 'Ordered',
          'userId': 'retailer_1',
          'statsRecorded': false,
        });

        await adminController.updateOrderStatus(orderId, targetStatus);

        final updatedDoc = await fakeFirestore.collection('orders').doc(orderId).get();
        expect(updatedDoc.data()!['status'], targetStatus);
      }
    });

    test('TC-102: Admin membatalkan pesanan secara manual', () async {
      await fakeFirestore.collection('orders').doc('ORD-CANCEL').set({
        'orderId': 'ORD-CANCEL',
        'status': 'Ordered',
        'userId': 'retailer_1',
        'items': [],
        'statsRecorded': false,
      });

      await adminController.cancelOrder('ORD-CANCEL');

      final updatedDoc = await fakeFirestore.collection('orders').doc('ORD-CANCEL').get();
      expect(updatedDoc.data()!['status'], 'Cancelled');
    });

    test('TC-103: Customer Support (CS) melihat detail pesanan untuk memvalidasi keluhan', () async {
      await fakeFirestore.collection('orders').doc('ORD-CS').set({
        'orderId': 'ORD-CS',
        'status': 'Delivered',
      });

      final order = await csController.getOrderById('ORD-CS');
      expect(order, isNotNull);
      expect(order!.orderId, 'ORD-CS');
    });

    test('TC-104: Ritel mengajukan pembatalan (cancel) pesanan berstatus Ordered', () async {
      await fakeFirestore.collection('orders').doc('ORD-REQ-ORDERED').set({
        'orderId': 'ORD-REQ-ORDERED',
        'status': 'Ordered',
        'userId': 'retailer_1',
      });

      final result = await userController.requestCancellation('ORD-REQ-ORDERED', 'Salah memesan produk');
      expect(result, isTrue);

      final doc = await fakeFirestore.collection('orders').doc('ORD-REQ-ORDERED').get();
      expect(doc.data()?['cancellationReason'], 'Salah memesan produk');
      expect(doc.data()?['cancellationStatus'], 'Requested');
    });

    test('TC-105: Ritel mengajukan pembatalan (cancel) pesanan berstatus Paid', () async {
      await fakeFirestore.collection('orders').doc('ORD-REQ-PAID').set({
        'orderId': 'ORD-REQ-PAID',
        'status': 'Paid',
        'userId': 'retailer_1',
      });

      final result = await userController.requestCancellation('ORD-REQ-PAID', 'Menginginkan pergantian alamat');
      expect(result, isTrue);

      final doc = await fakeFirestore.collection('orders').doc('ORD-REQ-PAID').get();
      expect(doc.data()?['cancellationReason'], 'Menginginkan pergantian alamat');
      expect(doc.data()?['cancellationStatus'], 'Requested');
    });

    test('TC-106: Admin menerima (approve) permintaan cancel dari ritel', () async {
      await fakeFirestore.collection('orders').doc('ORD-APP-CANCEL').set({
        'orderId': 'ORD-APP-CANCEL',
        'status': 'Ordered',
        'userId': 'retailer_1',
        'cancellationStatus': 'Requested',
        'items': [],
        'statsRecorded': false,
      });

      await adminController.cancelOrder('ORD-APP-CANCEL', cancellationStatus: 'Approved');

      final doc = await fakeFirestore.collection('orders').doc('ORD-APP-CANCEL').get();
      expect(doc.data()?['status'], 'Cancelled');
      expect(doc.data()?['cancellationStatus'], 'Approved');
    });

    test('TC-107: Admin menolak permintaan cancel dari ritel', () async {
      await fakeFirestore.collection('orders').doc('ORD-REJ-CANCEL').set({
        'orderId': 'ORD-REJ-CANCEL',
        'status': 'Ordered',
        'userId': 'retailer_1',
        'cancellationStatus': 'Requested',
      });

      await adminController.rejectCancellation('ORD-REJ-CANCEL');

      final doc = await fakeFirestore.collection('orders').doc('ORD-REJ-CANCEL').get();
      expect(doc.data()?['cancellationStatus'], 'Rejected');
    });
  });
}
