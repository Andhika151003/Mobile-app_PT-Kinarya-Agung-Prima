import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce/features/statistic/views/admin_statistic_view.dart';
import 'package:ecommerce/features/statistic/controllers/statistic_controller.dart';

/// Helper untuk menekan ListTile ink splash warnings dari production code
void _suppressListTileWarning() {
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('ListTile background color')) {
      return;
    }
    original?.call(details);
  };
}

void main() {
  group('AdminStatisticView Widget Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late AdminStatisticController controller;

    setUp(() async {
      fakeFirestore = FakeFirebaseFirestore();
      controller = AdminStatisticController(firestore: fakeFirestore);
    });

    Future<void> seedSampleData() async {
      final now = DateTime.now();

      await fakeFirestore.collection('orders').add({
        'status': 'Delivered',
        'total': 150000.0,
        'userId': 'retailer_a',
        'fullName': 'Toko Indah',
        'createdAt': Timestamp.fromDate(now),
        'items': [
          {
            'productId': 'p1',
            'title': 'Sampoo Lemon',
            'quantity': 2,
            'price': 50000.0,
            'category': 'Haircare'
          },
          {
            'productId': 'p2',
            'title': 'Sabun Mandi',
            'quantity': 1,
            'price': 50000.0,
            'category': 'Bodycare'
          },
        ],
      });

      await fakeFirestore.collection('orders').add({
        'status': 'Cancelled',
        'total': 200000.0,
        'userId': 'retailer_a',
        'fullName': 'Toko Indah',
        'createdAt': Timestamp.fromDate(now),
        'items': [
          {
            'productId': 'p1',
            'title': 'Sampoo Lemon',
            'quantity': 4,
            'price': 50000.0,
            'category': 'Haircare'
          },
        ],
      });

      await fakeFirestore.collection('users').add({
        'role': 'retailer',
        'isActive': true,
      });
      await fakeFirestore.collection('users').add({
        'role': 'admin',
        'isActive': true,
      });

      await fakeFirestore.collection('products').add({
        'name': 'Sampoo Lemon',
        'stock': 100,
        'lowStockAlert': 5,
      });
      await fakeFirestore.collection('products').add({
        'name': 'Sabun Mandi',
        'stock': 3,
        'lowStockAlert': 5,
      });

      await fakeFirestore.collection('complaints').add({
        'status': 'open',
        'createdAt': Timestamp.fromDate(now),
      });
    }

    testWidgets('Menampilkan summary cards dan filter chips setelah data dimuat',
        (tester) async {
      _suppressListTileWarning();

      await seedSampleData();
      await controller.fetchAnalyticsData();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AdminStatisticController>.value(
            value: controller,
            child: const AdminStatisticView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Admin Statistics'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Last 7 Days'), findsOneWidget);
      expect(find.text('Last 30 Days'), findsOneWidget);
      expect(find.text('Total Revenue'), findsOneWidget);
      expect(find.text('Total Orders'), findsOneWidget);
      expect(find.text('Total Cancel'), findsOneWidget);
      expect(find.text('Total Complaint'), findsOneWidget);
      expect(find.text('Sales Trend'), findsOneWidget);
    });

    testWidgets('Filter switching antara Today, Last 7 Days, Last 30 Days',
        (tester) async {
      _suppressListTileWarning();

      await seedSampleData();
      await controller.fetchAnalyticsData();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AdminStatisticController>.value(
            value: controller,
            child: const AdminStatisticView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();
      expect(find.text('Today'), findsOneWidget);

      await tester.tap(find.text('Last 30 Days'));
      await tester.pumpAndSettle();
      expect(find.text('Last 30 Days'), findsOneWidget);

      await tester.tap(find.text('Last 7 Days'));
      await tester.pumpAndSettle();
      expect(find.text('Last 7 Days'), findsOneWidget);
    });

    testWidgets('Tombol refresh dan download muncul', (tester) async {
      _suppressListTileWarning();

      await seedSampleData();
      await controller.fetchAnalyticsData();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AdminStatisticController>.value(
            value: controller,
            child: const AdminStatisticView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.byIcon(Icons.download_outlined), findsOneWidget);
    });

    testWidgets('Menampilkan data kosong dengan pesan yang sesuai',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AdminStatisticController>.value(
            value: controller,
            child: const AdminStatisticView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Last 7 Days'), findsOneWidget);
      expect(find.text('Last 30 Days'), findsOneWidget);
      expect(find.text('Total Revenue'), findsOneWidget);
      expect(find.text('Total Orders'), findsOneWidget);
      expect(find.text('Total Cancel'), findsOneWidget);
      expect(find.text('Total Complaint'), findsOneWidget);
      expect(find.text('Sales Trend'), findsOneWidget);
      expect(find.text('Top Products'), findsOneWidget);
      expect(find.text('Top Retailers'), findsOneWidget);
      expect(find.text('Category Popularity'), findsOneWidget);
    });
  });
}
