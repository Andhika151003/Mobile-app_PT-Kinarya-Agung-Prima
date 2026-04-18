import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/promotion.dart';

class PromotionUserController {
  final FirebaseFirestore _firestore;

  PromotionUserController({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<PromotionModel>> getActivePromotions() async {
    try {
      final now = DateTime.now();

      final snapshot = await _firestore
          .collection('promotions')
          .where('status', isEqualTo: 'active')
          .get();

      final activePromos = snapshot.docs
          .map((doc) => PromotionModel.fromMap(doc.id, doc.data()))
          .where((promo) {
            return !promo.startDate.isAfter(now) && promo.endDate.isAfter(now);
          })
          .toList();

      activePromos.sort((a, b) {
        if (a.isEndingSoon && !b.isEndingSoon) return -1;
        if (!a.isEndingSoon && b.isEndingSoon) return 1;
        return b.startDate.compareTo(a.startDate);
      });

      return activePromos;
    } catch (e) {
      debugPrint('Error fetching active promotions: $e');
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
}