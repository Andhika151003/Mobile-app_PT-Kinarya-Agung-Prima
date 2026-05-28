import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:ecommerce/features/dashboard/controllers/dashboard_admin_controller.dart';

void main() {
  group('DashboardAdminController Unit Tests (Whitebox)', () {
    late MockFirebaseAuth mockAuth;
    late FakeFirebaseFirestore mockFirestore;
    late DashboardAdminController controller;

    setUp(() {
      final mockUser = MockUser(uid: 'admin_uid', email: 'admin@email.com');
      mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
      mockFirestore = FakeFirebaseFirestore();
      controller = DashboardAdminController(auth: mockAuth, firestore: mockFirestore);
    });

    group('Stats & Information Fetching (TC-19)', () {
      test('getOverviewStats returns correct aggregated stats', () async {
        // 1. Seed retailers in users collection
        await mockFirestore.collection('users').doc('retailer1').set({
          'fullName': 'Retailer One',
          'role': 'retailer',
        });
        await mockFirestore.collection('users').doc('retailer2').set({
          'fullName': 'Retailer Two',
          'role': 'retailer',
        });

        // 2. Seed orders with status 'Paid', 'Shipped', 'Delivered'
        await mockFirestore.collection('orders').doc('order1').set({
          'total': 150000.0,
          'status': 'Paid',
        });
        await mockFirestore.collection('orders').doc('order2').set({
          'total': 250000.0,
          'status': 'Shipped',
        });
        await mockFirestore.collection('orders').doc('order3').set({
          'total': 50000.0,
          'status': 'Delivered',
        });
        // This order should be ignored in stats because of status
        await mockFirestore.collection('orders').doc('order4').set({
          'total': 90000.0,
          'status': 'Pending',
        });

        final stats = await controller.getOverviewStats();

        // 3. Assert aggregations (3 valid orders out of 4, total revenue = 450000.0, customers = 2)
        expect(stats['totalSales'], 450000.0);
        expect(stats['totalOrders'], 3);
        expect(stats['totalCustomers'], 2);
        expect(stats['conversionRate'], '150.0'); // 3 / 2 * 100
      });

      test('getPromotions returns active promotions up to limit', () async {
        // Seed promotions
        for (int i = 1; i <= 6; i++) {
          await mockFirestore.collection('promotions').doc('promo$i').set({
            'title': 'Promo $i',
            'status': i == 6 ? 'inactive' : 'active',
          });
        }

        final promos = await controller.getPromotions();

        // Should return only active ones, capped at 5
        expect(promos.length, 5);
        expect(promos.first['title'], 'Promo 1');
        expect(promos.any((p) => p['title'] == 'Promo 6'), false);
      });

      test('getPromotions returns empty list when promotions are empty ("No Active Promotions")', () async {
        final promos = await controller.getPromotions();
        expect(promos.isEmpty, true);
      });

      test('getRetailers returns only retailer users up to limit', () async {
        // Seed retailers and non-retailers
        for (int i = 1; i <= 12; i++) {
          await mockFirestore.collection('users').doc('user$i').set({
            'fullName': 'User $i',
            'role': i == 12 ? 'admin' : 'retailer',
          });
        }

        final retailers = await controller.getRetailers();

        // Should return only retailers, capped at 10
        expect(retailers.length, 10);
        expect(retailers.any((r) => r['fullName'] == 'User 12'), false);
      });

      test('getAdminInfo returns details of the currently signed-in admin', () async {
        await mockFirestore.collection('users').doc('admin_uid').set({
          'fullName': 'System Administrator',
          'role': 'admin',
        });

        final info = await controller.getAdminInfo();
        expect(info, isNotNull);
        expect(info!['fullName'], 'System Administrator');
      });

      test('getAllComplaints returns sorted stream of complaints', () async {
        // Seed complaints with different created timestamps
        await mockFirestore.collection('complaints').doc('comp1').set({
          'issueType': 'Late Delivery',
          'description': 'Description 1',
          'status': 'pending',
          'createdAt': Timestamp.fromDate(DateTime(2026, 5, 20)),
        });
        await mockFirestore.collection('complaints').doc('comp2').set({
          'issueType': 'Damaged Item',
          'description': 'Description 2',
          'status': 'resolved',
          'createdAt': Timestamp.fromDate(DateTime(2026, 5, 25)),
        });

        final complaintsStream = controller.getAllComplaints();
        final list = await complaintsStream.first;

        expect(list.length, 2);
        // Sorted descending: comp2 (May 25) should be first
        expect(list.first.id, 'comp2');
        expect(list.first.issueType, 'Damaged Item');
      });
    });

    group('Error Paths & Unauthenticated Failures', () {
      test('OverviewStats throws exception if unauthenticated', () async {
        await mockAuth.signOut();
        expect(() => controller.getOverviewStats(), throwsA(isA<Exception>()));
      });

      test('Promotions throws exception if unauthenticated', () async {
        await mockAuth.signOut();
        expect(() => controller.getPromotions(), throwsA(isA<Exception>()));
      });

      test('Retailers throws exception if unauthenticated', () async {
        await mockAuth.signOut();
        expect(() => controller.getRetailers(), throwsA(isA<Exception>()));
      });

      test('getAdminInfo returns null if unauthenticated', () async {
        await mockAuth.signOut();
        final info = await controller.getAdminInfo();
        expect(info, null);
      });

      test('Firestore query exception propagated correctly', () async {
        final badFirestore = MockFirestoreCustomException();
        final badController = DashboardAdminController(auth: mockAuth, firestore: badFirestore);

        expect(() => badController.getOverviewStats(), throwsA(isA<Exception>()));
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
