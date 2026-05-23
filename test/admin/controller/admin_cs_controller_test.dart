import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ecommerce/features/admin/controller/admin_cs_controller.dart';
import 'package:ecommerce/features/authentication/models/cs.dart';

class MockFirebaseAuthWithMocktail extends Mock implements FirebaseAuth {}
class MockUserFromMocktail extends Mock implements User {}

void main() {
  late AdminCsController adminCsController;
  late MockFirebaseAuth mockAuth;
  late FakeFirebaseFirestore fakeFirestore;
  late MockUser mockAdminUser;

  setUpAll(() {
    registerFallbackValue(MockUserFromMocktail());
  });

  setUp(() async {
    mockAdminUser = MockUser(
      isAnonymous: false,
      uid: 'admin123',
      email: 'admin@test.com',
    );
    mockAuth = MockFirebaseAuth(mockUser: mockAdminUser, signedIn: true);
    fakeFirestore = FakeFirebaseFirestore();

    // Setup admin record in Firestore for security validation
    await fakeFirestore.collection('users').doc('admin123').set({
      'role': 'admin',
      'username': 'Admin User',
      'email': 'admin@test.com',
    });

    adminCsController = AdminCsController(
      firestore: fakeFirestore,
      auth: mockAuth,
    );
  });

  group('AdminCsController Enhanced Tests', () {
    test('addCS creates user in Auth and Firestore with correct UID', () async {
      final newCS = CsUser(
        username: 'Auth CS',
        email: 'auth_cs@test.com',
        password: 'password123',
        phoneNumber: '111222',
        createdAt: DateTime.now(),
      );

      final result = await adminCsController.addCS(newCS);
      expect(result, isTrue);

      final snapshot = await fakeFirestore.collection('users').where('role', isEqualTo: 'cs').get();
      expect(snapshot.docs.length, equals(1));
      expect(snapshot.docs.first.data()['email'], equals('auth_cs@test.com'));
      expect(snapshot.docs.first.id, isNotEmpty);
    });

    test('Skenario Negatif: Duplikasi Email pada addCS', () async {
      final mockAuthForError = MockFirebaseAuthWithMocktail();
      final controller = AdminCsController(firestore: fakeFirestore, auth: mockAuthForError);
      
      final mockAdmin = MockUserFromMocktail();
      when(() => mockAdmin.uid).thenReturn('admin123');
      when(() => mockAuthForError.currentUser).thenReturn(mockAdmin);
      
      final cs = CsUser(
        username: 'Duplicate',
        email: 'duplicate@test.com',
        password: 'password123',
        phoneNumber: '123',
        createdAt: DateTime.now(),
      );
      
      when(() => mockAuthForError.createUserWithEmailAndPassword(
        email: cs.email,
        password: any(named: 'password'),
      )).thenThrow(FirebaseAuthException(code: 'email-already-in-use', message: 'The email address is already in use by another account.'));

      final result = await controller.addCS(cs);
      
      expect(result, isFalse);
      expect(controller.errorMessage, contains('already in use'));
    });

    test('Validasi Keamanan: Gagal addCS jika bukan Admin', () async {
      final regularUser = MockUser(uid: 'user456', email: 'user@test.com');
      final regularAuth = MockFirebaseAuth(mockUser: regularUser, signedIn: true);
      
      final controller = AdminCsController(firestore: fakeFirestore, auth: regularAuth);
      
      final newCS = CsUser(
        username: 'Should Fail',
        email: 'fail@test.com',
        password: 'password123',
        phoneNumber: '000',
        createdAt: DateTime.now(),
      );

      final result = await controller.addCS(newCS);
      
      expect(result, isFalse);
      expect(controller.errorMessage, contains('Unauthorized'));
    });

    test('toggleCSStatus updates record and handles security', () async {
      final docRef = await fakeFirestore.collection('users').add({
        'role': 'cs',
        'username': 'Target CS',
        'isActive': true,
      });

      final result = await adminCsController.toggleCSStatus(docRef.id, false);
      expect(result, isTrue);

      final doc = await fakeFirestore.collection('users').doc(docRef.id).get();
      expect(doc.data()!['isActive'], isFalse);
      expect(doc.data()!['managedBy'], equals('admin123'));
    });

    test('Validasi Keamanan: Gagal toggleCSStatus jika bukan Admin', () async {
      final regularUser = MockUser(uid: 'user456', email: 'user@test.com');
      final regularAuth = MockFirebaseAuth(mockUser: regularUser, signedIn: true);
      final controller = AdminCsController(firestore: fakeFirestore, auth: regularAuth);

      final result = await controller.toggleCSStatus('any_id', false);
      expect(result, isFalse);
      expect(controller.errorMessage, contains('Unauthorized'));
    });
  });
}
