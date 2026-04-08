import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:ecommerce/features/dashboard/controllers/dashboard_admin_controller.dart';

void main() {
  late DashboardAdminController dashboardController;
  late MockFirebaseAuth mockAuth;
  late FakeFirebaseFirestore fakeFirestore;
  late MockUser mockUser;

  setUp(() {
    mockUser = MockUser(
      isAnonymous: false,
      uid: 'admin123',
      email: 'admin@test.com',
    );
    mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
    fakeFirestore = FakeFirebaseFirestore();

    dashboardController = DashboardAdminController(
      auth: mockAuth,
      firestore: fakeFirestore,
    );
  });

  group('DashboardAdminController Tests', () {
    test('getOverviewStats returns default structured data', () async {
      final stats = await dashboardController.getOverviewStats();
      expect(stats, isNotNull);
      expect(stats['totalSales'], equals('\$10,000'));
      expect(stats['totalOrders'], equals(850));
      expect(stats['totalCustomers'], equals(1200));
      expect(stats['conversionRate'], equals(65.5));
    });

    test('getPromotions returns active promotions only (limit 5)', () async {
      await fakeFirestore.collection('promotions').add({'status': 'active', 'title': 'Promo A'});
      await fakeFirestore.collection('promotions').add({'status': 'active', 'title': 'Promo B'});
      await fakeFirestore.collection('promotions').add({'status': 'inactive', 'title': 'Promo C'});

      final promos = await dashboardController.getPromotions();
      expect(promos.length, equals(2));
      expect(promos[0]['title'], equals('Promo A'));
      expect(promos[1]['title'], equals('Promo B'));
    });

    test('getRetailers returns users with retailer role', () async {
      await fakeFirestore.collection('users').add({'role': 'retailer', 'fullName': 'Toko A'});
      await fakeFirestore.collection('users').add({'role': 'retailer', 'fullName': 'Toko B'});
      await fakeFirestore.collection('users').add({'role': 'admin', 'fullName': 'Admin Super'});

      final retailers = await dashboardController.getRetailers();
      expect(retailers.length, equals(2));
      expect(retailers[0]['fullName'], equals('Toko A'));
    });

    test('getAdminInfo returns admin doc data', () async {
      await fakeFirestore.collection('users').doc('admin123').set({
        'role': 'admin',
        'fullName': 'John Doe',
      });

      final info = await dashboardController.getAdminInfo();
      expect(info, isNotNull);
      expect(info!['fullName'], equals('John Doe'));
    });
  });
}
