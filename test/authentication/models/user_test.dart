import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerce/features/authentication/models/user.dart';
import 'package:ecommerce/features/authentication/models/admin.dart';
import 'package:ecommerce/features/authentication/models/cs.dart';
import 'package:ecommerce/features/authentication/models/retailer.dart';

void main() {
  group('BaseUser Polymorphic Tests', () {
    test('fromMap returns AdminUser if role is admin', () {
      final map = {
        'username': 'Admin Mirza',
        'email': 'admin@mail.com',
        'role': 'admin',
        'accessLevel': 5,
      };

      final user = BaseUser.fromMap('user-001', map);

      expect(user is AdminUser, true);
      expect((user as AdminUser).accessLevel, 5);
      expect(user.role, 'admin');
    });

    test('fromMap returns CsUser if role is cs', () {
      final map = {
        'username': 'CS Andi',
        'email': 'cs@mail.com',
        'role': 'cs',
        'department': 'Support',
      };

      final user = BaseUser.fromMap('user-002', map);

      expect(user is CsUser, true);
      expect((user as CsUser).department, 'Support');
    });

    test('fromMap returns RetailerUser if role is retailer or missing', () {
      final map = {
        'username': 'Toko ABC',
        'email': 'toko@abc.com',
        // tanpa role explicit
      };

      final user = BaseUser.fromMap('user-003', map);

      expect(user is RetailerUser, true);
      expect(user.role, 'retailer'); // Default role fallback
    });

    test('toMap converts RetailerUser correctly', () {
      final retailer = RetailerUser(
        id: '123',
        username: 'Budi',
        email: 'budi@mail.com',
        password: 'pass',
        phoneNumber: '0812',
        address: 'Bandung',
        createdAt: DateTime.now(),
      );

      final map = retailer.toMap();
      expect(map['id'], '123');
      expect(map['role'], 'retailer');
      expect(map['address'], 'Bandung');
      expect(map.containsKey('fullName'), true);
    });
  });
} 
