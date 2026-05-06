import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/profile_service.dart';
import '../services/statistic_service.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/repositories/order_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminProfileController {
  final ProfileService _profileService;
  final StatisticService _statisticService;

  AdminProfileController({
    ProfileService? profileService,
    StatisticService? statisticService,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _profileService = profileService ??
            ProfileService(
              authRepository: AuthRepository(firestore: firestore),
              auth: auth ?? FirebaseAuth.instance,
            ),
        _statisticService = statisticService ??
            StatisticService(
              orderRepository: OrderRepository(firestore: firestore),
            );

  Future<Map<String, dynamic>?> getAdminProfile() async {
    final result = await _profileService.getProfile();
    return result.isSuccess ? result.data : null;
  }

  Future<void> updateAdminProfile({
    required String fullName,
    required String phoneNumber,
    required String businessType,
    File? profileImage,
  }) async {
    final result = await _profileService.updateProfile(
      fullName: fullName,
      phoneNumber: phoneNumber,
      businessType: businessType,
      profileImage: profileImage,
      role: 'admin',
    );
    
    if (!result.isSuccess) {
      throw Exception(result.failure?.message ?? 'Gagal update profil');
    }
  }

  Future<Map<String, dynamic>> getAdminStats() async {
    final result = await _statisticService.getAdminStats();
    return result.isSuccess ? result.data! : {'totalRevenue': 0.0, 'monthlySales': 0};
  }
}