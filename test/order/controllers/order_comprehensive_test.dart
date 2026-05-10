import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:ecommerce/features/order/controllers/order_user_controller.dart';
import 'package:ecommerce/features/order/controllers/order_admin_controller.dart';
import 'package:ecommerce/features/order/controllers/order_cs_controller.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ecommerce/features/notification/services/push_notification_service.dart';

class MockPushNotificationService extends Mock implements PushNotificationService {}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late OrderUserController userController;
  late OrderAdminController adminController;
  late OrderCsController csController;
  late MockPushNotificationService mockPushNotificationService;

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

  group('Comprehensive Unit Test: Modul Pesanan (Order)', () {
    
    test('14. Ritel melihat daftar pesanan miliknya', () async {
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

    test('15. Ritel melihat detail pesanan', () async {
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

    test('16. Validasi pencarian pesanan (Empty State jika tidak ketemu)', () {
      final allOrders = [
        {'orderId': 'ORD-1', 'fullName': 'Retailer A'},
        {'orderId': 'ORD-2', 'fullName': 'Retailer B'},
      ];
      
      final results = adminController.filterAndSearchOrders(allOrders, 'All', 'NonExistentOrder');
      expect(results, isEmpty);
    });

    test('18. Admin melihat seluruh daftar pesanan', () async {
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

    test('19. Admin memperbarui status pesanan Paid -> Shipped', () async {
      await fakeFirestore.collection('orders').doc('ORD-SHIP').set({
        'orderId': 'ORD-SHIP',
        'status': 'Paid',
        'userId': 'retailer_1',
        'statsRecorded': true,
      });

      await adminController.updateOrderStatus('ORD-SHIP', 'Shipped');

      final updatedDoc = await fakeFirestore.collection('orders').doc('ORD-SHIP').get();
      expect(updatedDoc.data()!['status'], 'Shipped');
    });

    test('20. Admin membatalkan pesanan secara manual', () async {
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

    test('21. Customer Support melihat detail pesanan', () async {
      await fakeFirestore.collection('orders').doc('ORD-CS').set({
        'orderId': 'ORD-CS',
        'status': 'Delivered',
      });

      final order = await csController.getOrderById('ORD-CS');
      expect(order, isNotNull);
      expect(order!.orderId, 'ORD-CS');
    });
  });
}
