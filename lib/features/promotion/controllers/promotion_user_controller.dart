import 'package:flutter/foundation.dart';
import '../models/promotion.dart';
import '../../../core/repositories/promotion_repository.dart';
import '../../../core/repositories/order_repository.dart';

class PromotionUserController {
  final PromotionRepository _promotionRepository;
  final OrderRepository _orderRepository;

  PromotionUserController({
    PromotionRepository? promotionRepository,
    OrderRepository? orderRepository,
  })  : _promotionRepository = promotionRepository ?? PromotionRepository(),
        _orderRepository = orderRepository ?? OrderRepository();

  Future<List<PromotionModel>> getActivePromotions() async {
    try {
      final result = await _promotionRepository.getActiveAndUpcomingPromotions();
      
      if (!result.isSuccess) {
        debugPrint('Error fetching promotions: ${result.failure?.message}');
        return [];
      }

      final promos = result.data!.where((promo) {
        return promo.isActive || promo.isStartingSoon;
      }).toList();

      promos.sort((a, b) {
        // Prioritaskan yang sedang aktif
        if (a.isActive && !b.isActive) return -1;
        if (!a.isActive && b.isActive) return 1;
        
        // Lalu yang segera berakhir (jika aktif)
        if (a.isActive && b.isActive) {
          if (a.isEndingSoon && !b.isEndingSoon) return -1;
          if (!a.isEndingSoon && b.isEndingSoon) return 1;
        }
        
        return a.startDate.compareTo(b.startDate);
      });

      return promos;
    } catch (e) {
      debugPrint('Error sorting promotions: $e');
      return [];
    }
  }

  Future<PromotionModel?> getLatestPromoForPopup() async {
    try {
      final promos = await getActivePromotions();
      if (promos.isEmpty) return null;
      return promos.first;
    } catch (e) {
      debugPrint('Error fetching promo for popup: $e');
      return null;
    }
  }

  Future<bool> checkIfPromoUsed(String userId, String promoId) async {
    try {
      final snapshot = await _orderRepository.getOrdersByUserId(userId);
      
      bool used = snapshot.docs.any((doc) {
        final data = doc.data();
        final status = data['status']?.toString();
        final orderPromoId = data['promoId']?.toString();
        
        return status != 'Cancelled' && orderPromoId == promoId;
      });

      return used;
    } catch (e) {
      debugPrint('Error checking promo usage: $e');
      return false;
    }
  }

  Future<Set<String>> getUsedPromoIds(String userId) async {
    try {
      final snapshot = await _orderRepository.getOrdersByUserId(userId);

      final usedIds = snapshot.docs
          .where((doc) {
            final data = doc.data();
            final status = data['status']?.toString();
            return status != 'Cancelled' && data['promoId'] != null;
          })
          .map((doc) => doc.data()['promoId'].toString())
          .toSet();

      return usedIds;
    } catch (e) {
      debugPrint('Error getting used promo IDs: $e');
      return {};
    }
  }
}