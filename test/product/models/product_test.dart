import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce/features/product/models/product.dart';

void main() {
  group('Unit Test ProductModel', () {
    test('toMap harus mengonversi ProductModel menjadi Map dengan benar', () {
      // Arrange — Membuat instance ProductModel dengan data lengkap
      final product = ProductModel(
        retailerId: 'retail_1',
        name: 'Kaos Polos',
        sku: 'KP-01',
        category: 'Pakaian',
        price: 50000,
        moq: 12,
        stock: 100,
        lowStockAlert: 10,
        description: 'Bahan katun',
        imageUrl: 'http://image.com',
        isAvailable: true,
      );

      // Act — Memanggil toMap() untuk konversi ke Map
      final map = product.toMap();
      
      // Assert — Memverifikasi Map mengandung data yang sesuai
      expect(map['name'], 'Kaos Polos');
      expect(map['price'], 50000);
      expect(map['isAvailable'], true);
      expect(map['createdAt'], isA<FieldValue>());
    });

    test('fromMap harus melakukan parsing Map Firestore ke ProductModel dengan benar', () {
      // Arrange — Menyiapkan Map seperti data yang datang dari Firestore
      final map = {
        'retailerId': 'retail_2',
        'name': 'Celana Jeans',
        'sku': 'CJ-01',
        'category': 'Pakaian',
        'price': 150000.0,
        'stock': 50,
        'description': '',
        'imageUrl': 'url',
        'imageUrls': ['url1', 'url2'],
      };

      // Act — Memanggil factory fromMap() untuk parsing Map ke ProductModel
      final product = ProductModel.fromMap(map, 'doc_abc');

      // Assert — Memverifikasi bahwa objek ProductModel berisi data yang benar
      expect(product.id, 'doc_abc');
      expect(product.name, 'Celana Jeans');
      expect(product.price, 150000);
      expect(product.stock, 50);
      expect(product.imageUrls?.length, 2);
    });

    test('fromMap harus menangani field null dan kosong dengan nilai default', () {
      // Arrange — Menyiapkan Map dengan field minimal (banyak field tidak ada)
      final map = {
        'name': 'Tanpa Field Lengkap',
        'price': 1000,
        'imageUrl': '',
      };

      // Act — Memanggil fromMap() dengan data yang tidak lengkap
      final product = ProductModel.fromMap(map, 'doc_xyz');

      // Assert — Memverifikasi default values diterapkan untuk field yang hilang
      expect(product.category, 'Uncategorized');
      expect(product.stock, 0);
      expect(product.isAvailable, true);
    });
  });
}
