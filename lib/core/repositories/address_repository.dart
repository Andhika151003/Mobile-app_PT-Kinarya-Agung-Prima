import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddressRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  AddressRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? '';

  CollectionReference<Map<String, dynamic>> get _addressCollection =>
      _firestore.collection('users').doc(_uid).collection('addresses');

  Stream<QuerySnapshot<Map<String, dynamic>>> getAddressesStream() {
    if (_uid.isEmpty) return const Stream.empty();
    return _addressCollection.snapshots();
  }

  Future<void> addAddress(Map<String, dynamic> data) async {
    if (_uid.isEmpty) return;
    await _addressCollection.add(data);
  }

  Future<void> updateAddress(String id, Map<String, dynamic> data) async {
    if (_uid.isEmpty) return;
    await _addressCollection.doc(id).update(data);
  }

  Future<void> deleteAddress(String id) async {
    if (_uid.isEmpty) return;
    await _addressCollection.doc(id).delete();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getDefaultAddresses() async {
    if (_uid.isEmpty) throw Exception('User not authenticated');
    return await _addressCollection.where('isDefault', isEqualTo: true).get();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getFirstAddress() async {
    if (_uid.isEmpty) throw Exception('User not authenticated');
    return await _addressCollection.limit(1).get();
  }
}
