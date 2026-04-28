import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/promotion.dart';

class PromotionUserController {
  final FirebaseFirestore _firestore;

  PromotionUserController({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<PromotionModel>> getActivePromotions() async {
    try {
      final snapshot = await _firestore
          .collection('promotions')
          .where('status', whereIn: ['active', 'upcoming'])
          .get();

      final promos = snapshot.docs
          .map((doc) => PromotionModel.fromMap(doc.id, doc.data()))
          .where((promo) {
            return promo.isActive || promo.isStartingSoon;
          })
          .toList();

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
      debugPrint('Error fetching promotions: $e');
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