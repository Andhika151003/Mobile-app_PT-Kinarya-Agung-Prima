  import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce/features/statistic/controllers/statistic_controller.dart';

void main() {
  late AdminStatisticController controller;
  late FakeFirebaseFirestore mockFirestore;

  setUp(() {
    mockFirestore = FakeFirebaseFirestore();
    controller = AdminStatisticController(firestore: mockFirestore);
  });

  group('AdminStatisticController - Initial States', () {
    test('Default values are set correctly before fetching data', () {
      expect(controller.isLoading, false);
      expect(controller.currentFilter, StatFilter.week);
      expect(controller.totalRevenue, 0.0);
      expect(controller.totalOrders, 0);
      expect(controller.completedOrders, 0);
      expect(controller.cancelledOrders, 0);
      expect(controller.totalComplaints, 0);
      expect(controller.totalRetailers, 0);
      expect(controller.activeRetailers, 0);
      expect(controller.totalCS, 0);
      expect(controller.activeCS, 0);
      expect(controller.totalProducts, 0);
      expect(controller.lowStockCount, 0);
      expect(controller.orderStatusCounts, isEmpty);
      expect(controller.categoryOrderCounts, isEmpty);
      expect(controller.topProducts, isEmpty);
      expect(controller.topRetailers, isEmpty);
      expect(controller.salesTrend, isEmpty);
    });
  });

  group('AdminStatisticController - Filter & Analytics Aggregations', () {
    test('fetchAnalyticsData aggregates orders, revenue, and rankings correctly', () async {
      final now = DateTime.now();

      // Seed Orders
      // Order 1: Delivered (successful), total 150000, under Today filter
      await mockFirestore.collection('orders').add({
        'status': 'Delivered',
        'total': 150000.0,
        'userId': 'retailer_a',
        'fullName': 'Toko Indah',
        'createdAt': Timestamp.fromDate(now),
        'items': [
          {'productId': 'p1', 'title': 'Sampoo Lemon', 'quantity': 2, 'price': 50000.0, 'category': 'Haircare'},
          {'productId': 'p2', 'title': 'Sabun Mandi', 'quantity': 1, 'price': 50000.0, 'category': 'Bodycare'},
        ],
      });

      // Order 2: Paid (successful), total 80000, under Today filter
      await mockFirestore.collection('orders').add({
        'status': 'Paid',
        'total': 80000.0,
        'userId': 'retailer_b',
        'fullName': 'Toko Berkah',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(minutes: 30))),
        'items': [
          {'productId': 'p2', 'title': 'Sabun Mandi', 'quantity': 1, 'price': 50000.0, 'category': 'Bodycare'},
          {'productId': 'p3', 'title': 'Pasta Gigi', 'quantity': 1, 'price': 30000.0, 'category': 'Dental'},
        ],
      });

      // Order 3: Cancelled (unsuccessful), total 200000, under Today filter
      await mockFirestore.collection('orders').add({
        'status': 'Cancelled',
        'total': 200000.0,
        'userId': 'retailer_a',
        'fullName': 'Toko Indah',
        'createdAt': Timestamp.fromDate(now),
        'items': [
          {'productId': 'p1', 'title': 'Sampoo Lemon', 'quantity': 4, 'price': 50000.0, 'category': 'Haircare'},
        ],
      });

      // Order 4: Shipped (successful), total 300000, old (4 days ago - under Week & Month filter, but not Today)
      await mockFirestore.collection('orders').add({
        'status': 'Shipped',
        'total': 300000.0,
        'userId': 'retailer_c',
        'fullName': 'Toko Ceria',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 4))),
        'items': [
          {'productId': 'p4', 'title': 'Parfum Gold', 'quantity': 1, 'price': 300000.0, 'category': 'Fragrance'},
        ],
      });

      // Order 5: Settled (successful), total 400000, very old (15 days ago - under Month filter, but not Week/Today)
      await mockFirestore.collection('orders').add({
        'status': 'Settled',
        'total': 400000.0,
        'userId': 'retailer_a',
        'fullName': 'Toko Indah',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 15))),
        'items': [
          {'productId': 'p1', 'title': 'Sampoo Lemon', 'quantity': 8, 'price': 50000.0, 'category': 'Haircare'},
        ],
      });

      // --- 1. Test StatFilter.today ---
      controller.setFilter(StatFilter.today);
      await controller.fetchAnalyticsData();

      // Today should see Order 1, Order 2, Order 3
      expect(controller.totalOrders, 3);
      // Revenue is Order 1 (150000) + Order 2 (80000) = 230000 (Cancelled order excluded)
      expect(controller.totalRevenue, 230000.0);
      expect(controller.completedOrders, 1); // Only Order 1 (Delivered)
      expect(controller.cancelledOrders, 1); // Order 3 (Cancelled)

      // Category counts for successful items: Haircare(1), Bodycare(2), Dental(1)
      expect(controller.categoryOrderCounts['Haircare'], 1);
      expect(controller.categoryOrderCounts['Bodycare'], 2);
      expect(controller.categoryOrderCounts['Dental'], 1);

      // Top products ranking
      // Sabun Mandi (p2): qty=2, revenue=100000.0
      // Sampoo Lemon (p1): qty=2, revenue=100000.0
      // Pasta Gigi (p3): qty=1, revenue=30000.0
      expect(controller.topProducts.length, 3);
      expect(controller.topProducts[0]['name'], anyOf('Sabun Mandi', 'Sampoo Lemon'));
      expect(controller.topProducts[2]['name'], 'Pasta Gigi');

      // Top retailers ranking
      // Toko Indah (retailer_a): spent = 150000.0
      // Toko Berkah (retailer_b): spent = 80000.0
      expect(controller.topRetailers.length, 2);
      expect(controller.topRetailers[0]['name'], 'Toko Indah');
      expect(controller.topRetailers[0]['spent'], 150000.0);
      expect(controller.topRetailers[1]['name'], 'Toko Berkah');
      expect(controller.topRetailers[1]['spent'], 80000.0);

      // Sales trend check for Today (24 hour buckets)
      expect(controller.salesTrend.length, 24);

      // --- 2. Test StatFilter.week ---
      controller.setFilter(StatFilter.week);
      await controller.fetchAnalyticsData();

      // Week should see Orders 1, 2, 3, and 4 (Delivered, Paid, Cancelled, Shipped)
      expect(controller.totalOrders, 4);
      // Revenue: 150000 + 80000 + 300000 = 530000
      expect(controller.totalRevenue, 530000.0);
      expect(controller.completedOrders, 1); // Delivered (Settled is excluded because it's 15 days old)
      expect(controller.cancelledOrders, 1);

      // Sales trend check for Week (7 day buckets)
      expect(controller.salesTrend.length, 7);

      // --- 3. Test StatFilter.month ---
      controller.setFilter(StatFilter.month);
      await controller.fetchAnalyticsData();

      // Month should see all 5 orders
      expect(controller.totalOrders, 5);
      // Revenue: 150000 + 80000 + 300000 + 400000 = 930000
      expect(controller.totalRevenue, 930000.0);
      expect(controller.completedOrders, 2); // Delivered (Order 1) & Settled (Order 5)
      expect(controller.cancelledOrders, 1);

      // Sales trend check for Month (30 day buckets)
      expect(controller.salesTrend.length, 30);
    });
  });

  group('AdminStatisticController - User Stats', () {
    test('fetchAnalyticsData counts retailers and CS correctly based on role and active state', () async {
      // Seed Users
      // Retailer 1: Active
      await mockFirestore.collection('users').doc('user1').set({
        'role': 'retailer',
        'isActive': true,
      });
      // Retailer 2: Active
      await mockFirestore.collection('users').doc('user2').set({
        'role': 'retailer',
        'isActive': true,
      });
      // Retailer 3: Inactive
      await mockFirestore.collection('users').doc('user3').set({
        'role': 'retailer',
        'isActive': false,
      });
      // CS 1: Active
      await mockFirestore.collection('users').doc('user4').set({
        'role': 'cs',
        'isActive': true,
      });
      // CS 2: Inactive
      await mockFirestore.collection('users').doc('user5').set({
        'role': 'cs',
        'isActive': false,
      });
      // Admin: Should not be counted as retailer/CS
      await mockFirestore.collection('users').doc('user6').set({
        'role': 'admin',
        'isActive': true,
      });

      await controller.fetchAnalyticsData();

      expect(controller.totalRetailers, 3);
      expect(controller.activeRetailers, 2);
      expect(controller.totalCS, 2);
      expect(controller.activeCS, 1);
    });
  });

  group('AdminStatisticController - Product Stats', () {
    test('fetchAnalyticsData counts products and calculates low stock correctly', () async {
      // Seed Products
      // Product 1: stock (10) > alert (5) -> Not low stock
      await mockFirestore.collection('products').add({
        'stock': 10,
        'lowStockAlert': 5,
      });
      // Product 2: stock (3) <= alert (5) -> Low stock
      await mockFirestore.collection('products').add({
        'stock': 3,
        'lowStockAlert': 5,
      });
      // Product 3: stock (5) <= default alert (5) -> Low stock
      await mockFirestore.collection('products').add({
        'stock': 5,
      });
      // Product 4: stock (10) > default alert (5) -> Not low stock
      await mockFirestore.collection('products').add({
        'stock': 10,
      });

      await controller.fetchAnalyticsData();

      expect(controller.totalProducts, 4);
      expect(controller.lowStockCount, 2); // Product 2 and Product 3
    });
  });

  group('AdminStatisticController - Complaint Stats', () {
    test('fetchAnalyticsData counts complaints matching selected filter timeframes', () async {
      final now = DateTime.now();

      // Seed complaints
      // Complaint 1: Today
      await mockFirestore.collection('complaints').add({
        'createdAt': Timestamp.fromDate(now),
      });
      // Complaint 2: 3 days ago (under Week & Month filters)
      await mockFirestore.collection('complaints').add({
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 3))),
      });
      // Complaint 3: 12 days ago (under Month filter only)
      await mockFirestore.collection('complaints').add({
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 12))),
      });

      // Today filter
      controller.setFilter(StatFilter.today);
      await controller.fetchAnalyticsData();
      expect(controller.totalComplaints, 1);

      // Week filter
      controller.setFilter(StatFilter.week);
      await controller.fetchAnalyticsData();
      expect(controller.totalComplaints, 2);

      // Month filter
      controller.setFilter(StatFilter.month);
      await controller.fetchAnalyticsData();
      expect(controller.totalComplaints, 3);
    });
  });

  group('AdminStatisticController - Error & Disposal Handling', () {
    test('fetchAnalyticsData handles Firestore exception gracefully', () async {
      final brokenFirestore = MockBrokenFirestore();
      final errController = AdminStatisticController(firestore: brokenFirestore);

      expect(errController.isLoading, false);

      // Should complete without throwing exception
      await errController.fetchAnalyticsData();

      expect(errController.isLoading, false);
    });

    test('Disposed controller does not call notifyListeners', () async {
      final listenerCalled = <String>[];
      controller.addListener(() {
        listenerCalled.add('called');
      });

      // Fetch analytics triggers notifyListeners initially & finally
      await controller.fetchAnalyticsData();
      expect(listenerCalled.length, 2);

      listenerCalled.clear();
      controller.dispose();

      // Calling fetch on disposed controller shouldn't notify listeners
      await controller.fetchAnalyticsData();
      expect(listenerCalled, isEmpty);
    });
  });
}

// Custom mock Firestore to test exception handling
class MockBrokenFirestore extends FakeFirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    throw Exception('Firestore operation failed');
  }
}
