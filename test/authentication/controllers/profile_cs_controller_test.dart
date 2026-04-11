import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:ecommerce/features/authentication/controllers/profile_cs_controller.dart';

void main() {
  late ProfileCsController csController;
  late MockFirebaseAuth mockAuth;
  late FakeFirebaseFirestore fakeFirestore;
  late MockUser mockUser;

  setUp(() {
    mockUser = MockUser(
      isAnonymous: false,
      uid: 'cs123',
      email: 'cs@test.com',
      displayName: 'Test CS',
    );
    mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
    fakeFirestore = FakeFirebaseFirestore();

    csController = ProfileCsController(
      auth: mockAuth,
      firestore: fakeFirestore,
    );
  });

  group('ProfileCsController Tests', () {
    test('getCsProfile returns data when document exists', () async {
      await fakeFirestore.collection('users').doc('cs123').set({
        'fullName': 'Agus CS',
        'address': 'Call Center Bandung',
      });

      final data = await csController.getCsProfile();
      
      expect(data, isNotNull);
      expect(data!['fullName'], equals('Agus CS'));
      expect(data['uid'], equals('cs123'));
    });

    test('getCsProfile returns null when document does not exist', () async {
      final data = await csController.getCsProfile();
      expect(data, isNull);
    });
  });
}
