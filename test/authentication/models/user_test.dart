import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerce/features/authentication/models/user.dart';

void main() {
  group('User Model Tests', () {
    test('toMap harus mengonversi object User menjadi Map Firebase', () {
      final user = User(
        userId: 'user-001',
        username: 'Mirza',
        email: 'mirza@mail.com',
        password: 'password123',
        role: 'customer',
        phoneNumber: '08111222333',
      );

      final map = user.toMap();

      expect(map['userId'], 'user-001');
      expect(map['username'], 'Mirza');
      expect(map['email'], 'mirza@mail.com');
      expect(map['role'], 'customer');
      expect(map['phoneNumber'], '08111222333');
      expect(map['createdAt'], isNotNull);
      expect(map.containsKey('password'), false);
    });

    test('fromMap harus membuat object User dari data Map Firebase', () {
      final mapFromFirebase = {
        'username': 'Siti',
        'email': 'siti@mail.com',
        'role': 'admin',
        'phoneNumber': '08555666777',
      };

      final user = User.fromMap('doc-789', mapFromFirebase);

      expect(user.userId, 'doc-789');
      expect(user.username, 'Siti');
      expect(user.email, 'siti@mail.com');
      expect(user.password, '');
      expect(user.role, 'admin');
      expect(user.phoneNumber, '08555666777');
    });

    test(
      'fromMap harus memberikan role default jika tidak ada di Firebase',
      () {
        final mapTanpaRole = {'username': 'Budi', 'email': 'budi@mail.com'};

        final user = User.fromMap('doc-101', mapTanpaRole);

        expect(user.role, 'retailer');
      },
    );
  });
}
