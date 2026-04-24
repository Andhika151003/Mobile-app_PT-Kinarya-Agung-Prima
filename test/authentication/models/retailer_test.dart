import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerce/features/authentication/models/retailer.dart';

void main() {
  group('RetailerUser Model Tests', () {
    final testDate = DateTime(2026, 4, 8, 10, 0, 0);

    test('toMap harus mengonversi object RetailerUser menjadi Map Firebase', () {
      final retailer = RetailerUser(
        id: 'retailer-123',
        username: 'Amirul',
        email: 'amirul@mail.com',
        password: 'passwordRahasia',
        phoneNumber: '08123456789',
        address: 'Surabaya',
        createdAt: testDate,
      );

      final map = retailer.toMap();

      expect(map['id'], 'retailer-123');
      expect(map['username'], 'Amirul');
      expect(map['fullName'], 'Amirul');
      expect(map['email'], 'amirul@mail.com');
      expect(map['phoneNumber'], '08123456789');
      expect(map['address'], 'Surabaya');
      expect(map['role'], 'retailer');
      expect(map['createdAt'], testDate.toIso8601String());
      expect(map.containsKey('password'), false);
    });

    test('fromMap harus membuat object RetailerUser dari data Map Firebase', () {
      final mapFromFirebase = {
        'fullName': 'Toko Maju',
        'email': 'maju@mail.com',
        'phoneNumber': '08987654321',
        'address': 'Jakarta',
        'role': 'retailer',
        'createdAt': testDate.toIso8601String(),
      };

      final retailer = RetailerUser.fromMap('doc-456', mapFromFirebase);

      expect(retailer.id, 'doc-456');
      expect(retailer.username, 'Toko Maju');
      expect(retailer.email, 'maju@mail.com');
      expect(retailer.password, '');
      expect(retailer.phoneNumber, '08987654321');
      expect(retailer.address, 'Jakarta');
      expect(retailer.role, 'retailer');
      expect(retailer.createdAt, testDate);
    });
  });
} 
