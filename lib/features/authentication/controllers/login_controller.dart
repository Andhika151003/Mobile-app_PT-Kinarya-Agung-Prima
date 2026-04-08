import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/retailer.dart';

class LoginController extends ChangeNotifier {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isDisposed = false;

  // Validasi untuk field "Username" (diisi email)
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

  Future<Retailer?> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

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
      
      // 3. Buat objek Retailer dari data Firestore
      final retailer = Retailer(
        id: userCredential.user!.uid,
        fullName: data['fullName'] ?? 'Admin',
        email: data['email'] ?? '',
        password: '', 
        phoneNumber: data['phoneNumber'] ?? '-',
        address: data['address'] ?? '-',
        role: data['role'] ?? 'retailer',
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

      _setLoading(false);
      return retailer;
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
