import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:ecommerce/features/dashboard/controllers/dashboard_user_controller.dart';

void main() {
  group('DashboardUserController Unit Tests (Whitebox)', () {
    late MockFirebaseAuth mockAuth;
    late FakeFirebaseFirestore mockFirestore;
    late DashboardUserController controller;

    setUp(() {
      final mockUser = MockUser(uid: 'user_uid', email: 'user@email.com');
      mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
      mockFirestore = FakeFirebaseFirestore();
      controller = DashboardUserController(auth: mockAuth, firestore: mockFirestore);
    });

    group('User Data & Dashboard Stats (TC-21)', () {
      test('getUserData & getUserFullName return correct user profile information', () async {
        await mockFirestore.collection('users').doc('user_uid').set({
          'fullName': 'Andhika Retailer',
          'storeName': 'Andhika Mart',
          'role': 'retailer',
        });

        final data = await controller.getUserData();
        expect(data, isNotNull);
        expect(data!['fullName'], 'Andhika Retailer');
        expect(data['uid'], 'user_uid');

        final fullName = await controller.getUserFullName();
        expect(fullName, 'Andhika Retailer');
      });

      test('getUserFullName falls back to "Retailer" on empty data', () async {
        final fullName = await controller.getUserFullName();
        expect(fullName, 'Retailer');
      });

      test('getDashboardStats calculates correct order aggregations for this user', () async {
        // Seed orders for this user (with statuses Paid, Shipped, Delivered)
        await mockFirestore.collection('orders').doc('ord_1').set({
          'userId': 'user_uid',
          'total': 120000.0,
          'status': 'Paid',
        });
        await mockFirestore.collection('orders').doc('ord_2').set({
          'userId': 'user_uid',
          'total': 80000.0,
          'status': 'Delivered',
        });

        // Ignored order (different user)
        await mockFirestore.collection('orders').doc('ord_3').set({
          'userId': 'different_user',
          'total': 50000.0,
          'status': 'Paid',
        });

        // Ignored order (unsupported status)
        await mockFirestore.collection('orders').doc('ord_4').set({
          'userId': 'user_uid',
          'total': 60000.0,
          'status': 'Pending',
        });

        final stats = await controller.getDashboardStats();

        expect(stats['totalOrders'], 2);
        expect(stats['totalSpent'], 200000.0);
      });

      test('getRecentOrders returns recent orders stream for the active user', () async {
        // Seed orders
        for (int i = 1; i <= 6; i++) {
          await mockFirestore.collection('orders').doc('ord$i').set({
            'userId': i == 6 ? 'other_uid' : 'user_uid',
            'total': i * 10000.0,
          });
        }

        final stream = controller.getRecentOrders();
        final list = await stream.first;

        // Capped at 5 and only for user_uid
        expect(list.length, 5);
        expect(list.any((ord) => ord['userId'] == 'other_uid'), false);
      });

      test('getRecommendedProducts returns stream of recommended products sorted by monthly sales descending', () async {
        // Seed products
        for (int i = 1; i <= 12; i++) {
          await mockFirestore.collection('products').doc('prod$i').set({
            'name': 'Product $i',
            'price': 10000.0 * i,
            'description': 'Product Description',
            'stock': 10,
            'imageUrl': 'image_url',
            'category': 'Skincare',
            'monthlySales': i * 10, // Higher sales descending order
          });
        }

        final stream = controller.getRecommendedProducts();
        final list = await stream.first;

        // Capped at limit 10, sorted descending (so prod12 has monthlySales 120 and should be first)
        expect(list.length, 10);
        expect(list.first.id, 'prod12');
        expect(list.first.name, 'Product 12');
      });
    });

    group('Error Paths & Exception Handling', () {
      test('getUserData returns null if unauthenticated', () async {
        await mockAuth.signOut();
        final data = await controller.getUserData();
        expect(data, null);
      });

      test('getUserFullName falls back to "Retailer" on exceptions', () async {
        await mockAuth.signOut();
        final name = await controller.getUserFullName();
        expect(name, 'Retailer');
      });

      test('getDashboardStats throws exception if unauthenticated', () async {
        await mockAuth.signOut();
        expect(() => controller.getDashboardStats(), throwsA(isA<Exception>()));
      });

      test('getRecentOrders returns empty stream if unauthenticated', () async {
        await mockAuth.signOut();
        final stream = controller.getRecentOrders();
        final list = await stream.first;
        expect(list.isEmpty, true);
      });

      test('Firestore query failures propagated correctly', () async {
        final badFirestore = MockFirestoreCustomException();
        final badController = DashboardUserController(auth: mockAuth, firestore: badFirestore);

        expect(() => badController.getDashboardStats(), throwsA(isA<Exception>()));
      });
    });
  });
}

// Custom mock class
class MockFirestoreCustomException extends FakeFirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    throw Exception('Firestore query failed');
  }
}
