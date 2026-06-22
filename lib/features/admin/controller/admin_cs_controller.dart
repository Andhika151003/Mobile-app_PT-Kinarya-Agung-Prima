import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../authentication/models/cs.dart';
import '../../../core/firebase_provider.dart';

class AdminCsController extends ChangeNotifier {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  AdminCsController({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? AppFirebase.firestore,
        _auth = auth ?? AppFirebase.auth;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<Map<String, dynamic>> _csList = [];
  List<Map<String, dynamic>> get csList => _csList;

  Future<void> fetchAllCS() async {
    _setLoading(true);
    try {
      if (!await _isAdmin()) {
        throw Exception("Unauthorized: Only Admin can access Customer Support management");
      }
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'cs')
          .get();

      _csList = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          'isActive': data['isActive'] ?? true,
        };
      }).toList();

      _setLoading(false);
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
    }
  }

  Future<bool> _isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return false;
    return doc.data()?['role'] == 'admin';
  }

  int getActiveCSCount() {
    return _csList.where((cs) => cs['isActive'] == true).length;
  }

  int getInactiveCSCount() {
    return _csList.where((cs) => cs['isActive'] == false).length;
  }

  Future<bool> toggleCSStatus(String uid, bool newStatus) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      if (!await _isAdmin()) {
        throw Exception("Unauthorized: Only Admin can modify CS status");
      }

      await _firestore.collection('users').doc(uid).update({
        'isActive': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
        'managedBy': _auth.currentUser?.uid,
      });

      final index = _csList.indexWhere((cs) => cs['id'] == uid);
      if (index != -1) {
        _csList[index]['isActive'] = newStatus;
      }
      
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = "Failed to update status: ${e.toString()}";
      _setLoading(false);
      return false;
    }
  }

  Future<bool> addCS(CsUser cs) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      // 1. Validasi Keamanan (Otorisasi Admin)
      if (!await _isAdmin()) {
        throw Exception("Unauthorized: Only Admin can add Customer Support");
      }

      // 2. Memastikan Akun Terbuat di Firebase Auth
      // Menggunakan secondary app untuk mencegah login otomatis (auto sign-in)
      UserCredential userCredential;
      try {
        FirebaseApp app = await Firebase.initializeApp(
          name: 'SecondaryApp',
          options: Firebase.app().options,
        );
        final secondaryAuth = FirebaseAuth.instanceFor(app: app);
        userCredential = await secondaryAuth.createUserWithEmailAndPassword(
          email: cs.email,
          password: cs.password,
        );
        await app.delete(); // Hapus secondary app setelah selesai
      } catch (e) {
        // Fallback for unit testing where Firebase core isn't initialized
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: cs.email,
          password: cs.password,
        );
      }

      final uid = userCredential.user?.uid;
      if (uid == null) throw Exception("Failed to obtain UID from Firebase Auth");

      // 3. Firestore Entry
      final csData = cs.toMap();
      csData['id'] = uid; 
      await _firestore.collection('users').doc(uid).set(csData);
      
      await fetchAllCS(); 
      
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        _errorMessage = "The email address is already in use by another account.";
      } else {
        _errorMessage = e.message;
      }
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }
  Future<bool> updateCS(String uid, {required String username, required String phoneNumber}) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      if (!await _isAdmin()) {
        throw Exception("Unauthorized: Only Admin can edit Customer Support");
      }

      await _firestore.collection('users').doc(uid).update({
        'username': username,
        'phoneNumber': phoneNumber,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final index = _csList.indexWhere((cs) => cs['id'] == uid);
      if (index != -1) {
        _csList[index]['username'] = username;
        _csList[index]['phoneNumber'] = phoneNumber;
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = "Failed to update CS: ${e.toString()}";
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
