import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:ecommerce/features/admin/controller/admin_cs_controller.dart';
import 'package:ecommerce/features/authentication/models/cs.dart';

void main() {
  group('AdminCsController Unit Tests (Whitebox)', () {
    late MockAdminFirebaseAuth mockAuth;
    late FakeFirebaseFirestore mockFirestore;
    late AdminCsController controller;

    // Helper to seed admin user
    Future<void> seedAdmin() async {
      await mockFirestore.collection('users').doc('admin_uid').set({
        'fullName': 'System Admin',
        'email': 'admin@email.com',
        'role': 'admin',
        'isActive': true,
      });
    }

    // Helper to seed non-admin user
    Future<void> seedNonAdmin() async {
      await mockFirestore.collection('users').doc('non_admin_uid').set({
        'fullName': 'Retailer User',
        'email': 'retailer@email.com',
        'role': 'retailer',
        'isActive': true,
      });
    }

    setUp(() {
      final mockAdminUser = MockUser(uid: 'admin_uid', email: 'admin@email.com');
      mockAuth = MockAdminFirebaseAuth(mockAdminUser);
      mockFirestore = FakeFirebaseFirestore();
      controller = AdminCsController(firestore: mockFirestore, auth: mockAuth);
    });

    group('Fetch CS List & Statistics (TC-31)', () {
      test('TC-31: fetchAllCS() -> success, daftar CS tampil (nama, email, status) & stats', () async {
        await seedAdmin();

        // CS 1 (Active)
        await mockFirestore.collection('users').doc('cs_1').set({
          'fullName': 'CS Agent Budi',
          'email': 'budi@cs.com',
          'role': 'cs',
          'isActive': true,
        });

        // CS 2 (Inactive)
        await mockFirestore.collection('users').doc('cs_2').set({
          'fullName': 'CS Agent Siti',
          'email': 'siti@cs.com',
          'role': 'cs',
          'isActive': false,
        });

        // CS 3 (defaults to true isActive)
        await mockFirestore.collection('users').doc('cs_3').set({
          'fullName': 'CS Agent Andi',
          'email': 'andi@cs.com',
          'role': 'cs',
        });

        // Non-CS User (should be ignored)
        await mockFirestore.collection('users').doc('retailer_1').set({
          'fullName': 'Retailer Budi',
          'email': 'retailer@store.com',
          'role': 'retailer',
          'isActive': true,
        });

        await controller.fetchAllCS();

        // Assert loading finished, no errors
        expect(controller.isLoading, false);
        expect(controller.errorMessage, null);

        // Assert list contains only CS accounts
        expect(controller.csList.length, 3);
        final csIds = controller.csList.map((cs) => cs['id']).toList();
        expect(csIds, containsAll(['cs_1', 'cs_2', 'cs_3']));
        expect(csIds, isNot(contains('retailer_1')));

        // Assert data mappings
        final cs1 = controller.csList.firstWhere((cs) => cs['id'] == 'cs_1');
        expect(cs1['fullName'], 'CS Agent Budi');
        expect(cs1['email'], 'budi@cs.com');
        expect(cs1['isActive'], true);

        final cs2 = controller.csList.firstWhere((cs) => cs['id'] == 'cs_2');
        expect(cs2['isActive'], false);

        // Stats counts
        expect(controller.getActiveCSCount(), 2); // cs_1, cs_3
        expect(controller.getInactiveCSCount(), 1); // cs_2
      });

      test('fetchAllCS sets loading to true during execution', () async {
        await seedAdmin();
        final Future<void> fetchFuture = controller.fetchAllCS();
        expect(controller.isLoading, true);

        await fetchFuture;
        expect(controller.isLoading, false);
      });
    });

    group('Toggle CS Status (TC-32)', () {
      setUp(() async {
        await seedAdmin();
        await mockFirestore.collection('users').doc('cs_target').set({
          'fullName': 'Target CS',
          'email': 'target@cs.com',
          'role': 'cs',
          'isActive': true,
        });
        await controller.fetchAllCS();
      });

      test('TC-32: toggleCSStatus(uid, newStatus) Deactivates a CS staff', () async {
        final result = await controller.toggleCSStatus('cs_target', false);
        expect(result, true);

        // Verify Firestore update
        final doc = await mockFirestore.collection('users').doc('cs_target').get();
        expect(doc.data()?['isActive'], false);
        expect(doc.data()?['updatedAt'], isNotNull);
        expect(doc.data()?['managedBy'], 'admin_uid');

        // Verify local state update
        final localCs = controller.csList.firstWhere((cs) => cs['id'] == 'cs_target');
        expect(localCs['isActive'], false);
        expect(controller.getActiveCSCount(), 0);
        expect(controller.getInactiveCSCount(), 1);
      });

      test('TC-32: toggleCSStatus(uid, newStatus) Activates an inactive CS staff', () async {
        // Set inactive first
        await controller.toggleCSStatus('cs_target', false);
        expect(controller.getActiveCSCount(), 0);

        // Then activate
        final result = await controller.toggleCSStatus('cs_target', true);
        expect(result, true);

        // Verify Firestore update
        final doc = await mockFirestore.collection('users').doc('cs_target').get();
        expect(doc.data()?['isActive'], true);
        expect(doc.data()?['updatedAt'], isNotNull);
        expect(doc.data()?['managedBy'], 'admin_uid');

        // Verify local state update
        final localCs = controller.csList.firstWhere((cs) => cs['id'] == 'cs_target');
        expect(localCs['isActive'], true);
        expect(controller.getActiveCSCount(), 1);
        expect(controller.getInactiveCSCount(), 0);
      });
    });

    group('Add New Customer Support Staff (TC-33)', () {
      late CsUser validCs;

      setUp(() async {
        await seedAdmin();
        validCs = CsUser(
          username: 'Jane CS Agent',
          email: 'jane@cs.com',
          password: 'securePassword123',
          phoneNumber: '081223344556',
          createdAt: DateTime.now(),
        );
      });

      test('TC-33: addNewCs(data) with valid data successfully creates account and updates list', () async {
        final result = await controller.addCS(validCs);
        expect(result, true);
        expect(controller.errorMessage, null);
        expect(controller.isLoading, false);

        // Verify CS profile is saved in Firestore users collection
        final querySnapshot = await mockFirestore
            .collection('users')
            .where('email', isEqualTo: 'jane@cs.com')
            .get();
        expect(querySnapshot.docs.length, 1);
        
        final doc = querySnapshot.docs.first;
        final createdUid = doc.id;
        expect(doc.data()['fullName'], 'Jane CS Agent');
        expect(doc.data()['role'], 'cs');
        expect(doc.data()['phoneNumber'], '081223344556');
        expect(doc.data()['isActive'], true);

        // Verify lists are re-fetched automatically
        expect(controller.csList.any((cs) => cs['id'] == createdUid), true);
        expect(controller.getActiveCSCount(), 1);
      });

      test('addCS sets errorMessage and returns false if Auth registration fails (e.g., email-already-in-use)', () async {
        mockAuth.shouldThrowEmailAlreadyInUse = true;

        final result = await controller.addCS(validCs);
        expect(result, false);
        expect(controller.errorMessage, contains('already in use'));
        expect(controller.isLoading, false);
      });
    });

    group('Role-Based Access Control Checks', () {
      test('fetchAllCS throws exception when user is not authenticated', () async {
        await mockAuth.signOut();
        await controller.fetchAllCS();
        expect(controller.errorMessage, contains('Unauthorized'));
        expect(controller.csList.isEmpty, true);
      });

      test('fetchAllCS throws exception when user is authenticated but not Admin', () async {
        await seedNonAdmin();
        final mockUser = MockUser(uid: 'non_admin_uid', email: 'retailer@email.com');
        final simpleAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
        final badController = AdminCsController(firestore: mockFirestore, auth: simpleAuth);

        await badController.fetchAllCS();
        expect(badController.errorMessage, contains('Unauthorized'));
        expect(badController.csList.isEmpty, true);
      });

      test('toggleCSStatus fails when user is not authenticated', () async {
        await mockAuth.signOut();
        final result = await controller.toggleCSStatus('cs_target', false);
        expect(result, false);
        expect(controller.errorMessage, contains('Unauthorized'));
      });

      test('toggleCSStatus fails when user is authenticated but not Admin', () async {
        await seedNonAdmin();
        final mockUser = MockUser(uid: 'non_admin_uid', email: 'retailer@email.com');
        final simpleAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
        final badController = AdminCsController(firestore: mockFirestore, auth: simpleAuth);

        final result = await badController.toggleCSStatus('cs_target', false);
        expect(result, false);
        expect(badController.errorMessage, contains('Unauthorized'));
      });

      test('addCS fails when user is not authenticated', () async {
        await mockAuth.signOut();
        final validCs = CsUser(
          username: 'Jane CS Agent',
          email: 'jane@cs.com',
          password: 'securePassword123',
          phoneNumber: '081223344556',
          createdAt: DateTime.now(),
        );

        final result = await controller.addCS(validCs);
        expect(result, false);
        expect(controller.errorMessage, contains('Unauthorized'));
      });

      test('addCS fails when user is authenticated but not Admin', () async {
        await seedNonAdmin();
        final mockUser = MockUser(uid: 'non_admin_uid', email: 'retailer@email.com');
        final simpleAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
        final badController = AdminCsController(firestore: mockFirestore, auth: simpleAuth);

        final validCs = CsUser(
          username: 'Jane CS Agent',
          email: 'jane@cs.com',
          password: 'securePassword123',
          phoneNumber: '081223344556',
          createdAt: DateTime.now(),
        );

        final result = await badController.addCS(validCs);
        expect(result, false);
        expect(badController.errorMessage, contains('Unauthorized'));
      });
    });

    group('Error Paths & Firestore Exceptions', () {
      test('fetchAllCS sets errorMessage when Firestore query fails', () async {
        await seedAdmin();
        final badFirestore = MockFirestoreCustomException();
        final badController = AdminCsController(firestore: badFirestore, auth: mockAuth);

        await badController.fetchAllCS();
        expect(badController.isLoading, false);
        expect(badController.errorMessage, contains('Firestore query failed'));
      });

      test('toggleCSStatus returns false and sets errorMessage when Firestore update fails', () async {
        await seedAdmin();
        final badFirestore = MockFirestoreCustomException();
        final badController = AdminCsController(firestore: badFirestore, auth: mockAuth);

        final result = await badController.toggleCSStatus('cs_target', false);
        expect(result, false);
        expect(badController.isLoading, false);
        expect(badController.errorMessage, contains('Failed to update status'));
      });

      test('addCS returns false and sets errorMessage when Firestore write fails', () async {
        await seedAdmin();
        final badFirestore = MockFirestoreCustomException();
        final badController = AdminCsController(firestore: badFirestore, auth: mockAuth);

        final validCs = CsUser(
          username: 'Jane CS Agent',
          email: 'jane@cs.com',
          password: 'securePassword123',
          phoneNumber: '081223344556',
          createdAt: DateTime.now(),
        );

        final result = await badController.addCS(validCs);
        expect(result, false);
        expect(badController.isLoading, false);
        expect(badController.errorMessage, contains('Firestore query failed'));
      });
    });
  });
}

// Custom MockFirebaseAuth to bypass signing-out admin user upon newUser registration
class MockAdminFirebaseAuth extends MockFirebaseAuth {
  final MockUser _adminUser;
  bool _signedIn = true;
  bool shouldThrowEmailAlreadyInUse = false;

  MockAdminFirebaseAuth(this._adminUser) : super(mockUser: _adminUser, signedIn: true);

  @override
  User? get currentUser => _signedIn ? _adminUser : null;

  @override
  Future<void> signOut() async {
    _signedIn = false;
  }

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (shouldThrowEmailAlreadyInUse) {
      throw FirebaseAuthException(
        code: 'email-already-in-use',
        message: 'The email address is already in use by another account.',
      );
    }
    final newMockUser = MockUser(uid: 'new_cs_uid', email: email);
    return MockUserCredential(newMockUser);
  }
}

class MockUserCredential extends Fake implements UserCredential {
  final User _user;
  MockUserCredential(this._user);

  @override
  User? get user => _user;
}

// Custom mock class to simulate Firestore query exception
class MockFirestoreCustomException extends FakeFirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    throw Exception('Firestore query failed');
  }
}
