import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileCsController {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  ProfileCsController({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> getCsProfile() async {
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
      throw Exception("Gagal memuat profil Retail: $e");
    }
  }
}