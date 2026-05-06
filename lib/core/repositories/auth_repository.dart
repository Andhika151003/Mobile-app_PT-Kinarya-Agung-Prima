import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  // Authentication Methods
  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signUp(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  // Firestore User Methods
  Future<bool> checkEmailExists(String email) async {
    final snapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: email.trim())
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDoc(String uid) async {
    return await _firestore.collection('users').doc(uid).get();
  }

  Future<void> updateUserDoc(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
  }

  Future<void> createUserDoc(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).set(data);
  }

  Future<int> getTotalCustomersCount() async {
    final snapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'retailer')
        .get();
    return snapshot.docs.length;
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getRetailers({int limit = 10}) async {
    return await _firestore
        .collection('users')
        .where('role', isEqualTo: 'retailer')
        .limit(limit)
        .get();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getAdminUser() async {
    return await _firestore
        .collection('users')
        .where('role', isEqualTo: 'admin')
        .limit(1)
        .get();
  }

  User? get currentUser => _auth.currentUser;
}
