import '../../../core/repositories/order_repository.dart';
import '../../../core/utils/result.dart';
import '../../../core/error/failures.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StatisticService {
  final OrderRepository _orderRepository;

  StatisticService({OrderRepository? orderRepository})
      : _orderRepository = orderRepository ?? OrderRepository();

  Future<Result<Map<String, dynamic>>> getRetailStats(String userId) async {
    try {
      final snapshot = await _orderRepository.getOrdersByUserId(userId);
      
      double totalSpent = 0;
      int totalOrders = snapshot.docs.length;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status']?.toString() ?? '';
        if (['Paid', 'Shipped', 'Delivered'].contains(status)) {
          totalSpent += (data['total'] as num?)?.toDouble() ?? 0.0;
        }
      }

      return Result.success({
        'totalOrders': totalOrders,
        'totalSpent': totalSpent,
      });
    } catch (e) {
      return Result.failure(ServerFailure('Gagal memuat statistik: $e'));
    }
  }

  Future<Result<Map<String, dynamic>>> getAdminStats() async {
    try {
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);

      // We might need a method in OrderRepository to get all orders or filter by status
      // For now, let's assume we can get them.
      // Optimization: This should probably be a Cloud Function or more specific query.
      
      final snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('status', whereIn: ['Paid', 'Shipped', 'Delivered'])
          .get();

      double totalRevenue = 0;
      int monthlySalesUnits = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        totalRevenue += (data['total'] as num?)?.toDouble() ?? 0.0;

        final createdAt = data['createdAt'];
        DateTime? orderDate;
        if (createdAt is Timestamp) {
          orderDate = createdAt.toDate();
        } else if (createdAt is String) {
          orderDate = DateTime.tryParse(createdAt);
        }

        if (orderDate != null && orderDate.isAfter(firstDayOfMonth)) {
          final items = data['items'] as List<dynamic>? ?? [];
          for (var item in items) {
            monthlySalesUnits += (item['quantity'] as num?)?.toInt() ?? 0;
          }
        }
      }

      return Result.success({
        'totalRevenue': totalRevenue,
        'monthlySales': monthlySalesUnits,
      });
    } catch (e) {
      return Result.failure(ServerFailure('Gagal memuat statistik admin: $e'));
    }
  }
}
