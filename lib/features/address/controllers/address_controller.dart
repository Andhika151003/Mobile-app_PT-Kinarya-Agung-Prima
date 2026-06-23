import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/address_model.dart';

class AddressController {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  AddressController({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? '';

  CollectionReference get _addressCollection =>
      _firestore.collection('users').doc(_uid).collection('addresses');

  Stream<List<AddressModel>> getAddresses() {
    if (_uid.isEmpty) return Stream.value([]);
    return _addressCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return AddressModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  Future<void> addAddress(AddressModel address) async {
    if (_uid.isEmpty) return;

    if (address.isDefault) {
      await _clearDefault();
    }

    await _addressCollection.add(address.toMap());
  }

  Future<void> updateAddress(AddressModel address) async {
    if (_uid.isEmpty || address.id == null) return;

    if (address.isDefault) {
      await _clearDefault();
    }

    await _addressCollection.doc(address.id).update(address.toMap());
  }

  Future<void> deleteAddress(String id) async {
    if (_uid.isEmpty) return;
    await _addressCollection.doc(id).delete();
  }

  Future<void> setDefaultAddress(String id) async {
    if (_uid.isEmpty) return;
    await _clearDefault();
    await _addressCollection.doc(id).update({'isDefault': true});
  }

  Future<void> _clearDefault() async {
    final query = await _addressCollection.where('isDefault', isEqualTo: true).get();
    for (var doc in query.docs) {
      await doc.reference.update({'isDefault': false});
    }
  }

  Future<AddressModel?> getDefaultAddress() async {
    if (_uid.isEmpty) return null;
    final query = await _addressCollection.where('isDefault', isEqualTo: true).limit(1).get();
    if (query.docs.isNotEmpty) {
      return AddressModel.fromMap(query.docs.first.id, query.docs.first.data() as Map<String, dynamic>);
    }
    
    // If no default, try getting the first one
    final all = await _addressCollection.limit(1).get();
    if (all.docs.isNotEmpty) {
      return AddressModel.fromMap(all.docs.first.id, all.docs.first.data() as Map<String, dynamic>);
    }
    
    return null;
  }
}
