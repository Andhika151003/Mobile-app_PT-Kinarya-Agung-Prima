import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../supabase_storage_service.dart';

class RetailProfileController {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  RetailProfileController({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> getRetailProfile() async {
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

  // Menyimpan pembaruan khusus Retail
  Future<void> updateRetailProfile({
    required String storeName,
    required String location,
    required String contact,
    required String businessType,
    File? profileImage,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        String? uploadedImageUrl;

        if (profileImage != null) {
          final storageService = SupabaseStorageService();
          final fileName = 'profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          uploadedImageUrl = await storageService.uploadProductImage(profileImage, fileName);
        }

        final updateData = {
          'fullName': storeName,
          'address': location,
          'phoneNumber': contact,
          'businessType': businessType,
        };

        if (uploadedImageUrl != null) {
          updateData['photoUrl'] = uploadedImageUrl;
        }

        await _firestore.collection('users').doc(user.uid).update(updateData);
      }
    } catch (e) {
      throw Exception("Gagal update profil Retail: $e");
    }
  }

  // --- FUNGSI UNTUK TOGGLE STATUS ---
  Future<void> updateStoreStatus(bool isActive) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'isActive': isActive, // Update field boolean di Firestore
        });
      }
    } catch (e) {
      throw Exception("Gagal mengubah status toko: $e");
    }
  }
}