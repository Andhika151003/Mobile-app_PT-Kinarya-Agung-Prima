import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:ecommerce/features/authentication/controllers/profile_cs_controller.dart';

void main() {
  group('ProfileCsController Unit Tests (Whitebox)', () {
    late MockFirebaseAuth mockAuth;
    late FakeFirebaseFirestore mockFirestore;
    late ProfileCsController controller;

    setUp(() {
      final mockUser = MockUser(uid: 'cs_uid', email: 'cs@email.com');
      mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
      mockFirestore = FakeFirebaseFirestore();
      controller = ProfileCsController(auth: mockAuth, firestore: mockFirestore);
    });

    group('Profile Load & Resolved Complaints Stream (TC-30)', () {
      test('TC-30: getProfile() -> success, data profil terisi (nama, role, csId, department, contact, totalTickets)', () async {
        // 1. Seed CS profile data in Firestore
        await mockFirestore.collection('users').doc('cs_uid').set({
          'fullName': 'Budi CS Support',
          'email': 'cs@email.com',
          'phoneNumber': '081234567890',
          'role': 'cs',
          'isActive': true,
        });

        // 2. Seed complaints for resolved tickets count
        // Resolved by this CS (included in totalTickets stream count)
        await mockFirestore.collection('complaints').doc('ticket_1').set({
          'status': 'resolved',
          'resolvedBy': 'cs_uid',
        });
        await mockFirestore.collection('complaints').doc('ticket_2').set({
          'status': 'resolved',
          'resolvedBy': 'cs_uid',
        });
        // Pending by this CS (ignored in resolved stream count)
        await mockFirestore.collection('complaints').doc('ticket_3').set({
          'status': 'pending',
          'resolvedBy': 'cs_uid',
        });
        // Resolved by another CS (ignored in resolved stream count)
        await mockFirestore.collection('complaints').doc('ticket_4').set({
          'status': 'resolved',
          'resolvedBy': 'other_cs_uid',
        });

        // 3. Fetch CS profile
        final profile = await controller.getCsProfile();
        expect(profile, isNotNull);
        expect(profile!['fullName'], 'Budi CS Support');
        expect(profile['role'], 'cs');
        expect(profile['phoneNumber'], '081234567890');
        expect(profile['uid'], 'cs_uid');

        // 4. Fetch resolved count stream
        final stream = controller.getResolvedCountStream();
        final count = await stream.first;
        expect(count, 2); // only ticket_1 and ticket_2 are resolved by cs_uid
      });
    });

    group('Error Paths & Exceptions', () {
      test('getCsProfile returns null if unauthenticated', () async {
        await mockAuth.signOut();
        final profile = await controller.getCsProfile();
        expect(profile, null);
      });

      test('getResolvedCountStream returns 0 stream if unauthenticated', () async {
        await mockAuth.signOut();
        final stream = controller.getResolvedCountStream();
        final count = await stream.first;
        expect(count, 0);
      });

      test('getCsProfile throws generic exception if firestore fails', () async {
        final badFirestore = MockFirestoreCustomException();
        final badController = ProfileCsController(auth: mockAuth, firestore: badFirestore);

        expect(() => badController.getCsProfile(), throwsA(isA<Exception>()));
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
