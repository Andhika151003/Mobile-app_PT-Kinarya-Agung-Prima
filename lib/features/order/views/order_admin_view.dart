import 'package:flutter/material.dart';
import '../../../core/utils/status_helper.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../controllers/order_admin_controller.dart'; 
import 'order_detail_admin_view.dart';
import 'all_order_admin_view.dart';
import '../../notification/views/notif_admin_view.dart';
import '../../notification/controllers/notif_admin_controller.dart';

class OrderAdminView extends StatefulWidget {
  const OrderAdminView({super.key});

  @override
  State<OrderAdminView> createState() => _OrderAdminViewState();
}

class _OrderAdminViewState extends State<OrderAdminView> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  static const _green = Color(0xFF34A853); 

  final OrderAdminController _adminController = OrderAdminController();
  final NotificationAdminController _notifController = NotificationAdminController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<OrderModel> _allOrders = [];
  List<OrderModel> _filteredOrders = [];
  bool _isLoading = true;
  String _selectedSort = 'Newest';
  String _selectedFilter = 'All';
  final List<String> _filters = [
    'All',
    'Ordered',
    'Paid',
    'Shipped',
    'Delivered',
    'Cancelled',
    'Expired'
  ];

  int _currentPage = 1;
  static const int _pageSize = 5;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _adminController.syncAllPendingOrders().then((_) {
        if (mounted) _fetchOrders(); 
      });
    });
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
          final mapList = _allOrders.map((e) => e.toMap()).toList();
          final filteredMaps = _adminController.filterAndSearchOrders(
            mapList, 
            _selectedFilter == 'All' ? 'All Transactions' : _selectedFilter, 
            _searchQuery
          );
          _filteredOrders = filteredMaps.map((e) => OrderModel.fromMap(e)).toList();
          _applySortInternal();
          
          final totalP = (_filteredOrders.length / _pageSize).ceil().clamp(1, 999);
          if (_currentPage > totalP) {
            _currentPage = totalP;
          }
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

  void _applySearch(String query) {
    setState(() {
      _searchQuery = query;
      final mapList = _allOrders.map((e) => e.toMap()).toList();
      final filteredMaps = _adminController.filterAndSearchOrders(
        mapList, 
        _selectedFilter == 'All' ? 'All Transactions' : _selectedFilter, 
        query
      );
      _filteredOrders = filteredMaps.map((e) => OrderModel.fromMap(e)).toList();
      _applySortInternal();
      _currentPage = 1;
    });
  }

  void _applySortInternal() {
    if (_selectedSort == 'Newest') {
      _filteredOrders.sort((a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    } else if (_selectedSort == 'Oldest') {
      _filteredOrders.sort((a, b) =>
          (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)));
    } else if (_selectedSort == 'Price (High-Low)') {
      _filteredOrders.sort((a, b) => b.total.compareTo(a.total));
    } else if (_selectedSort == 'Price (Low-High)') {
      _filteredOrders.sort((a, b) => a.total.compareTo(b.total));
    }
  }

  int get _totalPages => (_filteredOrders.length / _pageSize).ceil().clamp(1, 999);

  List<OrderModel> get _currentPageOrders {
    final start = ((_currentPage - 1) * _pageSize).clamp(0, _filteredOrders.isEmpty ? 0 : _filteredOrders.length - 1);
    final end = (start + _pageSize).clamp(0, _filteredOrders.length);
    if (start > end) return [];
    return _filteredOrders.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.white, 
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: 36, height: 36, fit: BoxFit.contain,
                    errorBuilder: (ctx, err, st) => const Icon(Icons.change_history, color: _green, size: 36), 
                  ),
                  const Spacer(),
                  StreamBuilder<int>(
                    stream: _notifController.getUnreadCount(),
                    builder: (context, snapshot) {
                      final unreadCount = snapshot.data ?? 0;
                      return Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_none_outlined,
                                color: Colors.black87),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const NotificationAdminView()),
                              );
                            },
                          ),
                          if (unreadCount > 0)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.receipt_long_outlined, color: Colors.black87),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AllTransactionsAdminView()),
                      ).then((_) {
                        _fetchOrders(); 
                      });
                    },
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: Text('Orders', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                      child: TextField(
                        key: const Key('input_search_order'),
                        controller: _searchController,
                        onChanged: (v) => setState(() => _applySearch(v.trim())),
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search Order ID or Name',
                          hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                   GestureDetector(
                    key: const Key('btn_search_order'),
                    onTap: () => setState(() => _applySearch(_searchController.text.trim())),
                    child: Container(
                      width: 46, height: 46,
                      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.search, color: Colors.white, size: 22),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 46,
                    width: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.sort, color: Colors.black87),
                      onSelected: (String value) {
                        setState(() {
                          _selectedSort = value;
                          _applySortInternal();
                        });
                      },
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem(value: 'Newest', child: Text('Terbaru')),
                        const PopupMenuItem(value: 'Oldest', child: Text('Terlama')),
                        const PopupMenuItem(value: 'Price (High-Low)', child: Text('Harga (Tertinggi)')),
                        const PopupMenuItem(value: 'Price (Low-High)', child: Text('Harga (Terendah)')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Status Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      key: Key('tab_${filter.toLowerCase().replaceAll(' ', '_')}'),
                      onTap: () {
                        setState(() {
                          _selectedFilter = filter;
                          _applySearch(_searchController.text.trim());
                        });
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.black : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? Colors.black : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          filter == 'All' ? 'Semua' : filter.displayStatus,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: _green))
                  : _filteredOrders.isEmpty
                      ? _EmptyState(hasSearch: _searchQuery.isNotEmpty)
                      : RefreshIndicator(
                          color: _green,
                          onRefresh: _fetchOrders,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                            itemCount: _currentPageOrders.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, i) => _OrderCard(
                              order: _currentPageOrders[i],
                              onRefresh: _fetchOrders, 
                            ),
                          ),
                        ),
            ),
            if (!_isLoading && _filteredOrders.isNotEmpty)
              _Pagination(
                currentPage: _currentPage, totalPages: _totalPages,
                onPageChanged: (p) => setState(() => _currentPage = p),
              ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onRefresh;

  const _OrderCard({required this.order, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);


    final paymentLabel = order.status == 'Ordered' ? 'Unpaid' : 'Paid';

    return GestureDetector(
      key: Key('card_admin_order_${order.orderId}'),
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
          borderRadius: BorderRadius.circular(8), 
          border: Border.all(color: Colors.grey.shade200), 
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    order.orderId,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              order.createdAt != null ? DateFormat('MMMM dd, yyyy • hh:mm a').format(order.createdAt!) : '-',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade300)),
                  child: const Icon(Icons.storefront_outlined, color: Colors.black54, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.fullName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(
                        order.shippingAddress,
                        style: TextStyle(fontSize: 12, color: order.shippingAddress.contains('tidak tersedia') ? Colors.red : Colors.grey.shade500),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(currencyFmt.format(order.total), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.black)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Items: ${order.items.length}   Payment: $paymentLabel', style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500)),
                const Spacer(),
                Icon(Icons.remove_red_eye_outlined, size: 20, color: Colors.grey.shade500),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg, fg; IconData icon; String label = status.displayStatus;

    if (status == 'Delivered') {
      bg = const Color(0xFFE6F4EA); fg = const Color(0xFF1E8E3E); icon = Icons.check_circle_outline;
    } else if (status == 'Cancelled') {
      bg = const Color(0xFFFCE8E6); fg = const Color(0xFFD93025); icon = Icons.cancel_outlined;
    } else if (status == 'Expired') {
      bg = const Color(0xFFFCE8E6); fg = const Color(0xFFD93025); icon = Icons.timer_off_outlined;
    } else if (status == 'Ordered') {
      bg = const Color(0xFFFEF7E0); fg = const Color(0xFFF9AB00); icon = Icons.access_time;
    } else if (status == 'Shipped') {
      bg = const Color(0xFFE3F2FD); fg = const Color(0xFF1976D2); icon = Icons.local_shipping_outlined;
    } else if (status == 'Paid') {
      bg = const Color(0xFFE8EAF6); fg = const Color(0xFF3949AB); icon = Icons.payment;
    } else {
      bg = const Color(0xFFE8EAF6); fg = const Color(0xFF3949AB); icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: fg)),
        ],
      ),
    );
  }
}

class _Pagination extends StatelessWidget {
  final int currentPage, totalPages;
  final ValueChanged<int> onPageChanged;
  const _Pagination({required this.currentPage, required this.totalPages, required this.onPageChanged});

  @override
  Widget build(BuildContext context) {
    final pages = <int>[];
    int start = (currentPage - 2).clamp(1, totalPages);
    int end = (start + 4).clamp(1, totalPages);
    start = (end - 4).clamp(1, totalPages);
    for (int i = start; i <= end; i++) {
      pages.add(i);
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PageBtn(enabled: currentPage > 1, isSelected: false, onTap: () => onPageChanged(currentPage - 1), child: const Icon(Icons.chevron_left, size: 20)),
          const SizedBox(width: 8),
          ...pages.map((p) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _PageBtn(
                  enabled: true, isSelected: p == currentPage, onTap: () => onPageChanged(p),
                  child: Text('$p', style: TextStyle(fontSize: 14, fontWeight: p == currentPage ? FontWeight.bold : FontWeight.normal, color: p == currentPage ? Colors.white : Colors.black87)),
                ),
              )),
          const SizedBox(width: 8),
          _PageBtn(enabled: currentPage < totalPages, isSelected: false, onTap: () => onPageChanged(currentPage + 1), child: const Icon(Icons.chevron_right, size: 20)),
        ],
      ),
    );
  }
}

class _PageBtn extends StatelessWidget {
  final Widget child; final bool enabled, isSelected; final VoidCallback onTap;
  const _PageBtn({required this.child, required this.enabled, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: isSelected ? const Color(0xFF34A853) : const Color(0xFFF5F5F5), shape: BoxShape.circle),
        child: Center(child: IconTheme(data: IconThemeData(color: isSelected ? Colors.white : enabled ? Colors.black54 : Colors.grey.shade400), child: child)),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasSearch;
  const _EmptyState({this.hasSearch = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(hasSearch ? Icons.search_off_rounded : Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(hasSearch ? 'Tidak ada hasil' : 'Belum ada pesanan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}