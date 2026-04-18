import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce/features/product/models/product.dart';

void main() {
  group('ProductModel Tests', () {
    test('toMap converts to Map', () {
      final product = ProductModel(
        retailerId: 'retail_1',
        name: 'Kaos Polos',
        sku: 'KP-01',
        category: 'Pakaian',
        price: 50000,
        wholesalePrice: 45000,
        moq: 12,
        stock: 100,
        lowStockAlert: 10,
        description: 'Bahan katun',
        imageUrl: 'http://image.com',
        isAvailable: true,
      );

      final map = product.toMap();
      
      expect(map['name'], 'Kaos Polos');
      expect(map['price'], 50000);
      expect(map['isAvailable'], true);
      expect(map['createdAt'], isA<FieldValue>());
    });

    test('fromMap parses Firestore Map correctly', () {
      final map = {
        'retailerId': 'retail_2',
        'name': 'Celana Jeans',
        'sku': 'CJ-01',
        'category': 'Pakaian',
        'price': 150000.0, // test double parsing to int
        'stock': 50,
        'description': '',
        'imageUrl': 'url',
        'imageUrls': ['url1', 'url2'],
      };

      final product = ProductModel.fromMap(map, 'doc_abc');

      expect(product.id, 'doc_abc');
      expect(product.name, 'Celana Jeans');
      expect(product.price, 150000);
      expect(product.stock, 50);
      expect(product.imageUrls?.length, 2);
    });

    test('fromMap handles null and missing fields with defaults', () {
      final map = {
        'name': 'Missing All',
        'price': 1000,
        'imageUrl': '',
      };

      final product = ProductModel.fromMap(map, 'doc_xyz');
      expect(product.category, 'Uncategorized');
      expect(product.stock, 0);
      expect(product.isAvailable, true);
    });
  });
}
