import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../controllers/order_user_controller.dart';
import 'order_detail_user_view.dart';

class OrderUserView extends StatefulWidget {
  const OrderUserView({super.key});

  @override
  State<OrderUserView> createState() => _OrderUserViewState();
}

class _OrderUserViewState extends State<OrderUserView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';

  final List<_TabConfig> _tabs = const [
    _TabConfig(label: 'All Orders', statusFilter: null),
    _TabConfig(label: 'Pending', statusFilter: ['Ordered', 'Pending Payment']),
    _TabConfig(label: 'Processing', statusFilter: ['Paid', 'Shipped']),
    _TabConfig(label: 'Delivered', statusFilter: ['Delivered', 'Settled']),
    _TabConfig(label: 'Cancelled', statusFilter: ['Cancelled']),
    _TabConfig(label: 'Expired', statusFilter: ['Expired']),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.black, fontSize: 18),
                decoration: const InputDecoration(
                  hintText: 'Search ID or Product...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              )
            : const Text(
                'Orders',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search,
                color: Colors.black87, size: 24),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.notifications_none_outlined,
                  color: Colors.black87, size: 24),
              onPressed: () {},
            ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(46),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: Colors.black87,
                unselectedLabelColor: Colors.grey.shade500,
                indicatorColor: Colors.black87,
                indicatorWeight: 2.5,
                tabAlignment: TabAlignment.start,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                tabs: _tabs.map((t) => Tab(text: t.label, height: 44)).toList(),
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((tab) => _OrderList(tab: tab, searchQuery: _searchQuery)).toList(),
      ),
    );
  }
}

// ── Tab config ────────────────────────────────────────────────────────────────
class _TabConfig {
  final String label;
  final List<String>? statusFilter; 

  const _TabConfig({required this.label, this.statusFilter});
}

// ── Order List per tab ────────────────────────────────────────────────────────
class _OrderList extends StatelessWidget {
  final _TabConfig tab;
  final String searchQuery;

  const _OrderList({required this.tab, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Center(child: Text('User belum login'));

    final OrderUserController userController = OrderUserController();

    return StreamBuilder(
      stream: userController.getUserOrdersStream(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF4A7D3C)));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return _EmptyState(hasSearch: searchQuery.isNotEmpty);

        List<OrderModel> allOrders = docs.map((doc) => OrderModel.fromMap(doc.data())).toList();

        // 1. Filter by Status
        if (tab.statusFilter != null) {
          allOrders = allOrders.where((order) => tab.statusFilter!.contains(order.status)).toList();
        }

        // 2. Filter by Search Query (Order ID or Product Names)
        if (searchQuery.isNotEmpty) {
          allOrders = allOrders.where((order) {
            final matchesId = order.orderId.toLowerCase().contains(searchQuery);
            final matchesProduct = order.items.any((item) =>
                item.title.toLowerCase().contains(searchQuery));
            return matchesId || matchesProduct;
          }).toList();
        }

        if (allOrders.isEmpty) return _EmptyState(hasSearch: searchQuery.isNotEmpty);

        // Urutkan dari yang terbaru
        allOrders.sort((a, b) {
          final aTs = a.createdAt;
          final bTs = b.createdAt;
          if (aTs == null && bTs == null) return 0;
          if (aTs == null) return 1;
          if (bTs == null) return -1;
          return bTs.compareTo(aTs);
        });

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          itemCount: allOrders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, i) => _OrderCard(order: allOrders[i]),
        );
      },
    );
  }
}

// ── Order Card ────────────────────────────────────────────────────────────────
class _OrderCard extends StatelessWidget {
  final OrderModel order; 

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(
        locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    final OrderItemModel? firstItem = order.items.isNotEmpty ? order.items.first : null;
    final String itemName = firstItem?.title ?? 'No items';
    final int itemQty = firstItem?.quantity ?? 1;
    final String itemUnit = firstItem?.variant ?? 'pack';
    final String? imageUrl = firstItem?.imageUrl;



    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => OrderDetailUserView(orderId: order.orderId)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Row 1: Order ID + Status badge ───────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.orderId,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                _StatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 4),

            // ── Row 2: Date + Time ────────────────────────────────────
            Text(
              order.createdAt != null
                  ? DateFormat('MMMM dd, yyyy • hh:mm a').format(order.createdAt!)
                  : '-',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 16),

            // ── Row 3: Product image + details ────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Product thumbnail
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: (imageUrl != null && imageUrl.isNotEmpty)
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.image_outlined, color: Colors.grey),
                          )
                        : const Icon(Icons.image_outlined, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 14),

                // Product info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        itemName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$itemQty $itemUnit  •  ${currencyFmt.format(order.total)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            if (order.items.length > 1)
               Padding(
                 padding: const EdgeInsets.only(top: 12),
                 child: Text(
                   '+ ${order.items.length - 1} item lainnya',
                   style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey.shade500),
                 ),
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
    Color bg; Color fg; IconData icon; String label;

    if (status == 'Delivered') {
      bg = const Color(0xFFE6F4EA); fg = const Color(0xFF1E8E3E); icon = Icons.check_circle_outline; label = 'Delivered';
    } else if (status == 'Cancelled') {
      bg = const Color(0xFFFCE8E6); fg = const Color(0xFFD93025); icon = Icons.cancel_outlined; label = 'Cancelled';
    } else if (status == 'Expired') {
      bg = const Color(0xFFFCE8E6); fg = const Color(0xFFD93025); icon = Icons.timer_off_outlined; label = 'Expired';
    } else if (status == 'Ordered') {
      bg = const Color(0xFFFEF7E0); fg = const Color(0xFFF9AB00); icon = Icons.access_time; label = 'Ordered';
    } else if (status == 'Shipped') {
      bg = const Color(0xFFE3F2FD); fg = const Color(0xFF1976D2); icon = Icons.local_shipping_outlined; label = 'Shipped';
    } else if (status == 'Paid') {
      bg = const Color(0xFFE8EAF6); fg = const Color(0xFF3949AB); icon = Icons.payment; label = 'Paid';
    } else {
      bg = const Color(0xFFE8EAF6); fg = const Color(0xFF3949AB); icon = Icons.info_outline; label = status; 
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
        ],
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
          Icon(
            hasSearch ? Icons.search_off_rounded : Icons.receipt_long_outlined,
            size: 72,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            hasSearch ? 'Tidak ada hasil' : 'Belum ada pesanan',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasSearch
                ? 'Kami tidak menemukan pesanan yang cocok dengan pencarian Anda.'
                : 'Pesanan yang Anda buat akan muncul di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}