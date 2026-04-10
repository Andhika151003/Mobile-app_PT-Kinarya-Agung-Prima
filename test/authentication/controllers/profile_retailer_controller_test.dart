import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:ecommerce/features/authentication/controllers/profile_user_controller.dart';

void main() {
  late RetailProfileController retailController;
  late MockFirebaseAuth mockAuth;
  late FakeFirebaseFirestore fakeFirestore;
  late MockUser mockUser;

  setUp(() {
    mockUser = MockUser(
      isAnonymous: false,
      uid: 'retail123',
      email: 'retail@test.com',
      displayName: 'Test Retail',
    );
    mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
    fakeFirestore = FakeFirebaseFirestore();

    retailController = RetailProfileController(
      auth: mockAuth,
      firestore: fakeFirestore,
    );
  });

  group('RetailProfileController Tests', () {
    test('getRetailProfile returns data when document exists', () async {
      await fakeFirestore.collection('users').doc('retail123').set({
        'fullName': 'Toko ABC',
        'address': 'Jl. Mawar',
      });

      final data = await retailController.getRetailProfile();
      
      expect(data, isNotNull);
      expect(data!['fullName'], equals('Toko ABC'));
      expect(data['uid'], equals('retail123'));
    });

    test('getRetailProfile returns null when document does not exist', () async {
      final data = await retailController.getRetailProfile();
      expect(data, isNull);
    });

    test('updateRetailProfile updates firestore data correctly without image', () async {
      // Setup initial document to avoid error on update if it doesn't exist 
      // (Firestore update fails if doc doesn't exist, though typically the user doc exists in production)
      await fakeFirestore.collection('users').doc('retail123').set({
        'fullName': 'Old Name',
      });

      await retailController.updateRetailProfile(
        storeName: 'New Store',
        location: 'New Location',
        contact: '08123456789',
        businessType: 'Retail',
        profileImage: null, // Kita test tanpa gambar supaya tidak tembus ke Supabase
      );

      final doc = await fakeFirestore.collection('users').doc('retail123').get();
      expect(doc.data()!['fullName'], equals('New Store'));
      expect(doc.data()!['address'], equals('New Location'));
      expect(doc.data()!['phoneNumber'], equals('08123456789'));
      expect(doc.data()!['businessType'], equals('Retail'));
    });

    test('updateStoreStatus updates isActive field correctly', () async {
      await fakeFirestore.collection('users').doc('retail123').set({
        'isActive': false,
      });

      await retailController.updateStoreStatus(true);

      final doc = await fakeFirestore.collection('users').doc('retail123').get();
      expect(doc.data()!['isActive'], equals(true));
    });
  });
}
