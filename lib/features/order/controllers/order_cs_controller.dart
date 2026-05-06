import 'package:flutter/material.dart';
import '../../../core/error/failures.dart';
import '../../../core/repositories/order_repository.dart';
import '../../../core/utils/result.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import 'order_sort_strategies.dart';

class OrderCsController extends ChangeNotifier {
  final OrderRepository _orderRepository;
  final OrderService _orderService;

  OrderCsController({
    OrderRepository? orderRepository,
    OrderService? orderService,
  })  : _orderRepository = orderRepository ?? OrderRepository(),
        _orderService = orderService ?? OrderService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<OrderModel> _orders = [];
  List<OrderModel> get orders => _orders;

  List<OrderModel> _filteredOrders = [];
  List<OrderModel> get filteredOrders => _filteredOrders;

  String _searchQuery = '';
  String _statusFilter = 'all';
  String _selectedSort = 'Newest';
  String get selectedSort => _selectedSort;

  final Map<String, OrderSortStrategy> _sortStrategies = {
    'Newest': SortByNewest(),
    'Oldest': SortByOldest(),
    'Price (High-Low)': SortByPriceHighToLow(),
    'Price (Low-High)': SortByPriceLowToHigh(),
  };

  Future<void> fetchAllOrders() async {
    _setLoading(true);
    _clearError();

    final result = await getAllOrders();
    result.fold(
      (orders) {
        _orders = orders;
        _applyFilters();
        _setLoading(false);
      },
      (failure) {
        _setError(failure.message);
        _setLoading(false);
      },
    );
  }

  Future<Result<List<OrderModel>>> getAllOrders() async {
    try {
      final orders = await _orderRepository.getAllOrders();
      return Result.success(orders);
    } catch (e) {
      return Result.failure(ServerFailure('Gagal memuat pesanan'));
    }
  }

  void searchOrders(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void filterByStatus(String status) {
    _statusFilter = status;
    _applyFilters();
  }

  void setSort(String sort) {
    _selectedSort = sort;
    _applyFilters();
  }

  void _applyFilters() {
    var filtered = List<OrderModel>.from(_orders);

    if (_searchQuery.isNotEmpty) {
      final search = _searchQuery.toLowerCase();
      filtered = filtered.where((order) =>
          order.orderId.toLowerCase().contains(search) ||
          order.fullName.toLowerCase().contains(search)).toList();
    }

    if (_statusFilter != 'all') {
      filtered = filtered.where((order) => order.status == _statusFilter).toList();
    }

    _sortStrategies[_selectedSort]?.sort(filtered);

    _filteredOrders = filtered;
    notifyListeners();
  }

  Future<Result<void>> updateOrderStatus(String orderId, String newStatus, String userId) async {
    _setLoading(true);
    _clearError();

    final result = await _orderService.updateStatusWithNotification(
      orderId: orderId,
      newStatus: newStatus,
      userId: userId,
    );

    if (result.isSuccess) {
      await _refreshOrderInList(orderId);
    } else {
      _setError(result.failure?.message);
    }

    _setLoading(false);
    return result;
  }

  Future<Result<void>> cancelOrder(String orderId, String userId) async {
    _setLoading(true);
    _clearError();

    final result = await _orderService.cancelOrderWithNotification(
      orderId: orderId,
      userId: userId,
    );

    if (result.isSuccess) {
      await _refreshOrderInList(orderId);
    } else {
      _setError(result.failure?.message);
    }

    _setLoading(false);
    return result;
  }

  Future<OrderModel?> getOrderById(String orderId) async {
    return _orderRepository.getOrderById(orderId);
  }

  Future<void> _refreshOrderInList(String orderId) async {
    final updatedOrder = await _orderRepository.getOrderById(orderId);
    if (updatedOrder != null) {
      final index = _orders.indexWhere((o) => o.orderId == orderId);
      if (index != -1) {
        _orders[index] = updatedOrder;
        _applyFilters();
      }
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}