import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerce/features/order/views/order_detail_admin_view.dart';
import 'package:ecommerce/features/order/controllers/order_admin_controller.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ecommerce/features/notification/services/push_notification_service.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

class MockPushNotificationService extends Mock implements PushNotificationService {}

void main() {
  late MockPushNotificationService mockPushNotificationService;

  setUp(() {
    mockPushNotificationService = MockPushNotificationService();
    
    when(() => mockPushNotificationService.sendNotificationToUser(
          userId: any(named: 'userId'),
          title: any(named: 'title'),
          message: any(named: 'message'),
          type: any(named: 'type'),
          relatedId: any(named: 'relatedId'),
        )).thenAnswer((_) async => true);
  });

  testWidgets('17. Validasi UI garis status pesanan (Order Stepper)', (WidgetTester tester) async {
    dotenv.loadFromString(envString: 'FCM_SERVER_KEY=dummy\nBACKEND_URL=mock');
    final fakeFirestore = FakeFirebaseFirestore();
    
    // Setup data pesanan dengan status 'Shipped'
    final orderId = 'ORD-STEPPER';
    await fakeFirestore.collection('orders').doc(orderId).set({
      'orderId': orderId,
      'status': 'Shipped',
      'fullName': 'Test Retailer',
      'shippingAddress': 'Test Address',
      'phoneNumber': '0812',
      'total': 100000.0,
      'subtotal': 100000.0,
      'shippingCost': 0.0,
      'tax': 0.0,
      'discountAmount': 0.0,
      'paymentMethod': 'Duitku',
      'createdAt': Timestamp.now(),
      'items': [],
    });

    final adminController = OrderAdminController(
      firestore: fakeFirestore,
      pushNotificationService: mockPushNotificationService,
    );

    // Jalankan widget (OrderDetailAdminView menampilkan status stepper)
    await tester.pumpWidget(
      MaterialApp(
        home: OrderDetailAdminView(
          orderId: orderId, 
          adminController: adminController,
        ),
      ),
    );

    // Tunggu loading Firestore
    await tester.pumpAndSettle();

    // Verifikasi apakah tahapan status muncul (Gunakan findsAtLeastNWidgets karena teks bisa muncul di info juga)
    expect(find.text('Belum bayar'), findsAtLeastNWidgets(1));
    expect(find.text('Dikemas'), findsAtLeastNWidgets(1));
    expect(find.text('Dikirim'), findsAtLeastNWidgets(1));
    expect(find.text('Selesai'), findsAtLeastNWidgets(1));
  });
}
