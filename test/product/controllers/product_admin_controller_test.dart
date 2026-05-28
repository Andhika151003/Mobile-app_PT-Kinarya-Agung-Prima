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
    test('filterAndSortProducts harus mengurutkan dan memfilter produk dengan benar', () {
      // Arrange — Membuat 2 produk dengan kategori, nama, stok, dan penjualan berbeda
      final p1 = ProductModel(
        id: '1', retailerId: 'admin123', name: 'Zebra', sku: 'Z-1', category: 'Cat1', brand: 'B1', 
        price: 15000, moq: 1, stock: 10, imageUrl: '', isAvailable: true, monthlySales: 5, lowStockAlert: 5, description: ''
      );
      final p2 = ProductModel(
        id: '2', retailerId: 'admin123', name: 'Alpha', sku: 'A-1', category: 'Cat2', brand: 'B2', 
        price: 10000, moq: 1, stock: 2, imageUrl: '', isAvailable: true, monthlySales: 15, lowStockAlert: 5, description: ''
      );

      final List<ProductModel> list = [p1, p2];

      // Act & Assert — Menguji filter berdasarkan kategori
      final c1Filtered = adminProductController.filterAndSortProducts(list, 'Cat1', '', false, 'Name A-Z');
      expect(c1Filtered.length, 1);
      expect(c1Filtered.first.name, 'Zebra');

      // Act & Assert — Menguji sorting berdasarkan nama A-Z
      final sortedAZ = adminProductController.filterAndSortProducts(list, 'All', '', false, 'Name A-Z');
      expect(sortedAZ.first.name, 'Alpha');
      
      // Act & Assert — Menguji filter berdasarkan pencarian nama
      final searchFiltered = adminProductController.filterAndSortProducts(list, 'All', 'Alpha', false, 'Name A-Z');
      expect(searchFiltered.length, 1);
      expect(searchFiltered.first.name, 'Alpha');

      // Act & Assert — Menguji filter In Stock (hanya produk dengan stok > lowStockAlert)
      final inStockFiltered = adminProductController.filterAndSortProducts(list, 'All', '', true, 'Name A-Z');
      expect(inStockFiltered.length, 1); 
      expect(inStockFiltered.first.name, 'Zebra');

      // Act & Assert — Menguji sorting berdasarkan Best Selling (penjualan terbanyak di atas)
      final sortedBestSelling = adminProductController.filterAndSortProducts(list, 'All', '', false, 'Best Selling');
      expect(sortedBestSelling.first.name, 'Alpha'); 
    });

    test('addSupplyProduct harus mengatur retailerId dan menyimpan produk ke Firestore', () async {
      // Arrange — Membuat produk baru dengan retailerId kosong (akan diisi dari user login)
      final product = ProductModel(
        retailerId: '', name: 'Produk Uji', category: 'Kategori', price: 10000, stock: 10, description: 'Deskripsi Uji', imageUrl: ''
      );

      // Act — Memanggil addSupplyProduct() untuk menyimpan produk ke Firestore
      await adminProductController.addSupplyProduct(product);

      // Assert — Memverifikasi produk tersimpan dan retailerId diisi dari mockAuth
      final snapshot = await fakeFirestore.collection('products').get();
      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.data()['retailerId'], 'admin123');
      expect(snapshot.docs.first.data()['name'], 'Produk Uji');
    });

    test('updateSupplyProduct harus memperbarui dokumen Firestore dengan benar', () async {
      // Arrange — Menambahkan produk awal ke Fake Firestore
      final product = ProductModel(
        id: 'prod1', retailerId: 'admin123', name: 'Produk Lama', category: 'Kategori', price: 10000, stock: 10, description: 'Deskripsi Lama', imageUrl: ''
      );
      await fakeFirestore.collection('products').doc('prod1').set(product.toMap());

      // Act — Mengubah nama produk lalu memanggil updateSupplyProduct()
      product.name = 'Nama Produk Baru';
      await adminProductController.updateSupplyProduct(product);

      // Assert — Memverifikasi nama berubah dan field updatedAt ditambahkan
      final doc = await fakeFirestore.collection('products').doc('prod1').get();
      expect(doc.data()!['name'], 'Nama Produk Baru');
      expect(doc.data()!.containsKey('updatedAt'), true);
    });
  });
}
