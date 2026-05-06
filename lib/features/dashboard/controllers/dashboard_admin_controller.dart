import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../authentication/services/profile_service.dart';
import '../../authentication/services/statistic_service.dart';
import '../../../core/repositories/promotion_repository.dart';
import '../../../core/repositories/complaint_repository.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/repositories/order_repository.dart';
import '../../complaint/models/complaint.dart';

class DashboardAdminController {
  final ProfileService _profileService;
  final StatisticService _statisticService;
  final PromotionRepository _promotionRepository;
  final ComplaintRepository _complaintRepository;
  final AuthRepository _authRepository;

  DashboardAdminController({
    ProfileService? profileService,
    StatisticService? statisticService,
    PromotionRepository? promotionRepository,
    ComplaintRepository? complaintRepository,
    AuthRepository? authRepository,
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
            ),
        _promotionRepository =
            promotionRepository ?? PromotionRepository(firestore: firestore),
        _complaintRepository =
            complaintRepository ?? ComplaintRepository(firestore: firestore),
        _authRepository = authRepository ?? AuthRepository(firestore: firestore);

  Future<Map<String, dynamic>> getOverviewStats() async {
    final result = await _statisticService.getAdminStats();
    final stats = result.isSuccess ? result.data! : {'totalRevenue': 0.0, 'monthlySales': 0};

    final totalCustomers = await _authRepository.getTotalCustomersCount();

    return {
      'totalSales': stats['totalRevenue'],
      'salesChange': '+0%',
      'totalOrders': 0, 
      'ordersChange': '+0%',
      'totalCustomers': totalCustomers,
      'customersChange': '+0%',
      'conversionRate': '0',
      'conversionChange': '+0%',
    };
  }

  Future<List<Map<String, dynamic>>> getPromotions() async {
    final result = await _promotionRepository.getActivePromotions();
    if (result.isSuccess) {
      return result.data!.map((promo) => {
        'id': promo.id,
        ...promo.toMap(),
      }).toList();
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getRetailers() async {
    final snapshot = await _authRepository.getRetailers(limit: 10);
    return snapshot.docs
        .map((doc) => {
              'id': doc.id,
              ...doc.data(),
            })
        .toList();
  }

  Future<Map<String, dynamic>?> getAdminInfo() async {
    final result = await _profileService.getProfile();
    return result.isSuccess ? result.data : null;
  }

  Stream<List<ComplaintModel>> getAllComplaints() {
    return _complaintRepository.getAllComplaintsStream();
  }
}
