import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:ecommerce/features/admin/controller/admin_master_controller.dart';

void main() {
  group('AdminMasterController Unit Tests (Whitebox)', () {
    late MockFirebaseAuth mockAuth;
    late FakeFirebaseFirestore mockFirestore;
    late AdminMasterController controller;

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
      mockAuth = MockFirebaseAuth(mockUser: mockAdminUser, signedIn: true);
      mockFirestore = FakeFirebaseFirestore();
      controller = AdminMasterController(auth: mockAuth, firestore: mockFirestore);
    });

    group('Fetch Retailers & Statistics (TC-34)', () {
      test('TC-34: fetchAllRetailers() -> success, daftar retailer tampil dengan total retailers & stats', () async {
        // 1. Seed database with admin user and some retailers/non-retailers
        await seedAdmin();
        
        // Retailer 1 (active)
        await mockFirestore.collection('users').doc('ret_1').set({
          'fullName': 'Budi Store',
          'email': 'budi@store.com',
          'role': 'retailer',
          'isActive': true,
        });

        // Retailer 2 (inactive)
        await mockFirestore.collection('users').doc('ret_2').set({
          'fullName': 'Siti Shop',
          'email': 'siti@shop.com',
          'role': 'retailer',
          'isActive': false,
        });

        // Retailer 3 (no isActive flag - defaults to true)
        await mockFirestore.collection('users').doc('ret_3').set({
          'fullName': 'Andi Retail',
          'email': 'andi@retail.com',
          'role': 'retailer',
        });

        // Customer Support (should be excluded)
        await mockFirestore.collection('users').doc('cs_1').set({
          'fullName': 'Support CS',
          'email': 'cs@company.com',
          'role': 'cs',
          'isActive': true,
        });

        // 2. Execute fetchAllRetailers
        await controller.fetchAllRetailers();

        // 3. Assert loading state transitioned correctly
        expect(controller.isLoading, false);
        expect(controller.errorMessage, null);

        // 4. Assert retailers list has only the 3 retailer users
        expect(controller.retailers.length, 3);
        expect(controller.filteredRetailers.length, 3);

        // Verify mapped data attributes
        final retailerIds = controller.retailers.map((r) => r['id']).toList();
        expect(retailerIds, containsAll(['ret_1', 'ret_2', 'ret_3']));
        expect(retailerIds, isNot(contains('cs_1')));

        // Verify default isActive logic
        final ret3 = controller.retailers.firstWhere((r) => r['id'] == 'ret_3');
        expect(ret3['isActive'], true);

        // 5. Assert statistics counts
        expect(controller.getTotalRetailersCount(), 3);
        expect(controller.getActiveRetailersCount(), 2); // ret_1 and ret_3
        expect(controller.getInactiveRetailersCount(), 1); // ret_2
      });

      test('fetchAllRetailers clears previous errors and updates loading state', () async {
        await seedAdmin();
        
        // Simulating starting action
        final Future<void> fetchFuture = controller.fetchAllRetailers();
        expect(controller.isLoading, true);

        await fetchFuture;
        expect(controller.isLoading, false);
      });
    });

    group('Search Retailers (TC-35)', () {
      setUp(() async {
        await seedAdmin();
        await mockFirestore.collection('users').doc('retailer_john').set({
          'fullName': 'John Doe Store',
          'email': 'john@doe.com',
          'role': 'retailer',
          'isActive': true,
        });
        await mockFirestore.collection('users').doc('retailer_mary').set({
          'fullName': 'Mary Jane Shop',
          'email': 'mj@example.com',
          'role': 'retailer',
          'isActive': true,
        });
        await controller.fetchAllRetailers();
      });

      test('TC-35: searchRetailers(keyword) with exact name match (case-insensitive)', () {
        controller.searchRetailers('JOHN');
        expect(controller.filteredRetailers.length, 1);
        expect(controller.filteredRetailers.first['id'], 'retailer_john');

        controller.searchRetailers('mary');
        expect(controller.filteredRetailers.length, 1);
        expect(controller.filteredRetailers.first['id'], 'retailer_mary');
      });

      test('TC-35: searchRetailers(keyword) with partial name match', () {
        controller.searchRetailers('Jane');
        expect(controller.filteredRetailers.length, 1);
        expect(controller.filteredRetailers.first['id'], 'retailer_mary');

        controller.searchRetailers('Store');
        expect(controller.filteredRetailers.length, 1);
        expect(controller.filteredRetailers.first['id'], 'retailer_john');
      });

      test('TC-35: searchRetailers(keyword) with partial email match', () {
        controller.searchRetailers('doe.com');
        expect(controller.filteredRetailers.length, 1);
        expect(controller.filteredRetailers.first['id'], 'retailer_john');

        controller.searchRetailers('example');
        expect(controller.filteredRetailers.length, 1);
        expect(controller.filteredRetailers.first['id'], 'retailer_mary');
      });

      test('TC-35: searchRetailers(keyword) with formatted ID match', () {
        // UID: 'retailer_john' -> formatted ID: '#KNYRETAIL' (first 6 chars of uid capitalized: RETAIL)
        // UID: 'retailer_mary' -> formatted ID: '#KNYRETAIL' (first 6 chars of uid capitalized: RETAIL)
        // Let's verify searching for formatted ID
        controller.searchRetailers('#KNYRETAIL');
        expect(controller.filteredRetailers.length, 2);

        // If searching a specific sub-string of formatted ID
        controller.searchRetailers('retail');
        expect(controller.filteredRetailers.length, 2);
      });

      test('TC-35: searchRetailers(keyword) returns empty list when no matches found', () {
        controller.searchRetailers('NonExistentName');
        expect(controller.filteredRetailers.isEmpty, true);
      });

      test('TC-35: searchRetailers(keyword) resets to all retailers when query is empty', () {
        controller.searchRetailers('john');
        expect(controller.filteredRetailers.length, 1);

        controller.searchRetailers('');
        expect(controller.filteredRetailers.length, 2);
      });
    });

    group('Filter Retailers by Status (TC-36)', () {
      setUp(() async {
        await seedAdmin();
        await mockFirestore.collection('users').doc('active_1').set({
          'fullName': 'Active Shop 1',
          'role': 'retailer',
          'isActive': true,
        });
        await mockFirestore.collection('users').doc('inactive_1').set({
          'fullName': 'Inactive Shop 1',
          'role': 'retailer',
          'isActive': false,
        });
        await controller.fetchAllRetailers();
      });

      test('TC-36: filterRetailersByStatus(active/inactive) filters lists as in the View', () {
        final allRetailers = controller.filteredRetailers;
        
        // Active Filter simulation
        final activeList = allRetailers.where((r) => r['isActive'] == true).toList();
        expect(activeList.length, 1);
        expect(activeList.first['id'], 'active_1');

        // Inactive Filter simulation
        final inactiveList = allRetailers.where((r) => r['isActive'] == false).toList();
        expect(inactiveList.length, 1);
        expect(inactiveList.first['id'], 'inactive_1');
      });
    });

    group('Update Retailer Status (TC-37) & Deletion', () {
      setUp(() async {
        await seedAdmin();
        await mockFirestore.collection('users').doc('ret_target').set({
          'fullName': 'Target Retailer',
          'role': 'retailer',
          'isActive': true,
        });
        await controller.fetchAllRetailers();
      });

      test('TC-37: disableRetailer(retailerId) updates Firestore and local state', () async {
        final result = await controller.disableRetailer('ret_target');
        expect(result, true);

        // Verify Firestore update
        final doc = await mockFirestore.collection('users').doc('ret_target').get();
        expect(doc.data()?['isActive'], false);
        expect(doc.data()?['disabledAt'], isNotNull);
        expect(doc.data()?['disabledBy'], 'admin_uid');

        // Verify local state update
        final localRetailer = controller.retailers.firstWhere((r) => r['id'] == 'ret_target');
        expect(localRetailer['isActive'], false);
        expect(controller.getInactiveRetailersCount(), 1);
        expect(controller.getActiveRetailersCount(), 0);
      });

      test('TC-37: enableRetailer(retailerId) updates Firestore and local state', () async {
        // Disable first
        await controller.disableRetailer('ret_target');
        expect(controller.getActiveRetailersCount(), 0);

        // Then enable
        final result = await controller.enableRetailer('ret_target');
        expect(result, true);

        // Verify Firestore update
        final doc = await mockFirestore.collection('users').doc('ret_target').get();
        expect(doc.data()?['isActive'], true);
        expect(doc.data()?['activatedAt'], isNotNull);
        expect(doc.data()?['activatedBy'], 'admin_uid');

        // Verify local state update
        final localRetailer = controller.retailers.firstWhere((r) => r['id'] == 'ret_target');
        expect(localRetailer['isActive'], true);
        expect(controller.getActiveRetailersCount(), 1);
        expect(controller.getInactiveRetailersCount(), 0);
      });

      test('deleteRetailer(retailerId) removes retailer from Firestore and local state', () async {
        final result = await controller.deleteRetailer('ret_target');
        expect(result, true);

        // Verify Firestore deletion
        final doc = await mockFirestore.collection('users').doc('ret_target').get();
        expect(doc.exists, false);

        // Verify local state update
        expect(controller.retailers.any((r) => r['id'] == 'ret_target'), false);
        expect(controller.getTotalRetailersCount(), 0);
      });

      test('getRetailerById returns correct retailer or null if not found', () {
        final retailer = controller.getRetailerById('ret_target');
        expect(retailer, isNotNull);
        expect(retailer!['fullName'], 'Target Retailer');

        final nonExistent = controller.getRetailerById('non_existent');
        expect(nonExistent, null);
      });
    });

    group('Role-Based Access Control', () {
      test('fetchAllRetailers throws exception when user is not authenticated', () async {
        // Sign out
        await mockAuth.signOut();

        await controller.fetchAllRetailers();
        expect(controller.errorMessage, contains('Unauthorized'));
        expect(controller.retailers.isEmpty, true);
      });

      test('fetchAllRetailers throws exception when user is authenticated but not Admin', () async {
        // Log in as retailer/non-admin
        await seedNonAdmin();
        final mockUser = MockUser(uid: 'non_admin_uid', email: 'retailer@email.com');
        mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);

        await controller.fetchAllRetailers();
        expect(controller.errorMessage, contains('Unauthorized'));
        expect(controller.retailers.isEmpty, true);
      });

      test('disableRetailer fails when user is not authenticated', () async {
        await mockAuth.signOut();
        final result = await controller.disableRetailer('some_id');
        expect(result, false);
        expect(controller.errorMessage, contains('Unauthorized'));
      });

      test('disableRetailer fails when user is authenticated but not Admin', () async {
        await seedNonAdmin();
        final mockUser = MockUser(uid: 'non_admin_uid', email: 'retailer@email.com');
        mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);

        final result = await controller.disableRetailer('some_id');
        expect(result, false);
        expect(controller.errorMessage, contains('Unauthorized'));
      });

      test('enableRetailer fails when user is not authenticated', () async {
        await mockAuth.signOut();
        final result = await controller.enableRetailer('some_id');
        expect(result, false);
        expect(controller.errorMessage, contains('Unauthorized'));
      });

      test('enableRetailer fails when user is authenticated but not Admin', () async {
        await seedNonAdmin();
        final mockUser = MockUser(uid: 'non_admin_uid', email: 'retailer@email.com');
        mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);

        final result = await controller.enableRetailer('some_id');
        expect(result, false);
        expect(controller.errorMessage, contains('Unauthorized'));
      });

      test('deleteRetailer fails when user is not authenticated', () async {
        await mockAuth.signOut();
        final result = await controller.deleteRetailer('some_id');
        expect(result, false);
        expect(controller.errorMessage, contains('Unauthorized'));
      });

      test('deleteRetailer fails when user is authenticated but not Admin', () async {
        await seedNonAdmin();
        final mockUser = MockUser(uid: 'non_admin_uid', email: 'retailer@email.com');
        mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);

        final result = await controller.deleteRetailer('some_id');
        expect(result, false);
        expect(controller.errorMessage, contains('Unauthorized'));
      });
    });

    group('Error Paths & Firestore Exceptions', () {
      test('fetchAllRetailers sets errorMessage and isLoading is false when Firestore query fails', () async {
        await seedAdmin();
        final badFirestore = MockFirestoreCustomException();
        final badController = AdminMasterController(auth: mockAuth, firestore: badFirestore);

        await badController.fetchAllRetailers();
        expect(badController.isLoading, false);
        expect(badController.errorMessage, contains('Gagal mengambil data'));
      });

      test('disableRetailer returns false and sets errorMessage when Firestore update fails', () async {
        await seedAdmin();
        final badFirestore = MockFirestoreCustomException();
        final badController = AdminMasterController(auth: mockAuth, firestore: badFirestore);

        final result = await badController.disableRetailer('some_id');
        expect(result, false);
        expect(badController.isLoading, false);
        expect(badController.errorMessage, contains('Gagal menonaktifkan'));
      });

      test('enableRetailer returns false and sets errorMessage when Firestore update fails', () async {
        await seedAdmin();
        final badFirestore = MockFirestoreCustomException();
        final badController = AdminMasterController(auth: mockAuth, firestore: badFirestore);

        final result = await badController.enableRetailer('some_id');
        expect(result, false);
        expect(badController.isLoading, false);
        expect(badController.errorMessage, contains('Gagal mengaktifkan'));
      });

      test('deleteRetailer returns false and sets errorMessage when Firestore delete fails', () async {
        await seedAdmin();
        final badFirestore = MockFirestoreCustomException();
        final badController = AdminMasterController(auth: mockAuth, firestore: badFirestore);

        final result = await badController.deleteRetailer('some_id');
        expect(result, false);
        expect(badController.isLoading, false);
        expect(badController.errorMessage, contains('Gagal menghapus'));
      });
    });
  });
}

// Custom mock class to simulate Firestore queries throwing exceptions
class MockFirestoreCustomException extends FakeFirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    throw Exception('Firestore query failed');
  }
}
