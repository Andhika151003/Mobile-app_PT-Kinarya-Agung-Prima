import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:ecommerce/features/promotion/controllers/promotion_user_controller.dart';
import 'package:ecommerce/features/promotion/models/promotion.dart';

void main() {
  late PromotionUserController userPromotionController;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    userPromotionController = PromotionUserController(
      firestore: fakeFirestore,
    );
  });

  group('PromotionUserController Tests', () {
    test('getActivePromotions returns only active and unexpired promos', () async {
      final now = DateTime.now();

      // Expired promo
      await fakeFirestore.collection('promotions').doc('promo1').set({
        'title': 'Expired Promo',
        'description': '',
        'discountType': '',
        'discountValue': 0,
        'productIds': [],
        'applicableTo': '',
        'startDate': now.subtract(const Duration(days: 5)),
        'endDate': now.subtract(const Duration(days: 1)),
        'startTime': '00:00',
        'endTime': '23:59',
        'status': 'active',
        'sku': 'SKU-0',
        'createdAt': now,
        'createdBy': 'user1'
      });

      // Active promo
      await fakeFirestore.collection('promotions').doc('promo2').set({
        'title': 'Active Promo',
        'description': '',
        'discountType': '',
        'discountValue': 0,
        'productIds': [],
        'applicableTo': '',
        'startDate': now.subtract(const Duration(days: 1)),
        'endDate': now.add(const Duration(days: 5)),
        'startTime': '00:00',
        'endTime': '23:59',
        'status': 'active',
        'sku': 'SKU-1',
        'createdAt': now,
        'createdBy': 'user1'
      });

      // Inactive promo
      await fakeFirestore.collection('promotions').doc('promo3').set({
        'title': 'Inactive Promo',
        'description': '',
        'discountType': '',
        'discountValue': 0,
        'productIds': [],
        'applicableTo': '',
        'startDate': now.subtract(const Duration(days: 1)),
        'endDate': now.add(const Duration(days: 5)),
        'startTime': '00:00',
        'endTime': '23:59',
        'status': 'inactive',
        'sku': 'SKU-2',
        'createdAt': now,
        'createdBy': 'user1'
      });

      final activePromos = await userPromotionController.getActivePromotions();
      expect(activePromos.length, 1);
      expect(activePromos.first.title, 'Active Promo');
    });
  });
}
