import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/profile_service.dart';
import '../services/statistic_service.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/repositories/order_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RetailProfileController {
  final ProfileService _profileService;
  final StatisticService _statisticService;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  RetailProfileController({
    ProfileService? profileService,
    StatisticService? statisticService,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _profileService = profileService ??
            ProfileService(
              authRepository: AuthRepository(firestore: firestore),
              auth: auth ?? FirebaseAuth.instance,
            ),
        _statisticService = statisticService ??
            StatisticService(
              orderRepository: OrderRepository(firestore: firestore),
            );

  Future<Map<String, dynamic>?> getRetailProfile() async {
    final result = await _profileService.getProfile();
    return result.isSuccess ? result.data : null;
  }

  Stream<Map<String, dynamic>?> getRetailProfileStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _firestore.collection('users').doc(user.uid).snapshots().map((doc) {
      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        data['uid'] = user.uid;
        return data;
      }
      return null;
    });
  }

  Future<void> updateRetailProfile({
    required String storeName,
    required String contact,
    required String businessType,
    File? profileImage,
  }) async {
    final result = await _profileService.updateProfile(
      fullName: storeName,
      phoneNumber: contact,
      businessType: businessType,
      profileImage: profileImage,
      role: 'retail',
    );
    
    if (!result.isSuccess) {
      throw Exception(result.failure?.message ?? 'Gagal update profil');
    }
  }

  Future<void> updateStoreStatus(bool isActive) async {
    final result = await _profileService.updateStatus(isActive);
    if (!result.isSuccess) {
      throw Exception(result.failure?.message ?? 'Gagal mengubah status');
    }
  }

  Future<Map<String, dynamic>> getRetailStats() async {
    final user = _auth.currentUser;
    if (user == null) return {'totalOrders': 0, 'totalSpent': 0.0};
    
    final result = await _statisticService.getRetailStats(user.uid);
    return result.isSuccess ? result.data! : {'totalOrders': 0, 'totalSpent': 0.0};
  }
}