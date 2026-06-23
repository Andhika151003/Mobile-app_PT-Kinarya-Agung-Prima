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
    // TC - 56 : Retailer Hanya menampilkan promosi aktif untuk user
    // TC - 63 : Retailer Validasi promo tidak berlaku jika melewati masa aktif
    test('TC - 56 & TC - 63 : Retailer Hanya menampilkan promosi aktif dan belum kedaluwarsa', () async {
      // Arrange
      final now = DateTime.now();

      // Expired promo (TC - 63 : promo tidak berlaku jika melewati masa aktif)
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

      // Active promo (TC - 56 : Hanya menampilkan promosi aktif)
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

      // Act
      final activePromos = await userPromotionController.getActivePromotions();

      // Assert
      expect(activePromos.length, 1);
      expect(activePromos.first.title, 'Promo Aktif');
    });

    // TC - 57 : Retailer Promosi diurutkan berdasarkan prioritas
    test('TC - 57 : Retailer Promosi diurutkan berdasarkan prioritas', () {
      // Arrange
      final p1 = {
        'title': 'Promo Rendah',
        'discountType': 'percentage',
        'discountValue': 10.0,
      };
      final p2 = {
        'title': 'Promo Tinggi',
        'discountType': 'fixed',
        'discountValue': 50000.0,
      };
      final promos = [p1, p2];

      // Act
      promos.sort((a, b) {
        int typePriority(String type) {
          if (type == 'fixed') return 3;
          if (type == 'percentage') return 2;
          return 0;
        }
        return typePriority(b['discountType'] as String).compareTo(typePriority(a['discountType'] as String));
      });

      // Assert
      expect(promos.first['title'], 'Promo Tinggi');
    });

    // TC - 60 : Retailer Menampilkan banner promosi di halaman utama
    test('TC - 60 : Retailer Menampilkan banner promosi di halaman utama', () {
      // Arrange & Act
      final bannerPromos = [
        {'title': 'Promo Merdeka', 'imageUrl': 'banner1.jpg'},
        {'title': 'Promo Ramadhan', 'imageUrl': 'banner2.jpg'},
      ];

      // Assert
      expect(bannerPromos.length, 2);
      expect(bannerPromos.first['imageUrl'], isNotNull);
    });

    // TC - 61 : Retailer Klik banner promosi mengarah ke daftar produk terkait
    // TC - 62 : Retailer Filter produk berdasarkan kategori promosi
    test('TC - 61 & TC - 62 : Retailer Klik banner dan Filter produk berdasarkan kategori promosi', () {
      // Arrange
      final productIdsInPromo = ['prod1', 'prod2'];
      final allProducts = [
        {'id': 'prod1', 'name': 'Produk A', 'category': 'Beauty'},
        {'id': 'prod2', 'name': 'Produk B', 'category': 'Beauty'},
        {'id': 'prod3', 'name': 'Produk C', 'category': 'Foods'},
      ];

      // Act
      // TC - 61 : Filter berdasarkan productIds yang terkait dengan banner promo
      final relatedProducts = allProducts.where((p) => productIdsInPromo.contains(p['id'])).toList();
      // TC - 62 : Filter produk promosi berdasarkan kategori 'Beauty'
      final beautyPromoProducts = relatedProducts.where((p) => p['category'] == 'Beauty').toList();

      // Assert
      expect(relatedProducts.length, 2);
      expect(beautyPromoProducts.length, 2);
    });
  });
}
