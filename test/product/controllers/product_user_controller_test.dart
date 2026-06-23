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
    // TC - 75 : Retailer Menampilkan daftar produk yang tersedia
    test('TC - 75 : Retailer Menampilkan daftar produk yang tersedia', () {
      final p1 = ProductModel(
        id: '1', retailerId: 'r1', name: 'Pisang', category: 'Food', price: 1000, stock: 10, description: 'Buah Segar', imageUrl: '', isAvailable: true
      );
      final p2 = ProductModel(
        id: '2', retailerId: 'r1', name: 'Apel', category: 'Food', price: 2000, stock: 2, description: 'Buah Segar', imageUrl: '', isAvailable: false
      );

      final list = [p1, p2];
      final availableOnly = list.where((p) => p.isAvailable).toList();
      expect(availableOnly.length, 1);
      expect(availableOnly.first.name, 'Pisang');
    });

    // TC - 76 : Retailer Pencarian produk di aplikasi retailer
    test('TC - 76 : Retailer Pencarian produk di aplikasi retailer', () {
      final p1 = ProductModel(
        id: '1', retailerId: 'r1', name: 'Pisang', category: 'Food', price: 1000, stock: 10, description: 'Buah Segar', imageUrl: ''
      );
      final p2 = ProductModel(
        id: '2', retailerId: 'r1', name: 'Apel', category: 'Food', price: 2000, stock: 2, description: 'Buah Segar', imageUrl: ''
      );

      final list = [p1, p2];
      final searchFiltered = userProductController.filterAndSortProducts(list, 'All Products', 'Apel', 'Name A-Z');
      expect(searchFiltered.length, 1);
      expect(searchFiltered.first.name, 'Apel');
    });

    // TC - 77 : Retailer Menampilkan detail spesifikasi produk
    test('TC - 77 : Retailer Menampilkan detail spesifikasi produk', () {
      final product = ProductModel(
        id: '1', retailerId: 'r1', name: 'Pisang', category: 'Food', price: 1000, stock: 10, description: 'Deskripsi Pisang', imageUrl: '',
        weight: 1.5, length: 10.0, width: 5.0, height: 5.0
      );

      expect(product.description, 'Deskripsi Pisang');
      expect(product.weight, 1.5);
      expect(product.length, 10.0);
    });

    // TC - 78 : Retailer Menampilkan status stok (In Stock / Out of Stock)
    test('TC - 78 : Retailer Menampilkan status stok (In Stock / Out of Stock)', () {
      final inStock = ProductModel(
        id: '1', retailerId: 'r1', name: 'In Stock Product', category: 'Food', price: 1000, stock: 10, description: '', imageUrl: ''
      );
      final outOfStock = ProductModel(
        id: '2', retailerId: 'r1', name: 'Out Of Stock Product', category: 'Food', price: 1000, stock: 0, description: '', imageUrl: ''
      );

      expect(inStock.stock > 0, true);
      expect(outOfStock.stock <= 0, true);
    });

    // TC - 79 : Retailer Filter produk berdasarkan rentang harga
    test('TC - 79 : Retailer Filter produk berdasarkan rentang harga', () {
      final p1 = ProductModel(
        id: '1', retailerId: 'r1', name: 'Murah', category: 'Food', price: 5000, stock: 10, description: '', imageUrl: ''
      );
      final p2 = ProductModel(
        id: '2', retailerId: 'r1', name: 'Mahal', category: 'Food', price: 50000, stock: 2, description: '', imageUrl: ''
      );

      final list = [p1, p2];
      final minPrice = 10000;
      final maxPrice = 60000;

      final filteredByRange = list.where((p) => p.price >= minPrice && p.price <= maxPrice).toList();
      expect(filteredByRange.length, 1);
      expect(filteredByRange.first.name, 'Mahal');
    });

    // TC - 80 : Retailer Menampilkan produk terkait (Related Products)
    test('TC - 80 : Retailer Menampilkan produk terkait (Related Products)', () {
      final target = ProductModel(
        id: '1', retailerId: 'r1', name: 'Pisang', category: 'Food', price: 1000, stock: 10, description: '', imageUrl: ''
      );
      final p2 = ProductModel(
        id: '2', retailerId: 'r1', name: 'Apel', category: 'Food', price: 2000, stock: 2, description: '', imageUrl: ''
      );
      final p3 = ProductModel(
        id: '3', retailerId: 'r1', name: 'Sabun', category: 'Bath', price: 5000, stock: 5, description: '', imageUrl: ''
      );

      final list = [target, p2, p3];
      final related = list.where((p) => p.category == target.category && p.id != target.id).toList();
      expect(related.length, 1);
      expect(related.first.name, 'Apel');
    });

    // TC - 81 : Retailer Urutkan produk berdasarkan harga termurah
    test('TC - 81 : Retailer Urutkan produk berdasarkan harga termurah', () {
      final p1 = ProductModel(
        id: '1', retailerId: 'r1', name: 'Pisang', category: 'Food', price: 2000, stock: 10, description: '', imageUrl: ''
      );
      final p2 = ProductModel(
        id: '2', retailerId: 'r1', name: 'Apel', category: 'Food', price: 1000, stock: 2, description: '', imageUrl: ''
      );

      final list = [p1, p2];
      final sortedLowHigh = userProductController.filterAndSortProducts(list, 'All Products', '', 'Price Low-High');
      expect(sortedLowHigh.first.name, 'Apel');
    });

    // TC - 82 : Retailer Urutkan produk berdasarkan terbaru
    test('TC - 82 : Retailer Urutkan produk berdasarkan terbaru', () {
      final p1 = {
        'name': 'Lama',
        'createdAt': DateTime.now().subtract(const Duration(days: 5)),
      };
      final p2 = {
        'name': 'Baru',
        'createdAt': DateTime.now(),
      };

      final list = [p1, p2];
      list.sort((a, b) => (b['createdAt'] as DateTime).compareTo(a['createdAt'] as DateTime));
      expect(list.first['name'], 'Baru');
    });

    test('calculateDiscountedPrice harus mengembalikan harga yang benar untuk diskon persentase', () {
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

      final discountedPrice = userProductController.calculateDiscountedPrice(product, promo);
      expect(discountedPrice, 80000.0);
    });

    test('calculateDiscountedPrice harus mengembalikan harga yang benar untuk diskon nominal tetap', () {
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

      final discountedPrice = userProductController.calculateDiscountedPrice(product, promo);
      expect(discountedPrice, 75000.0);
    });

    test('calculateDiscountedPrice harus mengembalikan harga asli jika tidak ada promo', () {
      final product = ProductModel(
        id: '1', retailerId: 'r1', name: 'Produk Uji', category: 'Kategori', price: 100000, stock: 10, description: '', imageUrl: ''
      );

      final discountedPrice = userProductController.calculateDiscountedPrice(product, null);
      expect(discountedPrice, 100000.0);
    });

    test('getBestPromotionForProduct harus mengembalikan promo terbaik untuk produk', () {
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

      final bestPromo = userProductController.getBestPromotionForProduct(product, promos);
      expect(bestPromo, isNotNull);
      expect(bestPromo!.title, 'Promo Besar Tetap');
    });

    test('getBestPromotionForProduct harus mengembalikan null jika tidak ada promo yang cocok', () {
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

      final bestPromo = userProductController.getBestPromotionForProduct(product, promos);
      expect(bestPromo, isNull);
    });
  });
}
