import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:ecommerce/features/payment%20&%20checkout/controllers/checkout_controller.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late CheckoutController checkoutController;
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late MockHttpClient mockHttpClient;
  late MockUser mockUser;

  setUpAll(() async {
    registerFallbackValue(Uri.parse('http://localhost'));
  });

  setUp(() {
    mockUser = MockUser(
      uid: 'user123',
      email: 'test@example.com',
      displayName: 'Test User',
    );
    mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
    fakeFirestore = FakeFirebaseFirestore();
    mockHttpClient = MockHttpClient();

    checkoutController = CheckoutController(
      firestore: fakeFirestore,
      auth: mockAuth,
      client: mockHttpClient,
      backendUrl: 'https://test.url',
    );
  });

  group('Unit Test CheckoutController', () {
    test('Alur checkout berhasil', () async {
      // 1. Setup produk di Firestore
      await fakeFirestore.collection('products').doc('p1').set({
        'name': 'Produk 1',
        'stock': 10,
        'price': 100.0,
      });

      // 2. Setup Mock HTTP Response
      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(
            jsonEncode({
              'success': true,
              'paymentUrl': 'https://payment.url',
            }),
            200,
          ));

      // 3. Proses Checkout
      final result = await checkoutController.processCheckout(
        fullName: 'Test User',
        shippingAddress: 'Alamat Test',
        paymentMethod: 'Duitku',
        paymentMethodCode: 'VC',
        promoCode: 'NONE',
        subtotal: 200.0,
        shippingCost: 10.0,
        tax: 0.0,
        total: 210.0,
        items: [
          {'productId': 'p1', 'title': 'Produk 1', 'quantity': 2, 'price': 100.0}
        ],
      );

      // 4. Verifikasi hasil
      expect(result.containsKey('paymentUrl'), isTrue);
      expect(result['paymentUrl'], equals('https://payment.url'));
      expect(result.containsKey('orderId'), isTrue);

      // 5. Verifikasi pembaruan Firestore
      final productDoc = await fakeFirestore.collection('products').doc('p1').get();
      expect(productDoc.data()!['stock'], equals(8)); // 10 - 2

      final orderDoc = await fakeFirestore.collection('orders').doc(result['orderId']!).get();
      expect(orderDoc.exists, isTrue);
      expect(orderDoc.data()!['status'], equals('Ordered'));
      expect(orderDoc.data()!['paymentUrl'], equals('https://payment.url'));
    });

    test('Checkout gagal saat stok produk habis', () async {
      // 1. Setup produk dengan stok rendah
      await fakeFirestore.collection('products').doc('p1').set({
        'name': 'Produk 1',
        'stock': 1,
      });

      // 2. Proses Checkout untuk 2 item
      final result = await checkoutController.processCheckout(
        fullName: 'Test User',
        shippingAddress: 'Alamat Test',
        paymentMethod: 'Duitku',
        paymentMethodCode: 'VC',
        promoCode: 'NONE',
        subtotal: 200.0,
        shippingCost: 10.0,
        tax: 0.0,
        total: 210.0,
        items: [
          {'productId': 'p1', 'title': 'Produk 1', 'quantity': 2, 'price': 100.0}
        ],
      );

      // 3. Verifikasi error
      expect(result.containsKey('error'), isTrue);
      expect(result['error'], contains('Stok "Produk 1" tidak mencukupi'));
      
      // 4. Verifikasi stok TIDAK diperbarui
      final productDoc = await fakeFirestore.collection('products').doc('p1').get();
      expect(productDoc.data()!['stock'], equals(1));
    });

    test('Checkout gagal saat API Duitku mengembalikan error', () async {
      // 1. Setup produk
      await fakeFirestore.collection('products').doc('p1').set({
        'name': 'Produk 1',
        'stock': 10,
      });

      // 2. Setup Mock HTTP Response untuk error
      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(
            jsonEncode({
              'success': false,
              'message': 'Metode pembayaran tidak valid',
            }),
            200,
          ));

      // 3. Proses Checkout
      final result = await checkoutController.processCheckout(
        fullName: 'Test User',
        shippingAddress: 'Alamat Test',
        paymentMethod: 'Duitku',
        paymentMethodCode: 'VC',
        promoCode: 'NONE',
        subtotal: 100.0,
        shippingCost: 10.0,
        tax: 0.0,
        total: 110.0,
        items: [
          {'productId': 'p1', 'title': 'Produk 1', 'quantity': 1, 'price': 100.0}
        ],
      );

      // 4. Verifikasi error
      expect(result.containsKey('error'), isTrue);
      expect(result['error'], contains('Duitku ditolak'));
    });
  });
}
