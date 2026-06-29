import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/firebase_provider.dart';

class RegisterController extends ChangeNotifier {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  RegisterController({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? AppFirebase.auth,
        _firestore = firestore ?? AppFirebase.firestore;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isDisposed = false;

  // ==================== VALIDATORS ====================

  String? validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nama Lengkap wajib diisi';
    }
    if (value.trim().length < 3) {
      return 'Harap masukkan nama lengkap';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email wajib diisi';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Harap masukkan alamat email yang valid';
    }
    return null;
  }

  String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nomor Telepon wajib diisi';
    }
    final phoneDigits = value.replaceAll(RegExp(r'\D'), '');
    if (phoneDigits.length < 10 || phoneDigits.length > 13) {
      return 'Harap masukkan nomor telepon yang valid';
    }
    return null;
  }


  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password wajib diisi';
    }
    if (value.length < 8) {
      return 'Password harus minimal 8 karakter';
    }
    return null;
  }

  String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Harap konfirmasi password Anda';
    }
    if (value != password) {
      return 'Password tidak cocok';
    }
    return null;
  }

  // ==================== REGISTER WITH FIREBASE ====================

  Future<bool> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String businessType,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      await userCredential.user!.sendEmailVerification();

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'fullName': fullName.trim(),
        'email': email.trim(),
        'phoneNumber': phoneNumber.trim(),
        'businessType': businessType,
        'role': 'retailer',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'Email sudah terdaftar';
          break;
        case 'invalid-email':
          message = 'Harap masukkan alamat email yang valid';
          break;
        case 'weak-password':
          message = 'Password harus minimal 8 karakter';
          break;
        case 'too-many-requests':
          message = 'Terlalu banyak percobaan. Harap coba lagi nanti.';
          break;
        case 'network-request-failed':
          message = 'Kesalahan jaringan. Harap periksa koneksi internet Anda.';
          break;
        default:
          message = 'Pendaftaran gagal: ${e.message}';
      }
      _setError(message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Pendaftaran gagal: ${e.toString()}');
      _setLoading(false);
      return false;
    }
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