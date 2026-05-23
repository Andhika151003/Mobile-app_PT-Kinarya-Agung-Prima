import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:ecommerce/features/product/controllers/product_user_controller.dart';
import 'package:ecommerce/features/product/models/product.dart';
import 'package:ecommerce/features/promotion/models/promotion.dart';

void main() {
  late ProductUserController userProductController;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    userProductController = ProductUserController(firestore: fakeFirestore);
  });

  group('Unit Test ProductUserController', () {
    test('filterAndSortProducts harus mengurutkan dan memfilter produk dengan benar', () {
      // Arrange — Membuat 2 produk dengan nama, harga, dan kategori berbeda
      final p1 = ProductModel(
        id: '1', retailerId: 'r1', name: 'Pisang', category: 'Food', price: 1000, stock: 10, description: 'Buah Segar', imageUrl: ''
      );
      final p2 = ProductModel(
        id: '2', retailerId: 'r1', name: 'Apel', category: 'Food', price: 2000, stock: 2, description: 'Buah Segar', imageUrl: ''
      );

      final list = [p1, p2];

      // Act & Assert — Menguji filter berdasarkan kategori 'Food'
      final filteredCategories = userProductController.filterAndSortProducts(list, 'Food', '', 'Name A-Z');
      expect(filteredCategories.length, 2);

      // Act & Assert — Menguji sorting berdasarkan nama A-Z
      final sortedAZ = userProductController.filterAndSortProducts(list, 'All Products', '', 'Name A-Z');
      expect(sortedAZ.first.name, 'Apel');

      // Act & Assert — Menguji sorting berdasarkan harga terendah ke tertinggi
      final sortedLowHigh = userProductController.filterAndSortProducts(list, 'All Products', '', 'Price Low-High');
      expect(sortedLowHigh.first.name, 'Pisang'); 

      // Act & Assert — Menguji sorting berdasarkan harga tertinggi ke terendah
      final sortedHighLow = userProductController.filterAndSortProducts(list, 'All Products', '', 'Price High-Low');
      expect(sortedHighLow.first.name, 'Apel');
    });

    test('calculateDiscountedPrice harus mengembalikan harga yang benar untuk diskon persentase', () {
      // Arrange — Membuat produk seharga Rp 100.000 dan promo diskon 20%
      final product = ProductModel(
        id: '1', retailerId: 'r1', name: 'Produk Uji', category: 'Kategori', price: 100000, stock: 10, description: '', imageUrl: ''
      );
      final now = DateTime.now();
      final promo = PromotionModel(
        title: 'Promo Diskon', description: '', discountType: 'percentage', discountValue: 20,
        productIds: ['1'], applicableTo: 'specific',
        startDate: now.subtract(const Duration(days: 1)),
        endDate: now.add(const Duration(days: 5)),
        startTime: '00:00', endTime: '23:59',
        status: 'active', sku: 'S', createdAt: now, createdBy: 'admin',
      );

      // Act — Menghitung harga setelah diskon percentage
      final discountedPrice = userProductController.calculateDiscountedPrice(product, promo);

      // Assert — Memverifikasi harga diskon: 100000 * (1 - 20/100) = 80000
      expect(discountedPrice, 80000.0);
    });

    test('calculateDiscountedPrice harus mengembalikan harga yang benar untuk diskon nominal tetap', () {
      // Arrange — Membuat produk seharga Rp 100.000 dan promo potongan Rp 25.000
      final product = ProductModel(
        id: '1', retailerId: 'r1', name: 'Produk Uji', category: 'Kategori', price: 100000, stock: 10, description: '', imageUrl: ''
      );
      final now = DateTime.now();
      final promo = PromotionModel(
        title: 'Potongan Harga', description: '', discountType: 'fixed', discountValue: 25000,
        productIds: ['1'], applicableTo: 'specific',
        startDate: now.subtract(const Duration(days: 1)),
        endDate: now.add(const Duration(days: 5)),
        startTime: '00:00', endTime: '23:59',
        status: 'active', sku: 'S', createdAt: now, createdBy: 'admin',
      );

      // Act — Menghitung harga setelah potongan fixed
      final discountedPrice = userProductController.calculateDiscountedPrice(product, promo);

      // Assert — Memverifikasi harga diskon: 100000 - 25000 = 75000
      expect(discountedPrice, 75000.0);
    });

    test('calculateDiscountedPrice harus mengembalikan harga asli jika tidak ada promo', () {
      // Arrange — Membuat produk tanpa promo (null)
      final product = ProductModel(
        id: '1', retailerId: 'r1', name: 'Produk Uji', category: 'Kategori', price: 100000, stock: 10, description: '', imageUrl: ''
      );

      // Act — Menghitung harga dengan promo null
      final discountedPrice = userProductController.calculateDiscountedPrice(product, null);

      // Assert — Memverifikasi harga tetap sama dengan harga asli
      expect(discountedPrice, 100000.0);
    });

    test('getBestPromotionForProduct harus mengembalikan promo terbaik untuk produk', () {
      // Arrange — Membuat produk dan 2 promo berbeda: percentage 10% dan fixed Rp 50.000
      final product = ProductModel(
        id: 'prod1', retailerId: 'r1', name: 'Produk Uji', category: 'Kategori', price: 100000, stock: 10, description: '', imageUrl: ''
      );
      final now = DateTime.now();

      final promos = [
        PromotionModel(
          title: 'Promo Kecil', description: '', discountType: 'percentage', discountValue: 10,
          productIds: ['prod1'], applicableTo: 'specific',
          startDate: now.subtract(const Duration(days: 1)),
          endDate: now.add(const Duration(days: 5)),
          startTime: '00:00', endTime: '23:59',
          status: 'active', sku: 'S1', createdAt: now, createdBy: 'admin',
        ),
        PromotionModel(
          title: 'Promo Besar Tetap', description: '', discountType: 'fixed', discountValue: 50000,
          productIds: ['prod1'], applicableTo: 'specific',
          startDate: now.subtract(const Duration(days: 1)),
          endDate: now.add(const Duration(days: 5)),
          startTime: '00:00', endTime: '23:59',
          status: 'active', sku: 'S2', createdAt: now, createdBy: 'admin',
        ),
      ];

      // Act — Mencari promo terbaik untuk produk (fixed punya prioritas lebih tinggi)
      final bestPromo = userProductController.getBestPromotionForProduct(product, promos);

      // Assert — Memverifikasi promo fixed terpilih karena prioritas tipe lebih tinggi
      expect(bestPromo, isNotNull);
      expect(bestPromo!.title, 'Promo Besar Tetap');
    });

    test('getBestPromotionForProduct harus mengembalikan null jika tidak ada promo yang cocok', () {
      // Arrange — Membuat produk dengan ID yang tidak cocok dengan promo manapun
      final product = ProductModel(
        id: 'prod999', retailerId: 'r1', name: 'Produk Uji', category: 'Kategori', price: 100000, stock: 10, description: '', imageUrl: ''
      );
      final now = DateTime.now();

      final promos = [
        PromotionModel(
          title: 'Promo Diskon', description: '', discountType: 'percentage', discountValue: 10,
          productIds: ['prod_other'], applicableTo: 'specific',
          startDate: now.subtract(const Duration(days: 1)),
          endDate: now.add(const Duration(days: 5)),
          startTime: '00:00', endTime: '23:59',
          status: 'active', sku: 'S1', createdAt: now, createdBy: 'admin',
        ),
      ];

      // Act — Mencari promo untuk produk yang tidak punya promo yang cocok
      final bestPromo = userProductController.getBestPromotionForProduct(product, promos);

      // Assert — Memverifikasi hasilnya null karena tidak ada promo yang cocok
      expect(bestPromo, isNull);
    });
  });
}
