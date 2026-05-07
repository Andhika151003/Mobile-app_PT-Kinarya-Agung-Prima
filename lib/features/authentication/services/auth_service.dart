import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../../core/error/failures.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/utils/result.dart';
import '../models/admin.dart';
import '../models/cs.dart';
import '../models/retailer.dart';

class AuthService {
  final AuthRepository _authRepository;

  AuthService({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository();

  Future<Result<dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _authRepository.signIn(email.trim(), password);
      final uid = userCredential.user!.uid;

      final docSnapshot = await _authRepository.getUserDoc(uid);

      if (!docSnapshot.exists) {
        return Result.failure(ServerFailure('Data user tidak ditemukan.'));
      }

      final data = docSnapshot.data()!;
      final bool isActive = data['isActive'] ?? true;
      final String role = data['role']?.toString().toLowerCase() ?? 'retailer';

      if (!isActive) {
        await _authRepository.signOut();
        
        String? adminPhone;
        try {
          final adminSnapshot = await _authRepository.getAdminUser();
          if (adminSnapshot.docs.isNotEmpty) {
            adminPhone = adminSnapshot.docs.first.data()['phoneNumber'];
          }
        } catch (e) {
          debugPrint('Error fetching admin phone: $e');
        }

        final message = adminPhone != null 
            ? 'Akun Anda dinonaktifkan. Silakan hubungi admin di $adminPhone.'
            : 'Akun Anda dinonaktifkan. Silakan hubungi admin.';
            
        return Result.failure(AuthFailure(message));
      }

      dynamic user;
      if (role == 'admin') {
        user = AdminUser.fromMap(uid, data);
      } else if (role == 'cs') {
        user = CsUser.fromMap(uid, data);
      } else {
        user = RetailerUser.fromMap(uid, data);
      }

      return Result.success(user);
    } on FirebaseAuthException catch (e) {
      return Result.failure(AuthFailure(_mapFirebaseAuthErrorCode(e.code)));
    } catch (e) {
      return Result.failure(ServerFailure('Gagal melakukan login: ${e.toString()}'));
    }
  }

  Future<Result<bool>> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String businessType,
    required String password,
  }) async {
    try {
      final userCredential = await _authRepository.signUp(email.trim(), password);
      final uid = userCredential.user!.uid;

      await _authRepository.sendEmailVerification();

      await _authRepository.createUserDoc(uid, {
        'uid': uid,
        'fullName': fullName.trim(),
        'email': email.trim(),
        'phoneNumber': phoneNumber.trim(),
        'businessType': businessType,
        'role': 'retailer',
        'isActive': true,
        'createdAt': DateTime.now(),
      });

      return Result.success(true);
    } on FirebaseAuthException catch (e) {
      return Result.failure(AuthFailure(_mapFirebaseAuthErrorCode(e.code)));
    } catch (e) {
      return Result.failure(ServerFailure('Gagal melakukan pendaftaran: ${e.toString()}'));
    }
  }

  Future<Result<void>> logout() async {
    try {
      await _authRepository.signOut();
      return Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure('Gagal logout: ${e.toString()}'));
    }
  }

  Future<Result<void>> forgotPassword(String email) async {
    try {
      await _authRepository.sendPasswordResetEmail(email.trim());
      return Result.success(null);
    } on FirebaseAuthException catch (e) {
      return Result.failure(AuthFailure(_mapFirebaseAuthErrorCode(e.code)));
    } catch (e) {
      return Result.failure(ServerFailure('Gagal mengirim email reset: ${e.toString()}'));
    }
  }

  Future<Result<bool>> isEmailRegistered(String email) async {
    try {
      final exists = await _authRepository.checkEmailExists(email);
      return Result.success(exists);
    } catch (e) {
      return Result.failure(ServerFailure('Gagal memeriksa email: ${e.toString()}'));
    }
  }

  String _mapFirebaseAuthErrorCode(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Email tidak terdaftar.';
      case 'wrong-password':
        return 'Kata sandi salah.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'user-disabled':
        return 'Akun ini telah dinonaktifkan.';
      case 'email-already-in-use':
        return 'Email sudah digunakan oleh akun lain.';
      case 'weak-password':
        return 'Kata sandi terlalu lemah.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Silakan coba lagi nanti.';
      case 'network-request-failed':
        return 'Kesalahan jaringan. Periksa koneksi internet Anda.';
      default:
        return 'Terjadi kesalahan autentikasi.';
    }
  }
}
