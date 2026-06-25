import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/status_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/firebase_provider.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../controllers/order_user_controller.dart';
import 'order_detail_user_view.dart';
import '../../shared/widgets/shimmer_loading.dart';
import '../../notification/views/notif_user_view.dart';
import '../../notification/controllers/notif_user_controller.dart';

class OrderUserView extends StatefulWidget {
  const OrderUserView({super.key});

  @override
  State<OrderUserView> createState() => _OrderUserViewState();
}

class _OrderUserViewState extends State<OrderUserView>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final NotificationUserController _notifController =
      NotificationUserController();
  @override
  bool get wantKeepAlive => true;

  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';
  String _selectedSort = 'Newest';

  final List<_TabConfig> _tabs = const [
    _TabConfig(label: 'Semua', statusFilter: null),
    _TabConfig(
      label: 'Belum bayar',
      statusFilter: ['Ordered', 'Pending Payment'],
    ),
    _TabConfig(label: 'Dikemas', statusFilter: ['Paid']),
    _TabConfig(label: 'Dikirim', statusFilter: ['Shipped']),
    _TabConfig(label: 'Selesai', statusFilter: ['Delivered', 'Settled']),
    _TabConfig(label: 'Dibatalkan', statusFilter: ['Cancelled']),
    _TabConfig(label: 'Kedaluwarsa', statusFilter: ['Expired']),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = AppFirebase.auth.currentUser?.uid;
      if (uid != null) {
        OrderUserController().syncAllPendingOrders(uid);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
                  hintText: 'Cari ID atau Produk...',
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
                'Pesanan',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: Colors.black87,
              size: 24,
            ),
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Colors.black87),
            onSelected: (String value) {
              setState(() {
                _selectedSort = value;
              });
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(value: 'Newest', child: Text('Terbaru')),
              const PopupMenuItem(value: 'Oldest', child: Text('Terlama')),
              const PopupMenuItem(
                value: 'Price (High-Low)',
                child: Text('Harga (Tertinggi)'),
              ),
              const PopupMenuItem(
                value: 'Price (Low-High)',
                child: Text('Harga (Terendah)'),
              ),
            ],
          ),
          if (!_isSearching)
            StreamBuilder<int>(
              stream: _notifController.getUnreadCount(),
              builder: (context, snapshot) {
                final unreadCount = snapshot.data ?? 0;
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.notifications_none_outlined,
                        color: Colors.black87,
                        size: 24,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationUserView(),
                          ),
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
                tabs: _tabs
                    .map(
                      (t) => Tab(
                        key: Key(
                          'tab_${t.label.toLowerCase().replaceAll(' ', '_')}',
                        ),
                        text: t.label,
                        height: 44,
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs
            .map(
              (tab) => _OrderList(
                tab: tab,
                searchQuery: _searchQuery,
                selectedSort: _selectedSort,
              ),
            )
            .toList(),
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
class _OrderList extends StatefulWidget {
  final _TabConfig tab;
  final String searchQuery;
  final String selectedSort;

  const _OrderList({
    required this.tab,
    required this.searchQuery,
    required this.selectedSort,
  });

  @override
  State<_OrderList> createState() => _OrderListState();
}

class _OrderListState extends State<_OrderList> {
  late Stream<QuerySnapshot<Map<String, dynamic>>> _ordersStream;
  String? _lastUid;
  final OrderUserController _userController = OrderUserController();

  static const int _pageSize = 5;
  int _currentPage = 0;

  // Track previous filter values to reset page when they change
  String _prevSearch = '';
  String _prevSort = '';
  List<String>? _prevStatusFilter;

  @override
  void initState() {
    super.initState();
    _prevSearch = widget.searchQuery;
    _prevSort = widget.selectedSort;
    _prevStatusFilter = widget.tab.statusFilter;
    _initStream();
  }

  void _initStream() {
    final uid = AppFirebase.auth.currentUser?.uid;
    _lastUid = uid;
    if (uid != null) {
      _ordersStream = _userController.getUserOrdersStream(uid);
    }
  }

  @override
  void didUpdateWidget(covariant _OrderList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final uid = AppFirebase.auth.currentUser?.uid;
    if (uid != _lastUid) {
      _initStream();
    }
    // Reset page when search/sort/filter changes
    if (widget.searchQuery != _prevSearch ||
        widget.selectedSort != _prevSort ||
        widget.tab.statusFilter != _prevStatusFilter) {
      _currentPage = 0;
      _prevSearch = widget.searchQuery;
      _prevSort = widget.selectedSort;
      _prevStatusFilter = widget.tab.statusFilter;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = AppFirebase.auth.currentUser?.uid;
    if (uid == null) return const Center(child: Text('User belum login'));

    return StreamBuilder(
      stream: _ordersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            itemCount: 5,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) => const OrderCardShimmer(),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async =>
                await _userController.syncAllPendingOrders(uid),
            color: Colors.black,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: _EmptyState(hasSearch: widget.searchQuery.isNotEmpty),
              ),
            ),
          );
        }

        List<OrderModel> allOrders = docs
            .map((doc) => OrderModel.fromMap(doc.data()))
            .toList();

        // 1. Filter by Status
        if (widget.tab.statusFilter != null) {
          allOrders = allOrders
              .where((order) => widget.tab.statusFilter!.contains(order.status))
              .toList();
        }

        // 2. Filter by Search Query (Order ID or Product Names)
        if (widget.searchQuery.isNotEmpty) {
          allOrders = allOrders.where((order) {
            final matchesId = order.orderId.toLowerCase().contains(
              widget.searchQuery,
            );
            final matchesProduct = order.items.any(
              (item) => item.title.toLowerCase().contains(widget.searchQuery),
            );
            return matchesId || matchesProduct;
          }).toList();
        }

        if (allOrders.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async =>
                await _userController.syncAllPendingOrders(uid),
            color: Colors.black,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: _EmptyState(hasSearch: widget.searchQuery.isNotEmpty),
              ),
            ),
          );
        }

        // Urutkan
        if (widget.selectedSort == 'Newest') {
          allOrders.sort(
            (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
              a.createdAt ?? DateTime(0),
            ),
          );
        } else if (widget.selectedSort == 'Oldest') {
          allOrders.sort(
            (a, b) => (a.createdAt ?? DateTime(0)).compareTo(
              b.createdAt ?? DateTime(0),
            ),
          );
        } else if (widget.selectedSort == 'Price (High-Low)') {
          allOrders.sort((a, b) => b.total.compareTo(a.total));
        } else if (widget.selectedSort == 'Price (Low-High)') {
          allOrders.sort((a, b) => a.total.compareTo(b.total));
        }

        // ── Pagination ─────────────────────────────────────────────────
        final totalPages = (allOrders.length / _pageSize).ceil();
        final safePage = _currentPage.clamp(0, totalPages - 1);
        if (safePage != _currentPage) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _currentPage = safePage);
          });
        }
        final start = safePage * _pageSize;
        final end = (start + _pageSize).clamp(0, allOrders.length);
        final pageOrders = allOrders.sublist(start, end);

        final showPagination = totalPages > 1;
        final itemCount = pageOrders.length + (showPagination ? 1 : 0);

        return RefreshIndicator(
          onRefresh: () async {
            await _userController.syncAllPendingOrders(uid);
          },
          color: Colors.black,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: itemCount,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, i) {
              if (i < pageOrders.length) {
                return _OrderCard(order: pageOrders[i]);
              } else {
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _PaginationBar(
                    currentPage: safePage,
                    totalPages: totalPages,
                    totalItems: allOrders.length,
                    pageSize: _pageSize,
                    onPageChanged: (page) => setState(() => _currentPage = page),
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }
}

// ── Pagination Bar ────────────────────────────────────────────────────────────
class _PaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  const _PaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.pageSize,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final startItem = currentPage * pageSize + 1;
    final endItem = ((currentPage + 1) * pageSize).clamp(0, totalItems);

    return Column(
      children: [
        Text(
          'Menampilkan $startItem–$endItem dari $totalItems pesanan',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _NavButton(
              icon: Icons.chevron_left,
              enabled: currentPage > 0,
              onTap: () => onPageChanged(currentPage - 1),
              key: const Key('pagination_prev'),
            ),
            const SizedBox(width: 8),
            ...List.generate(totalPages, (i) {
              final isActive = i == currentPage;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: GestureDetector(
                  key: Key('pagination_page_$i'),
                  onTap: () => onPageChanged(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.black87 : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isActive ? Colors.black87 : Colors.grey.shade300,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isActive ? Colors.white : Colors.black54,
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(width: 8),
            _NavButton(
              icon: Icons.chevron_right,
              enabled: currentPage < totalPages - 1,
              onTap: () => onPageChanged(currentPage + 1),
              key: const Key('pagination_next'),
            ),
          ],
        ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 18,
          color: enabled ? Colors.black87 : Colors.grey.shade400,
        ),
      ),
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
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final OrderItemModel? firstItem = order.items.isNotEmpty
        ? order.items.first
        : null;
    final String itemName = firstItem?.title ?? 'Tidak ada produk';
    final int itemQty = firstItem?.quantity ?? 1;
    final String itemUnit = firstItem?.variant ?? 'pak';
    final String? imageUrl = firstItem?.imageUrl;

    return GestureDetector(
      key: Key('card_order_${order.orderId}'),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderDetailUserView(orderId: order.orderId),
        ),
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
                  ? DateFormat(
                      'MMMM dd, yyyy • hh:mm a',
                    ).format(order.createdAt!)
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
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.image_outlined,
                              color: Colors.grey,
                            ),
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
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade500,
                  ),
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
    Color bg;
    Color fg;
    IconData icon;
    String label = status.displayStatus;

    if (status == 'Delivered') {
      bg = const Color(0xFFE6F4EA);
      fg = const Color(0xFF1E8E3E);
      icon = Icons.check_circle_outline;
    } else if (status == 'Cancelled') {
      bg = const Color(0xFFFCE8E6);
      fg = const Color(0xFFD93025);
      icon = Icons.cancel_outlined;
    } else if (status == 'Expired') {
      bg = const Color(0xFFFCE8E6);
      fg = const Color(0xFFD93025);
      icon = Icons.timer_off_outlined;
    } else if (status == 'Ordered') {
      bg = const Color(0xFFFEF7E0);
      fg = const Color(0xFFF9AB00);
      icon = Icons.access_time;
    } else if (status == 'Shipped') {
      bg = const Color(0xFFE3F2FD);
      fg = const Color(0xFF1976D2);
      icon = Icons.local_shipping_outlined;
    } else if (status == 'Paid') {
      bg = const Color(0xFFE8EAF6);
      fg = const Color(0xFF3949AB);
      icon = Icons.payment;
    } else {
      bg = const Color(0xFFE8EAF6);
      fg = const Color(0xFF3949AB);
      icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
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
