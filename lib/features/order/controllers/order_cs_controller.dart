import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order.dart';
import 'order_stats_helper.dart';

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

        // Sort by createdAt descending
        _orders.sort((a, b) {
          final aTs = a.createdAt;
          final bTs = b.createdAt;
          if (aTs == null && bTs == null) return 0;
          if (aTs == null) return 1;
          if (bTs == null) return -1;
          return bTs.compareTo(aTs);
        });
        
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
      if (newStatus == 'Paid' || newStatus == 'Shipped' || newStatus == 'Delivered') {
        await OrderStatsHelper.markOrderAsPaid(orderId, targetStatus: newStatus);
      } else {
        final updateData = {
          'status': newStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        await _firestore.collection('orders').doc(orderId).update(updateData);
      }

      // Update local state
      final index = _orders.indexWhere((o) => o.orderId == orderId);
      if (index != -1) {
        // Fetch the updated doc to get fresh data (including paidAt etc)
        final updatedDoc = await _firestore.collection('orders').doc(orderId).get();
        if (updatedDoc.exists) {
          _orders[index] = OrderModel.fromMap(updatedDoc.data()!);
        }
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

  Future<void> cancelOrder(String orderId) async {
    _setLoading(true);
    _clearError();

    final orderRef = _firestore.collection('orders').doc(orderId);
    
    try {
      await _firestore.runTransaction((transaction) async {
        final orderDoc = await transaction.get(orderRef);
        if (!orderDoc.exists) throw Exception('Pesanan tidak ditemukan');

        final data = orderDoc.data() as Map<String, dynamic>;
        final String currentStatus = data['status']?.toString() ?? '';
        final bool statsRecorded = data['statsRecorded'] ?? false;
        final List<dynamic> itemsData = data['items'] as List<dynamic>? ?? [];

        if (currentStatus == 'Cancelled') throw Exception('Pesanan sudah dibatalkan sebelumnya');

        // 1. Update status pesanan
        transaction.update(orderRef, {
          'status': 'Cancelled',
          'cancelledAt': FieldValue.serverTimestamp(),
        });

        // 2. Kembalikan Stok (Restock)
        for (var itemMap in itemsData) {
          final productId = itemMap['productId']?.toString() ?? itemMap['id']?.toString();
          final int quantity = (itemMap['quantity'] as num?)?.toInt() ?? 0;

          if (productId != null && productId.isNotEmpty && quantity > 0) {
            final productRef = _firestore.collection('products').doc(productId);
            transaction.update(productRef, {
              'stock': FieldValue.increment(quantity),
            });

            // 3. Batalkan Statistik (jika sudah tercatat)
            if (statsRecorded) {
              final int price = (itemMap['price'] as num?)?.toInt() ?? 0;
              final int revenue = price * quantity;
              
              transaction.update(productRef, {
                'monthlySales': FieldValue.increment(-quantity),
                'revenue': FieldValue.increment(-revenue),
              });
            }
          }
        }
      });

      // Update local state
      final index = _orders.indexWhere((o) => o.orderId == orderId);
      if (index != -1) {
        final updatedDoc = await _firestore.collection('orders').doc(orderId).get();
        if (updatedDoc.exists) {
          _orders[index] = OrderModel.fromMap(updatedDoc.data()!);
        }
      }
      _applyFilters();
      _setLoading(false);
    } catch (e) {
      debugPrint('Error cancelling order: $e');
      _setError('Gagal membatalkan pesanan: $e');
      _setLoading(false);
      rethrow;
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