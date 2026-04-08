import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../supabase_storage_service.dart';

class AdminProfileController {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AdminProfileController({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

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
    File? profileImage,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        String? uploadedImageUrl;

        if (profileImage != null) {
          final storageService = SupabaseStorageService();
          final fileName = 'admin_profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          uploadedImageUrl = await storageService.uploadProductImage(profileImage, fileName);
        }

        final updateData = {
          'fullName': fullName,
          'address': address,
          'phoneNumber': phoneNumber,
          'businessType': businessType,
          'bankAccount': bankAccount,
          'bankName': bankName,
        };

        if (uploadedImageUrl != null) {
          updateData['photoUrl'] = uploadedImageUrl;
        }

        await _firestore.collection('users').doc(user.uid).update(updateData);
      }
    } catch (e) {
      throw Exception("Gagal update profil Admin: $e");
    }
  }
}