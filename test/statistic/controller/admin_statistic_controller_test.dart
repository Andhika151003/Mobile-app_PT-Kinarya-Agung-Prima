import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce/features/statistic/controllers/statistic_controller.dart';

void main() {
  late AdminStatisticController controller;
  late FakeFirebaseFirestore firestore;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    controller = AdminStatisticController(firestore: firestore);
  });

  group('Enhanced AdminStatisticController Tests', () {
    test('fetchAnalyticsData aggregates filters and rankings correctly', () async {
      final now = DateTime.now();
      
      // Setup orders
      // Order 1: Success, Recent
      await firestore.collection('orders').add({
        'status': 'Delivered',
        'total': 100000.0,
        'userId': 'user1',
        'fullName': 'Toko A',
        'createdAt': Timestamp.fromDate(now),
        'items': [
          {'title': 'Product 1', 'quantity': 2, 'price': 40000.0, 'category': 'Food'},
          {'title': 'Product 2', 'quantity': 1, 'price': 20000.0, 'category': 'Drink'},
        ],
      });

      // Order 2: Success, Recent
      await firestore.collection('orders').add({
        'status': 'Paid',
        'total': 50000.0,
        'userId': 'user2',
        'fullName': 'Toko B',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 1))),
        'items': [
          {'title': 'Product 1', 'quantity': 1, 'price': 40000.0, 'category': 'Food'},
        ],
      });

      // Order 3: Success, Old (9 days ago)
      await firestore.collection('orders').add({
        'status': 'Delivered',
        'total': 300000.0,
        'userId': 'user1',
        'fullName': 'Toko A',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 9))),
        'items': [
          {'title': 'Product 3', 'quantity': 1, 'price': 300000.0, 'category': 'Electronics'},
        ],
      });

      // Test Today Filter
      controller.setFilter(StatFilter.today);
      await controller.fetchAnalyticsData();

      expect(controller.totalOrders, equals(2));
      expect(controller.totalRevenue, equals(150000.0));
      expect(controller.topRetailers.first['name'], equals('Toko A'));
      expect(controller.topProducts.first['name'], equals('Product 1'));
      expect(controller.categoryOrderCounts['Food'], equals(2));

      // Test Week Filter
      controller.setFilter(StatFilter.week);
      await controller.fetchAnalyticsData();
      expect(controller.totalOrders, equals(2)); // Only the 2 recent ones

      // Test All Filter
      controller.setFilter(StatFilter.month);
      await controller.fetchAnalyticsData();
      expect(controller.totalOrders, equals(3));
      expect(controller.totalRevenue, equals(450000.0));
    });
  });
}
