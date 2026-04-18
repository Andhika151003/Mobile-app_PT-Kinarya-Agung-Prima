import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:ecommerce/features/authentication/controllers/profile_user_controller.dart';

void main() {
  late RetailProfileController profileController;
  late MockFirebaseAuth mockAuth;
  late FakeFirebaseFirestore fakeFirestore;
  late MockUser mockUser;

  setUp(() {
    mockUser = MockUser(
      isAnonymous: false,
      uid: 'user123',
      email: 'user@test.com',
      displayName: 'Test Retail',
    );
    mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
    fakeFirestore = FakeFirebaseFirestore();

    profileController = RetailProfileController(
      auth: mockAuth,
      firestore: fakeFirestore,
    );
  });

  group('RetailProfileController Tests', () {
    test('getRetailProfile returns data when user exists in firestore', () async {
      await fakeFirestore.collection('users').doc('user123').set({
        'fullName': 'Toko Maju',
        'address': 'Jl. Makmur 1',
      });

      final data = await profileController.getRetailProfile();
      
      expect(data, isNotNull);
      expect(data!['fullName'], equals('Toko Maju'));
      expect(data['uid'], equals('user123'));
    });

    test('getRetailProfile returns null when document does not exist', () async {
      final data = await profileController.getRetailProfile();
      expect(data, isNull);
    });

    test('updateRetailProfile updates user data in firestore', () async {
      await fakeFirestore.collection('users').doc('user123').set({
        'fullName': 'Old Name',
      });

      await profileController.updateRetailProfile(
        storeName: 'New Toko',
        location: 'New Location',
        contact: '08123456789',
        businessType: 'Retail Store',
      );

      final doc = await fakeFirestore.collection('users').doc('user123').get();
      expect(doc.data()!['fullName'], equals('New Toko'));
      expect(doc.data()!['address'], equals('New Location'));
      expect(doc.data()!['phoneNumber'], equals('08123456789'));
      expect(doc.data()!['businessType'], equals('Retail Store'));
    });

    test('updateStoreStatus updates isActive field', () async {
      await fakeFirestore.collection('users').doc('user123').set({
        'isActive': false,
      });

      await profileController.updateStoreStatus(true);

      final doc = await fakeFirestore.collection('users').doc('user123').get();
      expect(doc.data()!['isActive'], isTrue);
    });
  });
}
