import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:ecommerce/features/authentication/controllers/profile_admin_controller.dart';

void main() {
  late AdminProfileController adminController;
  late MockFirebaseAuth mockAuth;
  late FakeFirebaseFirestore fakeFirestore;
  late MockUser mockUser;

  setUp(() {
    mockUser = MockUser(
      isAnonymous: false,
      uid: 'admin123',
      email: 'admin@test.com',
      displayName: 'Test Admin',
    );
    mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
    fakeFirestore = FakeFirebaseFirestore();

    adminController = AdminProfileController(
      auth: mockAuth,
      firestore: fakeFirestore,
    );
  });

  group('AdminProfileController Tests', () {
    test('getAdminProfile returns data when document exists', () async {
      await fakeFirestore.collection('users').doc('admin123').set({
        'fullName': 'Admin Super',
        'address': 'Office 123',
        'role': 'Admin',
      });

      final data = await adminController.getAdminProfile();
      
      expect(data, isNotNull);
      expect(data!['fullName'], equals('Admin Super'));
      expect(data['uid'], equals('admin123'));
    });

    test('getAdminProfile returns null when document does not exist', () async {
      final data = await adminController.getAdminProfile();
      expect(data, isNull);
    });

    test('updateAdminProfile updates all fields in firestore', () async {
      await fakeFirestore.collection('users').doc('admin123').set({
        'fullName': 'Old Admin',
      });

      await adminController.updateAdminProfile(
        fullName: 'New Admin',
        address: 'New HQ',
        phoneNumber: '08123456789',
        businessType: 'Distributor',
        bankAccount: '12345678',
        bankName: 'BCA',
      );

      final doc = await fakeFirestore.collection('users').doc('admin123').get();
      final updatedData = doc.data()!;
      expect(updatedData['fullName'], equals('New Admin'));
      expect(updatedData['address'], equals('New HQ'));
      expect(updatedData['phoneNumber'], equals('08123456789'));
      expect(updatedData['businessType'], equals('Distributor'));
      expect(updatedData['bankAccount'], equals('12345678'));
      expect(updatedData['bankName'], equals('BCA'));
    });
  });
}
