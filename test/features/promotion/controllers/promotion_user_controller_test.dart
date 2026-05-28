import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:ecommerce/features/promotion/controllers/promotion_user_controller.dart';

void main() {
  late PromotionUserController userPromotionController;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    userPromotionController = PromotionUserController(
      firestore: fakeFirestore,
    );
  });

  group('Unit Test PromotionUserController', () {
    test('getActivePromotions harus mengembalikan hanya promo yang aktif dan belum kedaluwarsa', () async {
      // Arrange — Menambahkan 3 promo ke Fake Firestore dengan kondisi berbeda:
      //   promo1: expired (endDate sudah lewat)
      //   promo2: active (masih dalam rentang tanggal)
      //   promo3: inactive (status bukan 'active')
      final now = DateTime.now();

      // Expired promo
      await fakeFirestore.collection('promotions').doc('promo1').set({
        'title': 'Promo Kedaluwarsa',
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
        'title': 'Promo Aktif',
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
        'title': 'Promo Nonaktif',
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

      // Act — Memanggil getActivePromotions() untuk mengambil promo yang aktif saja
      final activePromos = await userPromotionController.getActivePromotions();

      // Assert — Memverifikasi hanya 1 promo aktif yang dikembalikan (promo2)
      expect(activePromos.length, 1);
      expect(activePromos.first.title, 'Promo Aktif');
    });
  });
}
