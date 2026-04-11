import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:ecommerce/features/dashboard/controllers/dashboard_user_controller.dart';

void main() {
  late DashboardUserController dashboardController;
  late MockFirebaseAuth mockAuth;
  late FakeFirebaseFirestore fakeFirestore;
  late MockUser mockUser;

  setUp(() {
    mockUser = MockUser(
      isAnonymous: false,
      uid: 'user123',
      email: 'retail@test.com',
    );
    mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
    fakeFirestore = FakeFirebaseFirestore();

    dashboardController = DashboardUserController(
      auth: mockAuth,
      firestore: fakeFirestore,
    );
  });

  group('DashboardUserController Tests', () {
    test('getUserData returns data when document exists', () async {
      await fakeFirestore.collection('users').doc('user123').set({
        'fullName': 'Maju Jaya',
        'role': 'retail',
      });

      final data = await dashboardController.getUserData();
      
      expect(data, isNotNull);
      expect(data!['fullName'], equals('Maju Jaya'));
      expect(data['uid'], equals('user123'));
    });

    test('getUserFullName returns Retailer when name is absent', () async {
      await fakeFirestore.collection('users').doc('user123').set({
        'role': 'retail',
      });

      final name = await dashboardController.getUserFullName();
      expect(name, equals('Retailer'));
    });

    test('getUserFullName returns correct name when data exists', () async {
      await fakeFirestore.collection('users').doc('user123').set({
        'fullName': 'Budi Setiawan',
      });

      final name = await dashboardController.getUserFullName();
      expect(name, equals('Budi Setiawan'));
    });

    test('getDashboardStats returns initial empty stats dashboard map', () async {
      final stats = await dashboardController.getDashboardStats();
      expect(stats['totalOrders'], equals(0));
      expect(stats['pendingOrders'], equals(0));
      expect(stats['totalRevenue'], equals(0.0));
      expect(stats['recentNotifications'], isEmpty);
    });

    test('getRecommendedProducts returns stream of limit 10 products', () async {
      await fakeFirestore.collection('products').add({'name': 'Beras Makmur', 'price': 15000});
      await fakeFirestore.collection('products').add({'name': 'Minyak Goreng', 'price': 30000});

      final stream = dashboardController.getRecommendedProducts();
      final products = await stream.first;

      expect(products.length, equals(2));
      expect(products[0].name, equals('Beras Makmur'));
      expect(products[0].price, equals(15000));
    });
  });
}
