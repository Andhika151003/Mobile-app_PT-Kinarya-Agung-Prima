import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:ecommerce/features/address/controllers/address_controller.dart';
import 'package:ecommerce/features/address/models/address_model.dart';

void main() {
  group('AddressController Unit Tests', () {
    late FakeFirebaseFirestore mockFirestore;
    late MockFirebaseAuth mockAuth;
    late AddressController controller;
    const testUid = 'user123';

    setUp(() {
      mockFirestore = FakeFirebaseFirestore();
      final mockUser = MockUser(uid: testUid, email: 'user@test.com');
      mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
      
      controller = AddressController(
        firestore: mockFirestore,
        auth: mockAuth,
      );
    });

    test('getAddresses() harus mengembalikan list AddressModel yang ada', () async {
      await mockFirestore
          .collection('users')
          .doc(testUid)
          .collection('addresses')
          .doc('addr1')
          .set({
        'label': 'Home',
        'recipientName': 'John',
        'phoneNumber': '123',
        'fullAddress': 'Jl. A',
        'isDefault': true,
      });

      final addressesStream = controller.getAddresses();
      final addresses = await addressesStream.first;

      expect(addresses.length, 1);
      expect(addresses.first.id, 'addr1');
      expect(addresses.first.label, 'Home');
    });

    test('addAddress() harus menyimpan data ke Firestore', () async {
      final newAddress = AddressModel(
        label: 'Office',
        recipientName: 'Jane',
        phoneNumber: '098',
        fullAddress: 'Jl. B',
        isDefault: true,
      );

      await controller.addAddress(newAddress);

      final snapshot = await mockFirestore
          .collection('users')
          .doc(testUid)
          .collection('addresses')
          .get();

      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.data()['label'], 'Office');
      expect(snapshot.docs.first.data()['isDefault'], true);
    });

    test('addAddress() dengan isDefault = true harus mereset address lama menjadi false', () async {
      // Data lama dengan isDefault = true
      final oldDocRef = await mockFirestore
          .collection('users')
          .doc(testUid)
          .collection('addresses')
          .add({
        'label': 'Home',
        'recipientName': 'John',
        'phoneNumber': '123',
        'fullAddress': 'Jl. A',
        'isDefault': true,
      });

      final newAddress = AddressModel(
        label: 'Office',
        recipientName: 'Jane',
        phoneNumber: '098',
        fullAddress: 'Jl. B',
        isDefault: true,
      );

      await controller.addAddress(newAddress);

      final oldDocSnapshot = await oldDocRef.get();
      expect(oldDocSnapshot.data()?['isDefault'], false);
    });

    test('updateAddress() harus memperbarui data di Firestore', () async {
      final docRef = await mockFirestore
          .collection('users')
          .doc(testUid)
          .collection('addresses')
          .add({
        'label': 'Home',
        'recipientName': 'John',
        'phoneNumber': '123',
        'fullAddress': 'Jl. A',
        'isDefault': false,
      });

      final updatedAddress = AddressModel(
        id: docRef.id,
        label: 'Updated Home',
        recipientName: 'John',
        phoneNumber: '123',
        fullAddress: 'Jl. A Updated',
        isDefault: false,
      );

      await controller.updateAddress(updatedAddress);

      final snapshot = await docRef.get();
      expect(snapshot.data()?['label'], 'Updated Home');
    });

    test('deleteAddress() harus menghapus dokumen dari Firestore', () async {
      final docRef = await mockFirestore
          .collection('users')
          .doc(testUid)
          .collection('addresses')
          .add({
        'label': 'Home',
        'recipientName': 'John',
        'phoneNumber': '123',
        'fullAddress': 'Jl. A',
        'isDefault': false,
      });

      await controller.deleteAddress(docRef.id);

      final snapshot = await docRef.get();
      expect(snapshot.exists, false);
    });

    test('setDefaultAddress() harus membuat satu alamat default dan mereset lainnya', () async {
      final doc1 = await mockFirestore
          .collection('users')
          .doc(testUid)
          .collection('addresses')
          .add({
        'label': 'Home',
        'recipientName': 'John',
        'phoneNumber': '123',
        'fullAddress': 'Jl. A',
        'isDefault': true,
      });

      final doc2 = await mockFirestore
          .collection('users')
          .doc(testUid)
          .collection('addresses')
          .add({
        'label': 'Office',
        'recipientName': 'John',
        'phoneNumber': '123',
        'fullAddress': 'Jl. B',
        'isDefault': false,
      });

      await controller.setDefaultAddress(doc2.id);

      final snap1 = await doc1.get();
      final snap2 = await doc2.get();

      expect(snap1.data()?['isDefault'], false);
      expect(snap2.data()?['isDefault'], true);
    });

    test('getDefaultAddress() harus mengembalikan alamat default', () async {
      await mockFirestore
          .collection('users')
          .doc(testUid)
          .collection('addresses')
          .add({
        'label': 'Home',
        'recipientName': 'John',
        'phoneNumber': '123',
        'fullAddress': 'Jl. A',
        'isDefault': false,
      });

      await mockFirestore
          .collection('users')
          .doc(testUid)
          .collection('addresses')
          .add({
        'label': 'Office',
        'recipientName': 'John',
        'phoneNumber': '123',
        'fullAddress': 'Jl. B',
        'isDefault': true,
      });

      final defaultAddress = await controller.getDefaultAddress();

      expect(defaultAddress, isNotNull);
      expect(defaultAddress?.label, 'Office');
    });

    test('getDefaultAddress() harus mengembalikan alamat pertama jika tidak ada yang default', () async {
      await mockFirestore
          .collection('users')
          .doc(testUid)
          .collection('addresses')
          .add({
        'label': 'Home',
        'recipientName': 'John',
        'phoneNumber': '123',
        'fullAddress': 'Jl. A',
        'isDefault': false,
      });

      final defaultAddress = await controller.getDefaultAddress();

      expect(defaultAddress, isNotNull);
      expect(defaultAddress?.label, 'Home');
    });

    test('getDefaultAddress() harus mengembalikan null jika belum ada alamat', () async {
      final defaultAddress = await controller.getDefaultAddress();
      expect(defaultAddress, isNull);
    });
  });
}
