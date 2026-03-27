import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminProfileController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> getAdminProfile() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          var data = doc.data() as Map<String, dynamic>;
          data['uid'] = user.uid;
          return data;
        }
      }
      return null;
    } catch (e) {
      throw Exception("Gagal memuat profil Admin: $e");
    }
  }

  Future<void> updateAdminProfile({
    required String fullName,
    required String address,
    required String phoneNumber,
    required String businessType,
    required String bankAccount,
    required String bankName,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fullName': fullName,
          'address': address,
          'phoneNumber': phoneNumber,
          'businessType': businessType,
          'bankAccount': bankAccount,
          'bankName': bankName,
        });
      }
    } catch (e) {
      throw Exception("Gagal update profil Admin: $e");
    }
  }
}