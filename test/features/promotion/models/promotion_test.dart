import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce/features/promotion/models/promotion.dart';

void main() {
  group('PromotionModel Tests', () {
    final now = DateTime.now();

    test('toMap converts to Firestore-compatible Map', () {
      final promotion = PromotionModel(
        id: 'promo1',
        title: 'Big Sale',
        description: 'Sale in summer',
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

      final map = promotion.toMap();

      expect(map['title'], 'Big Sale');
      expect(map['discountValue'], 20.0);
      expect(map['productIds'], ['prod1', 'prod2']);
      expect(map['startDate'], isA<Timestamp>()); // should convert to timestamp
    });

    test('fromMap parses Firestore Map correctly', () {
      final map = {
        'title': 'Flash Sale',
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

      final promotion = PromotionModel.fromMap('doc123', map);

      expect(promotion.id, 'doc123');
      expect(promotion.title, 'Flash Sale');
      expect(promotion.discountType, 'fixed');
      expect(promotion.discountValue, 50000.0);
      expect(promotion.startDate.day, now.day);
    });

    test('isActive returns true if active and within date range', () {
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

      expect(activePromo.isActive, isTrue);
      expect(expiredPromo.isActive, isFalse);
    });

    test('discountText formats text correctly', () {
      final percentage = PromotionModel(
        title: '', description: '', discountType: 'percentage', discountValue: 25,
        productIds: [], applicableTo: 'all', startDate: now, endDate: now, startTime: '', endTime: '', status: 'active', sku: '', createdAt: now, createdBy: ''
      );
      final fixed = PromotionModel(
        title: '', description: '', discountType: 'fixed', discountValue: 15000,
        productIds: [], applicableTo: 'all', startDate: now, endDate: now, startTime: '', endTime: '', status: 'active', sku: '', createdAt: now, createdBy: ''
      );

      expect(percentage.discountText, '25% OFF');
      expect(fixed.discountText, 'Rp 15000 OFF');
    });
  });
}
