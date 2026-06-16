import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerce/features/address/models/address_model.dart';

void main() {
  group('AddressModel Unit Tests', () {
    final Map<String, dynamic> mockAddressMap = {
      'label': 'Home',
      'recipientName': 'John Doe',
      'phoneNumber': '081234567890',
      'fullAddress': 'Jl. Kebon Kacang No. 1, Jakarta Pusat',
      'isDefault': true,
    };

    final addressModel = AddressModel(
      id: 'address123',
      label: 'Home',
      recipientName: 'John Doe',
      phoneNumber: '081234567890',
      fullAddress: 'Jl. Kebon Kacang No. 1, Jakarta Pusat',
      isDefault: true,
    );

    test('toMap() harus mengonversi model menjadi Map Firebase dengan benar', () {
      final map = addressModel.toMap();
      
      expect(map['label'], 'Home');
      expect(map['recipientName'], 'John Doe');
      expect(map['phoneNumber'], '081234567890');
      expect(map['fullAddress'], 'Jl. Kebon Kacang No. 1, Jakarta Pusat');
      expect(map['isDefault'], true);
    });

    test('fromMap() harus mengubah Map dari Firebase menjadi objek AddressModel', () {
      final model = AddressModel.fromMap('address123', mockAddressMap);
      
      expect(model.id, 'address123');
      expect(model.label, 'Home');
      expect(model.recipientName, 'John Doe');
      expect(model.phoneNumber, '081234567890');
      expect(model.fullAddress, 'Jl. Kebon Kacang No. 1, Jakarta Pusat');
      expect(model.isDefault, true);
    });

    test('fromMap() harus menangani field yang kosong dengan nilai default', () {
      final model = AddressModel.fromMap('address456', {});
      
      expect(model.id, 'address456');
      expect(model.label, '');
      expect(model.recipientName, '');
      expect(model.phoneNumber, '');
      expect(model.fullAddress, '');
      expect(model.isDefault, false);
    });

    test('copyWith() harus mengembalikan instance baru dengan nilai yang diperbarui', () {
      final updatedModel = addressModel.copyWith(
        label: 'Office',
        isDefault: false,
      );
      
      // Fields that are changed
      expect(updatedModel.label, 'Office');
      expect(updatedModel.isDefault, false);
      
      // Fields that remain the same
      expect(updatedModel.id, 'address123');
      expect(updatedModel.recipientName, 'John Doe');
      expect(updatedModel.phoneNumber, '081234567890');
      expect(updatedModel.fullAddress, 'Jl. Kebon Kacang No. 1, Jakarta Pusat');
    });
  });
}
