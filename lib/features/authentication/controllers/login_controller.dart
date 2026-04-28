import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/admin.dart';
import '../models/cs.dart';
import '../models/retailer.dart';

class LoginController extends ChangeNotifier {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _deactivatedAdminPhone;
  String? get deactivatedAdminPhone => _deactivatedAdminPhone;

  bool _isDisposed = false;
  
  String? validateEmailInput(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
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

      // 2. Ambil data user dari Firestore
      final docSnapshot = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!docSnapshot.exists) {
        throw Exception('User data not found');
      }

      final data = docSnapshot.data()!;
      final bool isActive = data['isActive'] ?? true;
      final String role = data['role']?.toString().toLowerCase() ?? 'retailer';

      // 3. Cek status aktif (khusus untuk retailer atau semua role jika diperlukan)
      if (!isActive) {
        await _auth.signOut(); // Pastikan logout dari Firebase
        
        // Ambil nomor admin dari Firestore
        try {
          final adminSnapshot = await _firestore
              .collection('users')
              .where('role', isEqualTo: 'admin')
              .limit(1)
              .get();
          
          if (adminSnapshot.docs.isNotEmpty) {
            _deactivatedAdminPhone = adminSnapshot.docs.first.data()['phoneNumber'];
          }
        } catch (e) {
          debugPrint('Error fetching admin phone: $e');
        }

        throw Exception('Account Deactivated. Please contact admin.');
      }
      
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
          message = 'Email not found';
          break;
        case 'wrong-password':
          message = 'Incorrect password';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address';
          break;
        case 'user-disabled':
          message = 'This account has been disabled';
          break;
        default:
          message = 'Login failed: ${e.message}';
      }
      _setError(message);
      _setLoading(false);
      return null;
    } catch (e) {
      _setError('Login failed: ${e.toString()}');
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
