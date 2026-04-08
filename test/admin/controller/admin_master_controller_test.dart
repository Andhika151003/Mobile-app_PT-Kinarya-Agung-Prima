import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:ecommerce/features/admin/controller/admin_master_controller.dart';

void main() {
  late AdminMasterController adminController;
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

    adminController = AdminMasterController(
      firestore: fakeFirestore,
      auth: mockAuth,
    );
  });

  group('AdminMasterController Tests', () {
    test('fetchAllRetailers gets only users with role retailer', () async {
      await fakeFirestore.collection('users').add({'role': 'retailer', 'fullName': 'Toko A', 'email': 'a@toko.com', 'isActive': true});
      await fakeFirestore.collection('users').add({'role': 'retailer', 'fullName': 'Toko B', 'email': 'b@toko.com', 'isActive': false});
      await fakeFirestore.collection('users').add({'role': 'admin', 'fullName': 'Super Admin', 'email': 'admin@test.com'});

      await adminController.fetchAllRetailers();
      
      expect(adminController.retailers.length, equals(2));
      expect(adminController.filteredRetailers.length, equals(2));
      expect(adminController.getActiveRetailersCount(), equals(1));
      expect(adminController.getInactiveRetailersCount(), equals(1));
      expect(adminController.getTotalRetailersCount(), equals(2));
    });

    test('searchRetailers correctly filters retailers by name and email', () async {
      await fakeFirestore.collection('users').add({'role': 'retailer', 'fullName': 'Toko Maju', 'email': 'maju@toko.com'});
      await fakeFirestore.collection('users').add({'role': 'retailer', 'fullName': 'Toko Mundur', 'email': 'mundur@toko.com'});

      await adminController.fetchAllRetailers();
      
      adminController.searchRetailers('maju');
      expect(adminController.filteredRetailers.length, equals(1));
      expect(adminController.filteredRetailers.first['fullName'], equals('Toko Maju'));

      adminController.searchRetailers('mundur@');
      expect(adminController.filteredRetailers.length, equals(1));
      expect(adminController.filteredRetailers.first['email'], equals('mundur@toko.com'));

      adminController.searchRetailers('jaya');
      expect(adminController.filteredRetailers, isEmpty);
      
      adminController.searchRetailers('');
      expect(adminController.filteredRetailers.length, equals(2));
    });

    test('getRetailerById returns correct data', () async {
      final doc = await fakeFirestore.collection('users').add({'role': 'retailer', 'fullName': 'Toko A'});
      await adminController.fetchAllRetailers();

      final data = adminController.getRetailerById(doc.id);
      expect(data, isNotNull);
      expect(data!['fullName'], equals('Toko A'));

      final invalidData = adminController.getRetailerById('invalid_id');
      expect(invalidData, isNull);
    });

    test('disableRetailer changes isActive to false', () async {
      final doc = await fakeFirestore.collection('users').add({'role': 'retailer', 'fullName': 'Toko A', 'isActive': true});
      await adminController.fetchAllRetailers();

      final result = await adminController.disableRetailer(doc.id);
      expect(result, isTrue);

      final updatedDoc = await fakeFirestore.collection('users').doc(doc.id).get();
      expect(updatedDoc.data()!['isActive'], isFalse);
      expect(updatedDoc.data()!['disabledBy'], equals('admin123'));
      expect(updatedDoc.data()!['disabledAt'], isNotNull);
      
      final localData = adminController.getRetailerById(doc.id);
      expect(localData!['isActive'], isFalse);
    });

    test('enableRetailer changes isActive to true', () async {
      final doc = await fakeFirestore.collection('users').add({'role': 'retailer', 'fullName': 'Toko B', 'isActive': false});
      await adminController.fetchAllRetailers();

      final result = await adminController.enableRetailer(doc.id);
      expect(result, isTrue);

      final updatedDoc = await fakeFirestore.collection('users').doc(doc.id).get();
      expect(updatedDoc.data()!['isActive'], isTrue);
      expect(updatedDoc.data()!['activatedBy'], equals('admin123'));
      expect(updatedDoc.data()!['activatedAt'], isNotNull);

      final localData = adminController.getRetailerById(doc.id);
      expect(localData!['isActive'], isTrue);
    });

    test('deleteRetailer removes document and updates local list', () async {
      final doc = await fakeFirestore.collection('users').add({'role': 'retailer', 'fullName': 'Toko C'});
      await adminController.fetchAllRetailers();

      final result = await adminController.deleteRetailer(doc.id);
      expect(result, isTrue);

      final deletedDoc = await fakeFirestore.collection('users').doc(doc.id).get();
      expect(deletedDoc.exists, isFalse);

      final localData = adminController.getRetailerById(doc.id);
      expect(localData, isNull);
      expect(adminController.retailers.length, equals(0));
    });
  });
}
