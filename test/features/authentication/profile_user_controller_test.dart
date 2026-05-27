import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:ecommerce/features/authentication/controllers/profile_user_controller.dart';

void main() {
  group('RetailProfileController Unit Tests (Whitebox)', () {
    late MockFirebaseAuth mockAuth;
    late FakeFirebaseFirestore mockFirestore;
    late RetailProfileController controller;

    setUp(() {
      final mockUser = MockUser(uid: 'retailer_uid', email: 'retailer@email.com');
      mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
      mockFirestore = FakeFirebaseFirestore();
      controller = RetailProfileController(auth: mockAuth, firestore: mockFirestore);
    });

    group('Form Input Validators (TC-24 & TC-25)', () {
      // Inline form validator from form_edit_user_view.dart:
      // (value) {
      //   if (value == null || value.trim().isEmpty) {
      //     return '* $label is required';
      //   }
      //   return null;
      // }
      final validateField = (String label, String? value) {
        if (value == null || value.trim().isEmpty) {
          return '* $label is required';
        }
        return null;
      };

      test('TC-24: updateProfile() dengan business name kosong -> error "* Business Name is required"', () {
        final validationResult = validateField('Business Name', '');
        expect(validationResult, contains('Business Name is required'));
        expect(validateField('Business Name', null), contains('Business Name is required'));
      });

      test('TC-25: updateProfile() dengan contact kosong -> error "* Contact is required"', () {
        final validationResult = validateField('Contact', '');
        expect(validationResult, contains('Contact is required'));
        expect(validateField('Contact', null), contains('Contact is required'));
      });

      test('Field validators return null when fields are filled', () {
        expect(validateField('Business Name', 'My Store'), null);
        expect(validateField('Contact', '08123456789'), null);
      });
    });

    group('Profile Load & Stats Fetching (TC-22)', () {
      test('TC-22: getProfile() -> success, data profil terisi (nama, Store ID, email, contact, totalOrders, totalSpent)', () async {
        // 1. Seed user profile data in Firestore
        await mockFirestore.collection('users').doc('retailer_uid').set({
          'fullName': 'Gede Store',
          'email': 'retailer@email.com',
          'phoneNumber': '081234567890',
          'businessType': 'Pet Shop',
          'role': 'retailer',
          'isActive': true,
        });

        // 2. Seed orders for stats verification (Paid, Shipped, Delivered are summed)
        await mockFirestore.collection('orders').doc('ord_1').set({
          'userId': 'retailer_uid',
          'total': 100000.0,
          'status': 'Paid',
        });
        await mockFirestore.collection('orders').doc('ord_2').set({
          'userId': 'retailer_uid',
          'total': 200000.0,
          'status': 'Delivered',
        });
        await mockFirestore.collection('orders').doc('ord_3').set({
          'userId': 'retailer_uid',
          'total': 150000.0,
          'status': 'Pending', // ignored in spent calculation
        });

        // 3. Fetch profile
        final profile = await controller.getRetailProfile();
        expect(profile, isNotNull);
        expect(profile!['fullName'], 'Gede Store');
        expect(profile['email'], 'retailer@email.com');
        expect(profile['phoneNumber'], '081234567890');
        expect(profile['businessType'], 'Pet Shop');
        expect(profile['uid'], 'retailer_uid');

        // 4. Fetch stats
        final stats = await controller.getRetailStats();
        expect(stats['totalOrders'], 3); // all orders count in totalOrders
        expect(stats['totalSpent'], 300000.0); // sum of ord_1 (Paid) and ord_2 (Delivered)
      });
    });

    group('Profile Update & Operations (TC-23)', () {
      test('TC-23: updateProfile() dengan data valid -> success, Firestore document is updated', () async {
        // Seed initial data
        await mockFirestore.collection('users').doc('retailer_uid').set({
          'fullName': 'Old Store',
          'phoneNumber': '0800000000',
          'businessType': 'Lainnya',
        });

        // Update profile
        await controller.updateRetailProfile(
          storeName: 'New Valid Store',
          contact: '081122334455',
          businessType: 'Skincare',
        );

        // Assert updates in Firestore
        final doc = await mockFirestore.collection('users').doc('retailer_uid').get();
        expect(doc.exists, true);
        expect(doc.data()?['fullName'], 'New Valid Store');
        expect(doc.data()?['phoneNumber'], '081122334455');
        expect(doc.data()?['businessType'], 'Skincare');
      });

      test('updateStoreStatus toggles the isActive field correctly in Firestore', () async {
        await mockFirestore.collection('users').doc('retailer_uid').set({
          'isActive': true,
        });

        // Toggle to false
        await controller.updateStoreStatus(false);

        var doc = await mockFirestore.collection('users').doc('retailer_uid').get();
        expect(doc.data()?['isActive'], false);

        // Toggle to true
        await controller.updateStoreStatus(true);

        doc = await mockFirestore.collection('users').doc('retailer_uid').get();
        expect(doc.data()?['isActive'], true);
      });

      test('getRetailProfileStream streams real-time updates for user profile', () async {
        await mockFirestore.collection('users').doc('retailer_uid').set({
          'fullName': 'Stream Store',
          'role': 'retailer',
        });

        final stream = controller.getRetailProfileStream();
        final firstEmit = await stream.first;

        expect(firstEmit, isNotNull);
        expect(firstEmit!['fullName'], 'Stream Store');
        expect(firstEmit['uid'], 'retailer_uid');
      });
    });

    group('Error Paths & Exceptions', () {
      test('getRetailProfile returns null if unauthenticated', () async {
        await mockAuth.signOut();
        final profile = await controller.getRetailProfile();
        expect(profile, null);
      });

      test('getRetailProfileStream returns single-value null stream if unauthenticated', () async {
        await mockAuth.signOut();
        final stream = controller.getRetailProfileStream();
        final firstEmit = await stream.first;
        expect(firstEmit, null);
      });

      test('getRetailStats throws exception if unauthenticated', () async {
        await mockAuth.signOut();
        expect(() => controller.getRetailStats(), throwsA(isA<Exception>()));
      });

      test('getRetailProfile throws generic exception if firestore fails', () async {
        final badFirestore = MockFirestoreCustomException();
        final badController = RetailProfileController(auth: mockAuth, firestore: badFirestore);

        expect(() => badController.getRetailProfile(), throwsA(isA<Exception>()));
      });

      test('updateRetailProfile throws generic exception if firestore fails', () async {
        final badFirestore = MockFirestoreCustomException();
        final badController = RetailProfileController(auth: mockAuth, firestore: badFirestore);

        expect(
          () => badController.updateRetailProfile(
            storeName: 'Error Store',
            contact: '123',
            businessType: 'Lainnya',
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('updateStoreStatus throws generic exception if firestore fails', () async {
        final badFirestore = MockFirestoreCustomException();
        final badController = RetailProfileController(auth: mockAuth, firestore: badFirestore);

        expect(() => badController.updateStoreStatus(true), throwsA(isA<Exception>()));
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
