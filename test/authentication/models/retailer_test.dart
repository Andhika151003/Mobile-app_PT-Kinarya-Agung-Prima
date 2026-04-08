import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerce/features/authentication/models/retailer.dart';

void main() {
  group('Retailer Model Tests', () {
    final testDate = DateTime(2026, 4, 8, 10, 0, 0);

    test('toMap harus mengonversi object Retailer menjadi Map Firebase', () {
      final retailer = Retailer(
        id: 'retailer-123',
        fullName: 'Amirul',
        email: 'amirul@mail.com',
        password: 'passwordRahasia',
        phoneNumber: '08123456789',
        address: 'Surabaya',
        role: 'admin',
        createdAt: testDate,
      );

      // 2. Eksekusi
      final map = retailer.toMap();

      // 3. Ekspektasi (Assert)
      expect(map['id'], 'retailer-123');
      expect(map['fullName'], 'Amirul');
      expect(map['email'], 'amirul@mail.com');
      expect(map['phoneNumber'], '08123456789');
      expect(map['address'], 'Surabaya');
      expect(map['role'], 'admin');
      expect(map['createdAt'], testDate.toIso8601String());
      expect(map.containsKey('password'), false);
    });

    test('fromMap harus membuat object Retailer dari data Map Firebase', () {
      final mapFromFirebase = {
        'fullName': 'Toko Maju',
        'email': 'maju@mail.com',
        'phoneNumber': '08987654321',
        'address': 'Jakarta',
        'role': 'retailer',
        'createdAt': testDate.toIso8601String(),
      };

      final retailer = Retailer.fromMap('doc-456', mapFromFirebase);

      expect(retailer.id, 'doc-456');
      expect(retailer.fullName, 'Toko Maju');
      expect(retailer.email, 'maju@mail.com');
      expect(retailer.password, '');
      expect(retailer.phoneNumber, '08987654321');
      expect(retailer.address, 'Jakarta');
      expect(retailer.role, 'retailer');
      expect(retailer.createdAt, testDate);
    });
  });
}
