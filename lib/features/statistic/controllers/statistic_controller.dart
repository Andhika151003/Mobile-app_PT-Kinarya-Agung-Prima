import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

enum StatFilter { today, week, month, all }

class AdminStatisticController extends ChangeNotifier {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  AdminStatisticController({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;
  
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  StatFilter _currentFilter = StatFilter.all;
  StatFilter get currentFilter => _currentFilter;

  // --- Summary Stats ---
  double _totalRevenue = 0;
  int _totalOrders = 0;
  int _completedOrders = 0;
  int _cancelledOrders = 0;
  int _totalComplaints = 0;
  int _totalRetailers = 0;
  int _activeRetailers = 0;
  int _totalCS = 0;
  int _activeCS = 0;
  int _totalProducts = 0;
  int _lowStockCount = 0;

  double get totalRevenue => _totalRevenue;
  int get totalOrders => _totalOrders;
  int get completedOrders => _completedOrders;
  int get cancelledOrders => _cancelledOrders;
  int get totalComplaints => _totalComplaints;
  int get totalRetailers => _totalRetailers;
  int get activeRetailers => _activeRetailers;
  int get totalCS => _totalCS;
  int get activeCS => _activeCS;
  int get totalProducts => _totalProducts;
  int get lowStockCount => _lowStockCount;

  // --- Advanced Stats ---
  Map<String, int> _orderStatusCounts = {};
  Map<String, int> _categoryOrderCounts = {};
  List<Map<String, dynamic>> _topProducts = [];
  List<Map<String, dynamic>> _topRetailers = [];
  List<Map<String, dynamic>> _salesTrend = [];

  Map<String, int> get orderStatusCounts => _orderStatusCounts;
  Map<String, int> get categoryOrderCounts => _categoryOrderCounts;
  List<Map<String, dynamic>> get topProducts => _topProducts;
  List<Map<String, dynamic>> get topRetailers => _topRetailers;
  List<Map<String, dynamic>> get salesTrend => _salesTrend;

  void setFilter(StatFilter filter) {
    _currentFilter = filter;
    fetchAnalyticsData();
  }

  Future<void> fetchAnalyticsData() async {
    _isLoading = true;
    if (!_isDisposed) notifyListeners();

    try {
      await Future.wait([
        _fetchOrderStats(),
        _fetchUserStats(),
        _fetchProductStats(),
        _fetchComplaintStats(),
      ]);
    } catch (e) {
      debugPrint('Error fetching statistics: $e');
    } finally {
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  Future<void> _fetchOrderStats() async {
    Query query = _firestore.collection('orders');
    
    DateTime now = DateTime.now();
    DateTime? startDate;

    if (_currentFilter == StatFilter.today) {
      startDate = DateTime(now.year, now.month, now.day);
    } else if (_currentFilter == StatFilter.week) {
      startDate = now.subtract(const Duration(days: 7));
    } else if (_currentFilter == StatFilter.month) {
      startDate = DateTime(now.year, now.month - 1, now.day);
    }

    if (startDate != null) {
      query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }

    final snapshot = await query.get();
    
    double revenue = 0;
    int ordersCount = snapshot.docs.length;
    int completedCount = 0;
    Map<String, int> statusDist = {};
    Map<String, int> categoryOrderCounts = {};
    Map<String, Map<String, dynamic>> productStats = {};
    Map<String, Map<String, dynamic>> retailerStats = {};
    Map<String, double> trendData = {};

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status'] ?? 'Unknown';
      final total = (data['total'] as num?)?.toDouble() ?? 0.0;
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? now;
      final userId = data['userId'] ?? 'Unknown';
      final fullName = data['fullName'] ?? 'Unknown Customer';

      statusDist[status] = (statusDist[status] ?? 0) + 1;

      // Only count revenue for successful orders
      bool isSuccessful = (status == 'Paid' || status == 'Shipped' || status == 'Delivered' || status == 'Settled');
      
      if (isSuccessful) {
        revenue += total;
        if (status == 'Delivered' || status == 'Settled') completedCount++;

        // Sales Trend Data
        String dateKey;
        if (_currentFilter == StatFilter.today) {
          dateKey = DateFormat('HH:00').format(createdAt);
        } else {
          dateKey = DateFormat('dd/MM').format(createdAt);
        }
        trendData[dateKey] = (trendData[dateKey] ?? 0) + total;

        // Retailer Performance
        if (!retailerStats.containsKey(userId)) {
          retailerStats[userId] = {'name': fullName, 'spent': 0.0};
        }
        retailerStats[userId]!['spent'] += total;

        // Product & Category Analysis
        final items = data['items'] as List? ?? [];
        for (var item in items) {
          final itemMap = Map<String, dynamic>.from(item);
          final productId = itemMap['productId'] ?? itemMap['id'];
          final title = itemMap['title'] ?? 'Unknown';
          final qty = (itemMap['quantity'] as num?)?.toInt() ?? 1;
          final price = (itemMap['price'] as num?)?.toDouble() ?? 0.0;
          final category = itemMap['category'] ?? 'Uncategorized';
          final imageUrl = itemMap['imageUrl'];

          // Category Popularity (Count based on orders)
          categoryOrderCounts[category] = (categoryOrderCounts[category] ?? 0) + 1;

          // Product Stats
          if (!productStats.containsKey(title)) {
            productStats[title] = {
              'id': productId,
              'name': title, 
              'sales': 0, 
              'revenue': 0.0,
              'imageUrl': imageUrl,
            };
          }
          productStats[title]!['sales'] += qty;
          productStats[title]!['revenue'] += (qty * price);
        }
      }
    }

    _totalRevenue = revenue;
    _totalOrders = ordersCount;
    _completedOrders = completedCount;
    _cancelledOrders = statusDist['Cancelled'] ?? 0;
    _orderStatusCounts = statusDist;
    _categoryOrderCounts = categoryOrderCounts;

    // Sort and limit Top Products
    _topProducts = productStats.values.toList()
      ..sort((a, b) => b['revenue'].compareTo(a['revenue']));
    _topProducts = _topProducts.take(5).toList();

    // Sort and limit Top Retailers
    _topRetailers = retailerStats.values.toList()
      ..sort((a, b) => b['spent'].compareTo(a['spent']));
    _topRetailers = _topRetailers.take(3).toList();

    // Prepare Sales Trend
    _salesTrend = trendData.entries
        .map((e) => {'date': e.key, 'value': e.value})
        .toList();
    
    _salesTrend.sort((a, b) => a['date'].compareTo(b['date']));
  }

  Future<void> _fetchUserStats() async {
    final snapshot = await _firestore.collection('users').get();
    
    int retailers = 0;
    int activeRet = 0;
    int csCount = 0;
    int activeCsCount = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final role = data['role']?.toString().toLowerCase();
      final isActive = data['isActive'] ?? true;

      if (role == 'retailer') {
        retailers++;
        if (isActive) activeRet++;
      } else if (role == 'cs') {
        csCount++;
        if (isActive) activeCsCount++;
      }
    }

    _totalRetailers = retailers;
    _activeRetailers = activeRet;
    _totalCS = csCount;
    _activeCS = activeCsCount;
  }

  Future<void> _fetchProductStats() async {
    final snapshot = await _firestore.collection('products').get();
    
    int products = snapshot.docs.length;
    int lowStock = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final int stock = (data['stock'] as num?)?.toInt() ?? 0;
      final int alert = (data['lowStockAlert'] as num?)?.toInt() ?? 5;

      if (stock <= alert) {
        lowStock++;
      }
    }

    _totalProducts = products;
    _lowStockCount = lowStock;
  }

  Future<void> _fetchComplaintStats() async {
    Query query = _firestore.collection('complaints');

    DateTime now = DateTime.now();
    DateTime? startDate;

    if (_currentFilter == StatFilter.today) {
      startDate = DateTime(now.year, now.month, now.day);
    } else if (_currentFilter == StatFilter.week) {
      startDate = now.subtract(const Duration(days: 7));
    } else if (_currentFilter == StatFilter.month) {
      startDate = DateTime(now.year, now.month - 1, now.day);
    }

    if (startDate != null) {
      query = query.where('createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }

    final snapshot = await query.get();
    _totalComplaints = snapshot.docs.length;
  }
}
