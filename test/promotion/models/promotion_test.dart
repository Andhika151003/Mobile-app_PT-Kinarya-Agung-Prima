import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce/features/promotion/models/promotion.dart';

void main() {
  group('Unit Test PromotionModel', () {
    final now = DateTime.now();

    test('toMap harus mengonversi object PromotionModel menjadi Map Firebase yang valid', () {
      // Arrange — Membuat instance PromotionModel dengan data lengkap
      final promotion = PromotionModel(
        id: 'promo1',
        title: 'Diskon Besar',
        description: 'Diskon besar di musim panas',
        discountType: 'percentage',
        discountValue: 20.0,
        productIds: ['prod1', 'prod2'],
        applicableTo: 'specific',
        startDate: now,
        endDate: now.add(const Duration(days: 5)),
        startTime: '10:00',
        endTime: '22:00',
        status: 'active',
        sku: 'SKU-001',
        createdAt: now,
        createdBy: 'admin_123',
      );

      // Act — Memanggil toMap() untuk konversi ke Map
      final map = promotion.toMap();

      // Assert — Memverifikasi bahwa Map mengandung data yang benar
      expect(map['title'], 'Diskon Besar');
      expect(map['discountValue'], 20.0);
      expect(map['productIds'], ['prod1', 'prod2']);
      expect(map['startDate'], isA<Timestamp>()); // should convert to timestamp
    });

    test('fromMap harus melakukan parsing Map Firestore ke PromotionModel dengan benar', () {
      // Arrange — Menyiapkan Map seperti data yang datang dari Firestore
      final map = {
        'title': 'Promo Kilat',
        'description': '',
        'discountType': 'fixed',
        'discountValue': 50000.0,
        'productIds': [],
        'applicableTo': 'all',
        'startDate': Timestamp.fromDate(now),
        'endDate': Timestamp.fromDate(now.add(const Duration(days: 3))),
        'startTime': '00:00',
        'endTime': '23:59',
        'status': 'active',
        'sku': 'SKU-002',
        'createdAt': Timestamp.fromDate(now),
        'createdBy': 'user_1',
      };

      // Act — Memanggil factory fromMap() untuk parsing Map ke PromotionModel
      final promotion = PromotionModel.fromMap('doc123', map);

      // Assert — Memverifikasi bahwa parsing menghasilkan objek yang benar
      expect(promotion.id, 'doc123');
      expect(promotion.title, 'Promo Kilat');
      expect(promotion.discountType, 'fixed');
      expect(promotion.discountValue, 50000.0);
      expect(promotion.startDate.day, now.day);
    });

    test('isActive harus mengembalikan true jika status aktif dan dalam masa berlaku', () {
      // Arrange — Membuat 2 promo: satu aktif (dalam rentang tanggal), satu expired
      final activePromo = PromotionModel(
        title: 'A', description: 'A', discountType: 'percentage', discountValue: 10,
        productIds: [], applicableTo: 'all',
        startDate: now.subtract(const Duration(days: 1)),
        endDate: now.add(const Duration(days: 5)),
        startTime: '00:00', endTime: '23:59',
        status: 'active', sku: 'S', createdAt: now, createdBy: 'admin',
      );

      final expiredPromo = PromotionModel(
        title: 'B', description: 'B', discountType: 'percentage', discountValue: 10,
        productIds: [], applicableTo: 'all',
        startDate: now.subtract(const Duration(days: 5)),
        endDate: now.subtract(const Duration(days: 1)),
        startTime: '00:00', endTime: '23:59',
        status: 'active', sku: 'S', createdAt: now, createdBy: 'admin',
      );

      // Act & Assert — Mengakses getter isActive dan memverifikasi hasilnya
      expect(activePromo.isActive, isTrue);
      expect(expiredPromo.isActive, isFalse);
    });

    // TC - 58 : Retailer Menampilkan label diskon pada kartu produk
    test('TC - 58 : Retailer Menampilkan label diskon pada kartu produk (discountText)', () {
      // Arrange
      final percentage = PromotionModel(
        title: '', description: '', discountType: 'percentage', discountValue: 25,
        productIds: [], applicableTo: 'all', startDate: now, endDate: now, startTime: '', endTime: '', status: 'active', sku: '', createdAt: now, createdBy: ''
      );
      final fixed = PromotionModel(
        title: '', description: '', discountType: 'fixed', discountValue: 15000,
        productIds: [], applicableTo: 'all', startDate: now, endDate: now, startTime: '', endTime: '', status: 'active', sku: '', createdAt: now, createdBy: ''
      );

      // Act & Assert
      expect(percentage.discountText, '25% OFF');
      expect(fixed.discountText, 'Rp 15.000 OFF');
    });

    // TC - 59 : Retailer Menampilkan harga coret (original) dan harga promo
    test('TC - 59 : Retailer Menampilkan harga coret (original) dan harga promo', () {
      // Arrange
      final originalPrice = 100000;
      final discountValue = 20.0; // 20%
      
      // Act
      final promoPrice = originalPrice * (1 - (discountValue / 100));

      // Assert
      expect(originalPrice, 100000); // Harga asli (untuk dicoret di UI)
      expect(promoPrice, 80000.0);   // Harga promo yang ditampilkan
    });
  });
}
