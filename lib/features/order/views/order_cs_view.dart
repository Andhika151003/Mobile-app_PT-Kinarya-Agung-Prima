import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/order_cs_controller.dart';
import '../models/order.dart';
import 'order_detail_cs_view.dart';

class OrderCsView extends StatefulWidget {
  const OrderCsView({super.key});

  @override
  State<OrderCsView> createState() => _OrderCsViewState();
}

class _OrderCsViewState extends State<OrderCsView> {
  String _selectedStatus = 'all';
  late final OrderCsController _controller;

  final List<Map<String, String>> _tabs = [
    {'label': 'All Orders', 'value': 'all'},
    {'label': 'Pending', 'value': 'Ordered'},
    {'label': 'Paid', 'value': 'Paid'},
    {'label': 'Delivered', 'value': 'Delivered'},
    {'label': 'Cancelled', 'value': 'Cancelled'},
  ];

  @override
  void initState() {
    super.initState();
    _controller = OrderCsController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.fetchAllOrders();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            "Retailer's Order",
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: Colors.black,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false, // ← hapus back button
          actions: [
            IconButton(
              icon: const Icon(Icons.search, color: Colors.black),
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: _OrderSearchDelegate(_controller),
                );
              },
            ),
          ],
        ),
        body: Consumer<OrderCsController>(
          builder: (context, controller, child) {
            return Column(
              children: [
                // Tab Filter
                Container(
                  color: Colors.white,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Row(
                      children: _tabs.map((tab) {
                        final isSelected = _selectedStatus == tab['value'];
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedStatus = tab['value']!);
                            controller.filterByStatus(tab['value']!);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF2E7D32)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: isSelected
                                  ? null
                                  : Border.all(
                                      color: const Color(0xFFE5E7EB)),
                            ),
                            child: Text(
                              tab['label']!,
                              style: TextStyle(
                                fontSize: 13,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // Orders List
                Expanded(
                  child: controller.isLoading && controller.orders.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF2E7D32)))
                      : controller.filteredOrders.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.shopping_bag_outlined,
                                      size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Tidak ada pesanan',
                                    style: TextStyle(
                                        color: Colors.grey[500],
                                        fontFamily: 'Inter'),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              itemCount: controller.filteredOrders.length,
                              itemBuilder: (context, index) {
                                return _buildOrderCard(
                                    context,
                                    controller.filteredOrders[index],
                                    controller);
                              },
                            ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrderCard(
      BuildContext context, OrderModel order, OrderCsController controller) {
    Color statusColor;
    Color statusBgColor;
    IconData? statusIcon;
    String statusLabel;

    if (order.status == 'Delivered') {
      statusBgColor = const Color(0xFFE6F4EA); statusColor = const Color(0xFF1E8E3E); statusIcon = Icons.check_circle_outline; statusLabel = 'Delivered';
    } else if (order.status == 'Expired' || order.status == 'Cancelled') {
      statusBgColor = const Color(0xFFFCE8E6); statusColor = const Color(0xFFD93025); statusIcon = Icons.cancel_outlined; statusLabel = 'Cancelled';
    } else if (order.status == 'Ordered') {
      statusBgColor = const Color(0xFFFEF7E0); statusColor = const Color(0xFFF9AB00); statusIcon = Icons.access_time; statusLabel = 'Ordered';
    } else if (order.status == 'Shipped') {
      statusBgColor = const Color(0xFFE3F2FD); statusColor = const Color(0xFF1976D2); statusIcon = Icons.local_shipping_outlined; statusLabel = 'Shipped';
    } else if (order.status == 'Paid') {
      statusBgColor = const Color(0xFFE8EAF6); statusColor = const Color(0xFF3949AB); statusIcon = Icons.payment; statusLabel = 'Paid';
    } else {
      statusBgColor = const Color(0xFFE8EAF6); statusColor = const Color(0xFF3949AB); statusIcon = Icons.info_outline; statusLabel = order.status; 
    }

    final paymentStatus = order.paidAt != null
        ? 'Completed'
        : (order.status == 'Cancelled' ? 'Refunded' : 'Pending');

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderDetailCsView(order: order),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.orderId,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter',
                    color: Colors.black,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (statusIcon != null) ...[
                        Icon(statusIcon, size: 12, color: statusColor),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _formatDateTime(order.createdAt ?? DateTime.now()),
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'Inter',
                color: Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.store_outlined,
                      size: 18, color: Color(0xFF6B7280)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.fullName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        order.shippingAddress.split('\n').first,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'Inter',
                          color: Color(0xFF9CA3AF),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Text(
                  NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(order.total),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter',
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Items: ${order.items.length}  Payment: $paymentStatus',
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'Inter',
                    color: Color(0xFF6B7280),
                  ),
                ),
                const Icon(Icons.remove_red_eye_outlined,
                    size: 18, color: Color(0xFF9CA3AF)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return DateFormat('MMMM dd, yyyy • hh:mm a').format(date);
  }
}

class _OrderSearchDelegate extends SearchDelegate<String> {
  final OrderCsController controller;

  _OrderSearchDelegate(this.controller);

  @override
  List<Widget> buildActions(BuildContext context) => [
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, ''),
      );

  @override
  Widget buildResults(BuildContext context) {
    controller.searchOrders(query);
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    controller.searchOrders(query);
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    return ChangeNotifierProvider.value(
      value: controller,
      child: Consumer<OrderCsController>(
        builder: (_, ctrl, __) => ListView.builder(
          itemCount: ctrl.filteredOrders.length,
          itemBuilder: (ctx, i) {
            final order = ctrl.filteredOrders[i];
            return ListTile(
              title: Text(order.orderId),
              subtitle: Text(order.fullName),
              trailing: Text(order.status),
              onTap: () => close(ctx, order.orderId),
            );
          },
        ),
      ),
    );
  }
}