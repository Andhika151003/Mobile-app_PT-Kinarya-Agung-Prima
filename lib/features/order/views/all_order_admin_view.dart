import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../controllers/order_admin_controller.dart';
import 'order_detail_admin_view.dart';

class AllTransactionsAdminView extends StatefulWidget {
  const AllTransactionsAdminView({super.key});

  @override
  State<AllTransactionsAdminView> createState() => _AllTransactionsAdminViewState();
}

class _AllTransactionsAdminViewState extends State<AllTransactionsAdminView> {
  static const _primaryGreen = Color(0xFF00903D);
  static const _bgColor = Color(0xFFF7F8FA);

  final OrderAdminController _adminController = OrderAdminController();
  
  List<OrderModel> _allOrders = [];
  List<OrderModel> _filteredOrders = [];
  bool _isLoading = true;

  String _selectedFilter = 'All Transactions';
  final List<String> _filters = ['All Transactions', 'Today', 'This Week'];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    try {
      final docs = await _adminController.getAllOrdersAdmin();
      if (mounted) {
        setState(() {
          _allOrders = docs.map((e) => OrderModel.fromMap(e)).toList();
          _filterItems();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      _filterItems();
    });
  }

  void _filterItems() {
    final now = DateTime.now();
    List<OrderModel> results = List.from(_allOrders);

    // 1. Time Filter
    if (_selectedFilter == 'Today') {
      results = results.where((order) {
        if (order.createdAt == null) return false;
        return order.createdAt!.year == now.year &&
               order.createdAt!.month == now.month &&
               order.createdAt!.day == now.day;
      }).toList();
    } else if (_selectedFilter == 'This Week') {
      final weekAgo = now.subtract(const Duration(days: 7));
      results = results.where((order) {
        if (order.createdAt == null) return false;
        return order.createdAt!.isAfter(weekAgo);
      }).toList();
    }

    // 2. Search Filter
    if (_searchQuery.isNotEmpty) {
      results = results.where((order) {
        final q = _searchQuery.toLowerCase();
        final matchesId = order.orderId.toLowerCase().contains(q);
        final matchesName = order.fullName.toLowerCase().contains(q);
        final matchesAddress = order.shippingAddress.toLowerCase().contains(q);
        final matchesItems = order.items.any((item) => item.title.toLowerCase().contains(q));
        return matchesId || matchesName || matchesAddress || matchesItems;
      }).toList();
    }

    _filteredOrders = results;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300)),
            child: const Icon(Icons.arrow_back_ios_new, size: 14, color: Colors.black87),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          children: [
            Icon(Icons.receipt_long_outlined, color: Colors.black87),
            SizedBox(width: 8),
            Text('Transactions', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Search Bar ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search ID, Name, or Product...',
                  hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                  prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  suffixIcon: _searchQuery.isNotEmpty 
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _filterItems();
                          });
                        },
                      )
                    : null,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _filterItems();
                  });
                },
              ),
            ),
          ),

          // ── Filter Chips ──────────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: _filters.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: InkWell(
                    onTap: () => _applyFilter(filter),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? _primaryGreen : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? _primaryGreen : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Transaction List ────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: _primaryGreen))
                : _filteredOrders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _searchQuery.isNotEmpty ? Icons.search_off_rounded : Icons.receipt_long_outlined, 
                              size: 64, 
                              color: Colors.grey.shade300
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty ? 'No results found' : 'No transactions found',
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: _primaryGreen,
                        onRefresh: _fetchOrders,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: _filteredOrders.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            return _TransactionCard(
                              order: _filteredOrders[index],
                              onRefresh: _fetchOrders,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Transaction Card Widget ───────────────────────────────────────────
class _TransactionCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onRefresh;

  const _TransactionCard({required this.order, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final digits = order.orderId.replaceAll(RegExp(r'[^0-9]'), '');
    final shortId = '#ORD-${digits.length >= 4 ? digits.substring(digits.length - 4) : digits}';

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OrderDetailAdminView(orderId: order.orderId)),
        );
        onRefresh();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: TRX ID & Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  shortId,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                _buildStatusBadge(order.status),
              ],
            ),
            const SizedBox(height: 16),
            
            // Row 2: Store Info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.storefront_outlined, color: Colors.grey, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.fullName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.shippingAddress,
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Row 3: Price & Eye Icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFmt.format(order.total),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                Icon(Icons.remove_red_eye_outlined, color: Colors.grey.shade400, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg; Color fg; String label;

    if (status == 'Ordered' || status == 'Pending Payment') {
      bg = const Color(0xFFFFF3CD); 
      fg = const Color(0xFFD69E2E); 
      label = 'Pending';
    } else if (status == 'Paid' || status == 'Shipped' || status == 'Delivered' || status == 'Settled') {
      bg = const Color(0xFFD1E7DD); 
      fg = const Color(0xFF0F5132); 
      label = status == 'Delivered' ? 'Delivered' : 'Verified';
    } else {
      bg = const Color(0xFFF8D7DA); 
      fg = const Color(0xFF842029); 
      label = 'Cancelled';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}