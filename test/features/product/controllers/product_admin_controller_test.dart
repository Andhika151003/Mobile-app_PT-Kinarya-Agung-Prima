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

  group('AdminProductController Tests', () {
    test('filterAndSortProducts sorts and filters correctly', () {
      final p1 = ProductModel(
        id: '1', retailerId: 'admin123', name: 'Zebra', sku: 'Z-1', category: 'Cat1', brand: 'B1', 
        price: 15000, moq: 1, stock: 10, imageUrl: '', isAvailable: true, monthlySales: 5, lowStockAlert: 5, description: ''
      );
      final p2 = ProductModel(
        id: '2', retailerId: 'admin123', name: 'Alpha', sku: 'A-1', category: 'Cat2', brand: 'B2', 
        price: 10000, moq: 1, stock: 2, imageUrl: '', isAvailable: true, monthlySales: 15, lowStockAlert: 5, description: ''
      );

      final List<ProductModel> list = [p1, p2];

      // Test category filter
      final c1Filtered = adminProductController.filterAndSortProducts(list, 'Cat1', '', false, 'Name A-Z');
      expect(c1Filtered.length, 1);
      expect(c1Filtered.first.name, 'Zebra');

      // Test sort A-Z
      final sortedAZ = adminProductController.filterAndSortProducts(list, 'All', '', false, 'Name A-Z');
      expect(sortedAZ.first.name, 'Alpha');
      
      // Test search
      final searchFiltered = adminProductController.filterAndSortProducts(list, 'All', 'Alpha', false, 'Name A-Z');
      expect(searchFiltered.length, 1);
      expect(searchFiltered.first.name, 'Alpha');

      // Test In Stock
      final inStockFiltered = adminProductController.filterAndSortProducts(list, 'All', '', true, 'Name A-Z');
      expect(inStockFiltered.length, 1); 
      expect(inStockFiltered.first.name, 'Zebra');

      // Test sort Best Selling
      final sortedBestSelling = adminProductController.filterAndSortProducts(list, 'All', '', false, 'Best Selling');
      expect(sortedBestSelling.first.name, 'Alpha'); 
    });

    test('addSupplyProduct sets retailerId and saves to firestore', () async {
      final product = ProductModel(
        retailerId: '', name: 'Test Product', category: 'Cat', price: 10, stock: 10, description: 'Desc', imageUrl: ''
      );

      await adminProductController.addSupplyProduct(product);

      final snapshot = await fakeFirestore.collection('products').get();
      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.data()['retailerId'], 'admin123');
      expect(snapshot.docs.first.data()['name'], 'Test Product');
    });

    test('updateSupplyProduct updates firestore document correctly', () async {
      final product = ProductModel(
        id: 'prod1', retailerId: 'admin123', name: 'Old Product', category: 'Cat', price: 10, stock: 10, description: 'Desc', imageUrl: ''
      );
      await fakeFirestore.collection('products').doc('prod1').set(product.toMap());

      product.name = 'New Name Update';
      await adminProductController.updateSupplyProduct(product);

      final doc = await fakeFirestore.collection('products').doc('prod1').get();
      expect(doc.data()!['name'], 'New Name Update');
      expect(doc.data()!.containsKey('updatedAt'), true);
    });
  });
}
