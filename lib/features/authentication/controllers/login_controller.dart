import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/firebase_provider.dart';
import '../models/admin.dart';
import '../models/cs.dart';
import '../models/retailer.dart';

class LoginController extends ChangeNotifier {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  LoginController({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? AppFirebase.auth,
        _firestore = firestore ?? AppFirebase.firestore;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _deactivatedAdminPhone;
  String? get deactivatedAdminPhone => _deactivatedAdminPhone;

  bool _isDisposed = false;
  
  String? validateEmailInput(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email wajib diisi';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Harap masukkan alamat email yang valid';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password wajib diisi';
    }
    return null;
  }

  // ==================== LOGIN WITH FIREBASE ====================

  Future<dynamic> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();
    _deactivatedAdminPhone = null;

    try {
      // 1. Login ke Firebase Authentication
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final docSnapshot = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get(const GetOptions(source: Source.server));

      if (!docSnapshot.exists) {
        throw Exception('User data not found');
      }

      final data = docSnapshot.data()!;

      // Cek status aktif/non-aktif
      if (data['isActive'] == false) {
        try {
          final adminDocs = await _firestore
              .collection('users')
              .where('role', isEqualTo: 'admin')
              .limit(1)
              .get();
          if (adminDocs.docs.isNotEmpty) {
            _deactivatedAdminPhone = adminDocs.docs.first.data()['phoneNumber']?.toString();
          }
        } catch (e) {
          debugPrint('Error fetching admin phone: $e');
        }

        await _auth.signOut();
        _setError('Akun Dinonaktifkan');
        _setLoading(false);
        return null;
      }

      final String role = (data['role']?.toString().trim().toLowerCase()) ?? 'retailer';
      
      dynamic user;

      if (role == 'admin') {
        user = AdminUser.fromMap(userCredential.user!.uid, data);
      } else if (role == 'cs') {
        user = CsUser.fromMap(userCredential.user!.uid, data);
      } else {
        user = RetailerUser.fromMap(userCredential.user!.uid, data);
      }

      _setLoading(false);
      return user;
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'Email tidak ditemukan';
          break;
        case 'wrong-password':
          message = 'Kata sandi salah';
          break;
        case 'invalid-email':
          message = 'Harap masukkan alamat email yang valid';
          break;
        case 'user-disabled':
          message = 'Akun ini telah dinonaktifkan';
          break;
        default:
          message = 'Login gagal: ${e.message}';
      }
      _setError(message);
      _setLoading(false);
      return null;
    } catch (e) {
      _setError('Login gagal: ${e.toString()}');
      _setLoading(false);
      return null;
    }
  }

  // ==================== LOGOUT ====================

  Future<void> logout() async {
    await _auth.signOut();
  }

  void _setLoading(bool value) {
    if (!_isDisposed) {
      _isLoading = value;
      notifyListeners();
    }
  }

  void _setError(String? message) {
    if (!_isDisposed) {
      _errorMessage = message;
      notifyListeners();
    }
  }

  void _clearError() {
    if (!_isDisposed) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
} 
