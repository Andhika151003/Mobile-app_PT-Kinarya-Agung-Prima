import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/promotion/models/promotion.dart';
import '../utils/result.dart';
import '../error/failures.dart';

class PromotionRepository {
  final FirebaseFirestore _firestore;

  PromotionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<Result<List<PromotionModel>>> getAllPromotions() async {
    try {
      final snapshot = await _firestore
          .collection('promotions')
          .orderBy('createdAt', descending: true)
          .get();

      final promotions = snapshot.docs
          .map((doc) => PromotionModel.fromMap(doc.id, doc.data()))
          .toList();

      return Result.success(promotions);
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<List<PromotionModel>>> getActivePromotions({int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection('promotions')
          .where('status', isEqualTo: 'active')
          .limit(limit)
          .get();

      final promotions = snapshot.docs
          .map((doc) => PromotionModel.fromMap(doc.id, doc.data()))
          .toList();

      return Result.success(promotions);
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Stream<List<PromotionModel>> getActivePromotionsStream() {
    return _firestore
        .collection('promotions')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PromotionModel.fromMap(doc.id, doc.data()))
          .where((promo) => promo.isActive)
          .toList();
    });
  }

  Future<Result<List<PromotionModel>>> getActiveAndUpcomingPromotions() async {
    try {
      final snapshot = await _firestore
          .collection('promotions')
          .where('status', whereIn: ['active', 'upcoming'])
          .get();

      final promotions = snapshot.docs
          .map((doc) => PromotionModel.fromMap(doc.id, doc.data()))
          .toList();

      return Result.success(promotions);
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<String>> createPromotion(PromotionModel promotion) async {
    try {
      final docRef = await _firestore.collection('promotions').add(promotion.toMap());
      return Result.success(docRef.id);
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<void>> updatePromotion(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('promotions').doc(id).update(data);
      return Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<void>> deletePromotion(String id) async {
    try {
      final docRef = _firestore.collection('promotions').doc(id);
      final doc = await docRef.get();
      
      if (!doc.exists) {
        return Result.failure(ServerFailure('Promotion not found'));
      }

      await docRef.delete();
      return Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }
}
