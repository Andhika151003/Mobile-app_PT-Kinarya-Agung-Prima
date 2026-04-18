import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order.dart';

class OrderCsController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  Future<void> fetchAllOrders() async {
    _setLoading(true);
    _clearError();

    try {
      print('Fetching orders from Firestore...');
      
      final snapshot = await _firestore
          .collection('orders')
          .get(); 

      print('Jumlah dokumen di Firestore: ${snapshot.docs.length}');

      if (snapshot.docs.isEmpty) {
        print('Tidak ada data order di Firestore');
        _orders = [];
      } else {
        for (var doc in snapshot.docs) {
          print('Order ID: ${doc.data()['orderId']}');
        }
        
        _orders = snapshot.docs.map((doc) {
          return OrderModel.fromMap(doc.data());
        }).toList();
        
        print('Total orders loaded: ${_orders.length}');
      }

      _applyFilters();
      _setLoading(false);
    } catch (e) {
      print('Error fetching orders: $e');
      _setError('Gagal mengambil data pesanan');
      _setLoading(false);
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

  void _applyFilters() {
    var filtered = List<OrderModel>.from(_orders);

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((order) {
        final orderId = order.orderId.toLowerCase();
        final fullName = order.fullName.toLowerCase();
        final search = _searchQuery.toLowerCase();
        return orderId.contains(search) || fullName.contains(search);
      }).toList();
    }

    if (_statusFilter != 'all') {
      filtered = filtered.where((order) => order.status == _statusFilter).toList();
    }

    _filteredOrders = filtered;
    notifyListeners();
  }

  Future<bool> updateOrderStatus(String orderId, String newStatus, {DateTime? shippedAt, DateTime? deliveredAt}) async {
    _setLoading(true);
    _clearError();

    try {
      final updateData = {
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (newStatus == 'Shipped' && shippedAt != null) {
        updateData['shippedAt'] = Timestamp.fromDate(shippedAt);
      }
      if (newStatus == 'Delivered' && deliveredAt != null) {
        updateData['deliveredAt'] = Timestamp.fromDate(deliveredAt);
      }

      await _firestore.collection('orders').doc(orderId).update(updateData);

      final index = _orders.indexWhere((o) => o.orderId == orderId);
      if (index != -1) {
        _orders[index] = _orders[index].copyWith(
          status: newStatus,
          shippedAt: newStatus == 'Shipped' ? (shippedAt ?? DateTime.now()) : _orders[index].shippedAt,
          deliveredAt: newStatus == 'Delivered' ? (deliveredAt ?? DateTime.now()) : _orders[index].deliveredAt,
        );
      }
      _applyFilters();

      _setLoading(false);
      return true;
    } catch (e) {
      debugPrint('Error updating order status: $e');
      _setError('Gagal update status pesanan');
      _setLoading(false);
      return false;
    }
  }

  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (doc.exists) {
        return OrderModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching order: $e');
      return null;
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