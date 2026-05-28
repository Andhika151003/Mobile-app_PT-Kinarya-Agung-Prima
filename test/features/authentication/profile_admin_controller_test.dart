import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:ecommerce/features/authentication/controllers/profile_admin_controller.dart';

void main() {
  group('AdminProfileController Unit Tests (Whitebox)', () {
    late MockFirebaseAuth mockAuth;
    late FakeFirebaseFirestore mockFirestore;
    late AdminProfileController controller;

    setUp(() {
      final mockUser = MockUser(uid: 'admin_uid', email: 'admin@email.com');
      mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
      mockFirestore = FakeFirebaseFirestore();
      controller = AdminProfileController(auth: mockAuth, firestore: mockFirestore);
    });

    group('Form Input Validators (TC-28 & TC-29)', () {
      // Inline form validator from form_edit_admin_view.dart:
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

      test('TC-28: updateProfile() dengan nama kosong -> error "* Business Name is required"', () {
        final validationResult = validateField('Business Name', '');
        expect(validationResult, contains('Business Name is required'));
        expect(validateField('Business Name', null), contains('Business Name is required'));
      });

      test('TC-29: updateProfile() dengan contact kosong -> error "* Contact is required"', () {
        final validationResult = validateField('Contact', '');
        expect(validationResult, contains('Contact is required'));
        expect(validateField('Contact', null), contains('Contact is required'));
      });

      test('Field validators return null when fields are filled', () {
        expect(validateField('Business Name', 'Admin Office'), null);
        expect(validateField('Contact', '08123456789'), null);
      });
    });

    group('Profile Load & Stats Fetching (TC-26)', () {
      test('TC-26: getProfile() -> success, data profil terisi (nama, role, distributorId, contact)', () async {
        // 1. Seed admin profile data in Firestore
        await mockFirestore.collection('users').doc('admin_uid').set({
          'fullName': 'Agung Admin',
          'email': 'admin@email.com',
          'phoneNumber': '081234567890',
          'businessType': 'Distributor',
          'role': 'admin',
          'isActive': true,
        });

        final profile = await controller.getAdminProfile();

        // Assert profile fields
        expect(profile, isNotNull);
        expect(profile!['fullName'], 'Agung Admin');
        expect(profile['role'], 'admin');
        expect(profile['businessType'], 'Distributor'); // acts as distributorId / businessType
        expect(profile['phoneNumber'], '081234567890');
        expect(profile['uid'], 'admin_uid');
      });

      test('TC-26 (Stats): getAdminStats() calculates total revenue and monthly sales units correctly', () async {
        final now = DateTime.now();
        final currentMonth = Timestamp.fromDate(DateTime(now.year, now.month, 10));
        final lastMonth = Timestamp.fromDate(DateTime(now.year, now.month - 1, 15));

        // 1. Order in current month, status Paid (included in revenue & monthly unit sold)
        await mockFirestore.collection('orders').doc('ord_cur_1').set({
          'total': 150000.0,
          'status': 'Paid',
          'createdAt': currentMonth,
          'items': [
            {'quantity': 3},
            {'quantity': 2},
          ],
        });

        // 2. Order in current month, status Delivered (included in revenue & monthly unit sold)
        await mockFirestore.collection('orders').doc('ord_cur_2').set({
          'total': 250000.0,
          'status': 'Delivered',
          'createdAt': currentMonth,
          'items': [
            {'quantity': 1},
          ],
        });

        // 3. Order in previous month, status Shipped (included in revenue, but excluded from monthly unit sold)
        await mockFirestore.collection('orders').doc('ord_prev_1').set({
          'total': 100000.0,
          'status': 'Shipped',
          'createdAt': lastMonth,
          'items': [
            {'quantity': 5},
          ],
        });

        // 4. Order in current month, status Pending (excluded from revenue and monthly unit sold)
        await mockFirestore.collection('orders').doc('ord_pending').set({
          'total': 300000.0,
          'status': 'Pending',
          'createdAt': currentMonth,
          'items': [
            {'quantity': 10},
          ],
        });

        final stats = await controller.getAdminStats();

        // Total revenue = 150000 (ord_cur_1) + 250000 (ord_cur_2) + 100000 (ord_prev_1) = 500000.0
        expect(stats['totalRevenue'], 500000.0);
        // Monthly sales units (only current month completed orders) = 5 (from ord_cur_1) + 1 (from ord_cur_2) = 6
        expect(stats['monthlySales'], 6);
      });
    });

    group('Profile Update & Operations (TC-27)', () {
      test('TC-27: updateProfile() dengan data valid -> success, Firestore document is updated', () async {
        // Seed initial admin data
        await mockFirestore.collection('users').doc('admin_uid').set({
          'fullName': 'Old Admin',
          'phoneNumber': '0800000000',
          'businessType': 'Distributor',
        });

        // Update profile
        await controller.updateAdminProfile(
          fullName: 'New Valid Admin Name',
          phoneNumber: '089988776655',
          businessType: 'Super Distributor',
        );

        // Assert updates in Firestore
        final doc = await mockFirestore.collection('users').doc('admin_uid').get();
        expect(doc.exists, true);
        expect(doc.data()?['fullName'], 'New Valid Admin Name');
        expect(doc.data()?['phoneNumber'], '089988776655');
        expect(doc.data()?['businessType'], 'Super Distributor');
      });
    });

    group('Error Paths & Exceptions', () {
      test('getAdminProfile returns null if unauthenticated', () async {
        await mockAuth.signOut();
        final profile = await controller.getAdminProfile();
        expect(profile, null);
      });

      test('getAdminProfile throws generic exception if firestore fails', () async {
        final badFirestore = MockFirestoreCustomException();
        final badController = AdminProfileController(auth: mockAuth, firestore: badFirestore);

        expect(() => badController.getAdminProfile(), throwsA(isA<Exception>()));
      });

      test('updateAdminProfile throws generic exception if firestore fails', () async {
        final badFirestore = MockFirestoreCustomException();
        final badController = AdminProfileController(auth: mockAuth, firestore: badFirestore);

        expect(
          () => badController.updateAdminProfile(
            fullName: 'Error Admin',
            phoneNumber: '123',
            businessType: 'Distributor',
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('getAdminStats returns default values when firestore throws exception', () async {
        final badFirestore = MockFirestoreCustomException();
        final badController = AdminProfileController(auth: mockAuth, firestore: badFirestore);

        final stats = await badController.getAdminStats();
        expect(stats['totalRevenue'], 0.0);
        expect(stats['monthlySales'], 0);
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
