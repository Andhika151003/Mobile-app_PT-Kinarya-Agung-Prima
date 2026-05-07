import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/error/failures.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/utils/result.dart';
import '../../../supabase_storage_service.dart';

class ProfileService {
  final AuthRepository _authRepository;
  final SupabaseStorageService _storageService;
  final FirebaseAuth _auth;

  ProfileService({
    AuthRepository? authRepository,
    SupabaseStorageService? storageService,
    FirebaseAuth? auth,
  })  : _authRepository = authRepository ?? AuthRepository(),
        _storageService = storageService ?? SupabaseStorageService(),
        _auth = auth ?? FirebaseAuth.instance;

  Future<Result<Map<String, dynamic>?>> getProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return Result.failure(AuthFailure('User tidak terautentikasi'));
      
      final doc = await _authRepository.getUserDoc(user.uid);
      if (!doc.exists) return Result.success(null);
      
      final data = doc.data()!;
      data['uid'] = user.uid;
      return Result.success(data);
    } catch (e) {
      return Result.failure(ServerFailure('Gagal memuat profil: $e'));
    }
  }

  Future<Result<void>> updateProfile({
    required String fullName,
    required String phoneNumber,
    String? businessType,
    File? profileImage,
    required String role, 
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return Result.failure(AuthFailure('User tidak terautentikasi'));

      String? uploadedImageUrl;
      if (profileImage != null) {
        final fileName = '${role}_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        if (role == 'admin') {
          uploadedImageUrl = await _storageService.uploadAdminProfileImage(profileImage, fileName);
        } else {
          uploadedImageUrl = await _storageService.uploadRetailProfileImage(profileImage, fileName);
        }
      }

      final updateData = {
        'fullName': fullName,
        'phoneNumber': phoneNumber,
      };

      if (businessType != null) {
        updateData['businessType'] = businessType;
      }

      if (uploadedImageUrl != null) {
        updateData['photoUrl'] = uploadedImageUrl;
      }

      await _authRepository.updateUserDoc(user.uid, updateData);
      return Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure('Gagal memperbarui profil: $e'));
    }
  }

  Future<Result<void>> updateStatus(bool isActive) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return Result.failure(AuthFailure('User tidak terautentikasi'));
      
      await _authRepository.updateUserDoc(user.uid, {'isActive': isActive});
      return Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure('Gagal memperbarui status: $e'));
    }
  }
}
