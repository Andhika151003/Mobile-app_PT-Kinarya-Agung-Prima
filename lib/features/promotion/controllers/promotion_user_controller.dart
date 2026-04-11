import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/promotion.dart';

class PromotionUserController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch semua promo yang sedang aktif saat ini
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
            // Filter manual karena Firestore tidak bisa query 2 range sekaligus
            return promo.startDate.isBefore(now) && promo.endDate.isAfter(now);
          })
          .toList();

      // Urutkan: yang ending soon duluan, lalu by startDate terbaru
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

  /// Ambil satu promo terbaru untuk pop up (promo pertama yang aktif)
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