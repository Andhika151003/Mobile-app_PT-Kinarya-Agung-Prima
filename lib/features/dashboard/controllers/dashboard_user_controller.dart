import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../authentication/services/profile_service.dart';
import '../../authentication/services/statistic_service.dart';
import '../../../core/repositories/order_repository.dart';
import '../../../core/repositories/product_repository.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../product/models/product.dart';
import '../../order/models/order.dart';

class DashboardUserController {
  final ProfileService _profileService;
  final StatisticService _statisticService;
  final OrderRepository _orderRepository;
  final ProductRepository _productRepository;
  final FirebaseAuth _auth;

  DashboardUserController({
    ProfileService? profileService,
    StatisticService? statisticService,
    OrderRepository? orderRepository,
    ProductRepository? productRepository,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _profileService = profileService ??
            ProfileService(
              authRepository: AuthRepository(firestore: firestore),
              auth: auth ?? FirebaseAuth.instance,
            ),
        _statisticService = statisticService ??
            StatisticService(
              orderRepository: OrderRepository(firestore: firestore),
            ),
        _orderRepository = orderRepository ?? OrderRepository(firestore: firestore),
        _productRepository =
            productRepository ?? ProductRepository(firestore: firestore);

  Future<Map<String, dynamic>?> getUserData() async {
    final result = await _profileService.getProfile();
    return result.isSuccess ? result.data : null;
  }

  Future<String> getUserFullName() async {
    final userData = await getUserData();
    return userData?['fullName'] ?? 'Retailer';
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    final user = _auth.currentUser;
    if (user == null) return {'totalOrders': 0, 'totalSpent': 0.0};
    
    final result = await _statisticService.getRetailStats(user.uid);
    return result.isSuccess ? result.data! : {'totalOrders': 0, 'totalSpent': 0.0};
  }

  Stream<List<OrderModel>> getRecentOrders() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);
    return _orderRepository.getRecentOrdersStream(user.uid);
  }

  Stream<List<ProductModel>> getRecommendedProducts() {
    return _productRepository.getRecommendedProducts();
  }
}
