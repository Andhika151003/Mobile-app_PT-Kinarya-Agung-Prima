import 'package:flutter/material.dart';
import '../../../core/repositories/order_repository.dart';
import '../../../core/utils/result.dart';
import '../../../core/error/failures.dart';
import '../models/order.dart';
import '../services/order_service.dart';

class OrderAdminController extends ChangeNotifier {
  final OrderRepository _orderRepository;
  final OrderService _orderService;

  OrderAdminController({
    OrderRepository? orderRepository,
    OrderService? orderService,
  })  : _orderRepository = orderRepository ?? OrderRepository(),
        _orderService = orderService ?? OrderService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<Result<List<OrderModel>>> getAllOrders() async {
    try {
      final orders = await _orderRepository.getAllOrders();
      return Result.success(orders);
    } catch (e) {
      return Result.failure(DatabaseFailure('Gagal memuat pesanan'));
    }
  }

  Future<Result<void>> updateStatus(String orderId, String newStatus, String userId) async {
    _setLoading(true);
    final result = await _orderService.updateStatusWithNotification(
      orderId: orderId,
      newStatus: newStatus,
      userId: userId,
    );
    _setLoading(false);
    return result;
  }

  List<OrderModel> applyFilters({
    required List<OrderModel> allOrders,
    required String selectedFilter,
    required String searchQuery,
  }) {
    var results = List<OrderModel>.from(allOrders);

    results = _filterByTime(results, selectedFilter);
    results = _filterByStatus(results, selectedFilter);
    results = _filterBySearch(results, searchQuery);

    return results;
  }

  List<OrderModel> _filterByTime(List<OrderModel> orders, String filter) {
    final now = DateTime.now();
    if (filter == 'Today') {
      return orders.where((o) => _isSameDay(o.createdAt, now)).toList();
    } else if (filter == 'This Week') {
      final weekAgo = now.subtract(const Duration(days: 7));
      return orders.where((o) => o.createdAt?.isAfter(weekAgo) ?? false).toList();
    }
    return orders;
  }

  List<OrderModel> _filterByStatus(List<OrderModel> orders, String filter) {
    const statuses = ['Ordered', 'Paid', 'Shipped', 'Delivered', 'Cancelled', 'Expired'];
    if (statuses.contains(filter)) {
      return orders.where((o) => o.status == filter).toList();
    }
    return orders;
  }

  List<OrderModel> _filterBySearch(List<OrderModel> orders, String query) {
    if (query.isEmpty) return orders;
    final q = query.toLowerCase();
    return orders.where((o) {
      return o.orderId.toLowerCase().contains(q) ||
             o.fullName.toLowerCase().contains(q) ||
             o.shippingAddress.toLowerCase().contains(q);
    }).toList();
  }

  bool _isSameDay(DateTime? d1, DateTime d2) {
    if (d1 == null) return false;
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  // --- Backward Compatibility for Views ---
  
  Future<List<OrderModel>> getAllOrdersAdmin() async {
    final result = await getAllOrders();
    return result.data ?? [];
  }

  Future<OrderModel?> getOrderById(String orderId) async {
    return _orderRepository.getOrderById(orderId);
  }

  Future<void> updateOrderStatus(String orderId, String newStatus, String userId) async {
    await updateStatus(orderId, newStatus, userId);
  }

  List<OrderModel> filterAndSearchOrders(
    List<OrderModel> allOrders,
    String selectedFilter,
    String searchQuery,
  ) {
    return applyFilters(
      allOrders: allOrders,
      selectedFilter: selectedFilter,
      searchQuery: searchQuery,
    );
  }

  Future<Result<void>> cancelOrder(String orderId, String userId) async {
    _setLoading(true);
    final result = await _orderService.cancelOrderWithNotification(
      orderId: orderId,
      userId: userId,
    );
    _setLoading(false);
    return result;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}