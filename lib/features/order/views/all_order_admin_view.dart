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

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    try {
      final docs = await _adminController.getAllOrdersAdmin();
      if (mounted) {
        setState(() {
          _allOrders = docs.map((e) => OrderModel.fromMap(e)).toList();
          _applyFilter(_selectedFilter);
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
      final now = DateTime.now();

      if (filter == 'All Transactions') {
        _filteredOrders = List.from(_allOrders);
      } else if (filter == 'Today') {
        _filteredOrders = _allOrders.where((order) {
          if (order.createdAt == null) return false;
          return order.createdAt!.year == now.year &&
                 order.createdAt!.month == now.month &&
                 order.createdAt!.day == now.day;
        }).toList();
      } else if (filter == 'This Week') {
        final weekAgo = now.subtract(const Duration(days: 7));
        _filteredOrders = _allOrders.where((order) {
          if (order.createdAt == null) return false;
          return order.createdAt!.isAfter(weekAgo);
        }).toList();
      }
    });
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
        title: Row(
          children: [
            const Icon(Icons.receipt_long_outlined, color: Colors.black87),
            const SizedBox(width: 8),
            const Text('Transactions', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text('No transactions found', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
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
              color: Colors.black.withOpacity(0.02),
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