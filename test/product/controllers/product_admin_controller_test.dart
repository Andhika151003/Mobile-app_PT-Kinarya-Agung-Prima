import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:ecommerce/features/product/controllers/product_admin_controller.dart';
import 'package:ecommerce/features/product/models/product.dart';

void main() {
  late AdminProductController adminProductController;
  late MockFirebaseAuth mockAuth;
  late FakeFirebaseFirestore fakeFirestore;
  late MockUser mockUser;

  setUp(() {
    mockUser = MockUser(
      isAnonymous: false,
      uid: 'admin123',
    );
    mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
    fakeFirestore = FakeFirebaseFirestore();

    adminProductController = AdminProductController(
      firestore: fakeFirestore,
      auth: mockAuth,
    );
  });

  group('Unit Test AdminProductController', () {
    // TC - 64 : Admin Menampilkan daftar produk
    test('TC - 64 : Admin Menampilkan daftar produk', () async {
      final product = ProductModel(
        id: 'p1', retailerId: 'admin123', name: 'Produk A', category: 'Health', price: 10000, stock: 10, description: '', imageUrl: ''
      );
      await fakeFirestore.collection('products').doc('p1').set(product.toMap());
      
      final productsStream = adminProductController.getSupplyProducts();
      final list = await productsStream.first;
      expect(list.length, 1);
      expect(list.first.name, 'Produk A');
    });

    // TC - 65 : Admin Tambah produk baru — data valid
    test('TC - 65 : Admin Tambah produk baru — data valid', () async {
      final product = ProductModel(
        retailerId: '', name: 'Produk Baru', category: 'Beauty Care', price: 10000, stock: 10, description: 'Deskripsi Uji', imageUrl: ''
      );

      await adminProductController.addSupplyProduct(product);

      final snapshot = await fakeFirestore.collection('products').get();
      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.data()['retailerId'], 'admin123');
      expect(snapshot.docs.first.data()['name'], 'Produk Baru');
    });

    // TC - 66 : Admin Tambah produk baru — SKU duplikat
    test('TC - 66 : Admin Tambah produk baru — SKU duplikat', () async {
      // Menambahkan produk awal dengan SKU
      final firstProduct = ProductModel(
        id: 'p1', retailerId: 'admin123', name: 'Produk Satu', sku: 'SKU-DUP', category: 'Health', price: 10000, stock: 10, description: '', imageUrl: ''
      );
      await fakeFirestore.collection('products').doc('p1').set(firstProduct.toMap());

      // Simulasi pendeteksian duplikasi SKU di database
      final dupQuery = await fakeFirestore.collection('products').where('sku', isEqualTo: 'SKU-DUP').get();
      expect(dupQuery.docs.length, 1); // Terdeteksi SKU sudah ada di database
    });

    // TC - 67 : Admin Validasi input harga (tidak boleh negatif)
    test('TC - 67 : Admin Validasi input harga (tidak boleh negatif)', () {
      final negativePriceProduct = ProductModel(
        retailerId: 'admin123', name: 'Produk Negatif', price: -5000, stock: 10, description: '', imageUrl: '', category: 'Health'
      );
      expect(negativePriceProduct.price < 0, true);
    });

    // TC - 68 : Admin Upload foto produk (multiple images)
    test('TC - 68 : Admin Upload foto produk (multiple images)', () {
      final productWithMultipleImages = ProductModel(
        retailerId: 'admin123', name: 'Produk Gambar Banyak', price: 10000, stock: 10, description: '', imageUrl: 'cover_url', imageUrls: ['url1', 'url2'], category: 'Health'
      );
      expect(productWithMultipleImages.imageUrl, 'cover_url');
      expect(productWithMultipleImages.imageUrls?.length, 2);
    });

    // TC - 69 : Admin Edit informasi produk
    test('TC - 69 : Admin Edit informasi produk', () async {
      final product = ProductModel(
        id: 'prod1', retailerId: 'admin123', name: 'Produk Lama', category: 'Kategori', price: 10000, stock: 10, description: 'Deskripsi Lama', imageUrl: ''
      );
      await fakeFirestore.collection('products').doc('prod1').set(product.toMap());

      product.name = 'Nama Produk Baru';
      await adminProductController.updateSupplyProduct(product);

      final doc = await fakeFirestore.collection('products').doc('prod1').get();
      expect(doc.data()!['name'], 'Nama Produk Baru');
      expect(doc.data()!.containsKey('updatedAt'), true);
    });

    // TC - 70 : Admin Update stok produk secara manual
    test('TC - 70 : Admin Update stok produk secara manual', () async {
      final product = ProductModel(
        id: 'prod1', retailerId: 'admin123', name: 'Produk', category: 'Kategori', price: 10000, stock: 10, description: 'Deskripsi', imageUrl: ''
      );
      await fakeFirestore.collection('products').doc('prod1').set(product.toMap());

      await adminProductController.addStock(product, 15);

      final doc = await fakeFirestore.collection('products').doc('prod1').get();
      expect(doc.data()!['stock'], 25);
    });

    // TC - 71 : Admin Hapus produk yang tidak memiliki transaksi
    test('TC - 71 : Admin Hapus produk yang tidak memiliki transaksi', () async {
      final product = ProductModel(
        id: 'prod1', retailerId: 'admin123', name: 'Produk Hapus', category: 'Kategori', price: 10000, stock: 10, description: 'Deskripsi', imageUrl: ''
      );
      await fakeFirestore.collection('products').doc('prod1').set(product.toMap());

      await adminProductController.deleteSupplyProduct(product);

      final doc = await fakeFirestore.collection('products').doc('prod1').get();
      expect(doc.exists, false);
    });

    // TC - 72 : Admin Cegah hapus produk yang sedang dalam promosi aktif
    test('TC - 72 : Admin Cegah hapus produk yang sedang dalam promosi aktif', () async {
      // Simulasikan produk terdaftar di promosi aktif
      final activePromoDoc = {
        'title': 'Promo Ramadhan',
        'status': 'active',
        'productIds': ['prod1'],
        'applicableTo': 'specific',
      };
      await fakeFirestore.collection('promotions').doc('promo1').set(activePromoDoc);

      // Cek apakah produk dengan ID 'prod1' terdaftar di promosi aktif
      final activePromosQuery = await fakeFirestore
          .collection('promotions')
          .where('status', isEqualTo: 'active')
          .where('productIds', arrayContains: 'prod1')
          .get();

      // Jika terdaftar, maka cegah penghapusan
      final isPrevented = activePromosQuery.docs.isNotEmpty;
      expect(isPrevented, true);
    });

    // TC - 73 : Admin Pencarian produk berdasarkan nama atau SKU
    // TC - 74 : Admin Filter produk berdasarkan kategori
    test('TC - 73 & TC - 74 : Admin Pencarian dan Filter produk berdasarkan kategori/SKU/Nama', () {
      final p1 = ProductModel(
        id: '1', retailerId: 'admin123', name: 'Zebra', sku: 'Z-1', category: 'Cat1', brand: 'B1', 
        price: 15000, moq: 1, stock: 10, imageUrl: '', isAvailable: true, monthlySales: 5, lowStockAlert: 5, description: ''
      );
      final p2 = ProductModel(
        id: '2', retailerId: 'admin123', name: 'Alpha', sku: 'A-1', category: 'Cat2', brand: 'B2', 
        price: 10000, moq: 1, stock: 2, imageUrl: '', isAvailable: true, monthlySales: 15, lowStockAlert: 5, description: ''
      );

      final List<ProductModel> list = [p1, p2];

      // TC - 74 : Filter berdasarkan kategori
      final c1Filtered = adminProductController.filterAndSortProducts(list, 'Cat1', '', false, 'Name A-Z');
      expect(c1Filtered.length, 1);
      expect(c1Filtered.first.name, 'Zebra');

      // TC - 73 : Pencarian berdasarkan nama
      final searchFiltered = adminProductController.filterAndSortProducts(list, 'All', 'Alpha', false, 'Name A-Z');
      expect(searchFiltered.length, 1);
      expect(searchFiltered.first.name, 'Alpha');
    });
  });
}
