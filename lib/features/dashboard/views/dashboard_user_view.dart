import 'dart:async';
import 'package:ecommerce/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../../../core/firebase_provider.dart';
import '../../../core/utils/status_helper.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/format_util.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/dashboard_user_controller.dart';
import '../../promotion/controllers/promotion_user_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../promotion/models/promotion.dart';
import '../../product/models/product.dart';
import '../../product/views/product_detail_user_view.dart';
import '../../complaint/views/complaint_form_view.dart';
import '../../complaint/views/complaint_history_view.dart';
import '../../authentication/controllers/profile_user_controller.dart';
import '../../notification/views/notif_user_view.dart';
import '../../notification/controllers/notif_user_controller.dart';
import 'package:ecommerce/features/order/controllers/order_user_controller.dart';

class DashboardUserView extends StatefulWidget {
  const DashboardUserView({super.key});

  @override
  State<DashboardUserView> createState() => _DashboardUserViewState();
}

class _DashboardUserViewState extends State<DashboardUserView>
    with AutomaticKeepAliveClientMixin {
  final DashboardUserController _controller = DashboardUserController();
  final PromotionUserController _promoController = PromotionUserController();
  late final NotificationUserController? _notifController;
  final RetailProfileController _profileController = RetailProfileController();

  String userName = 'Retailer';
  bool isLoading = true;

  List<PromotionModel> _activePromos = [];
  int _currentBannerIndex = 0;
  final PageController _bannerPageController = PageController();

  late Stream<List<Map<String, dynamic>>> _recentOrdersStream;
  late Stream<List<ProductModel>> _recommendedProductsStream;
  Timer? _syncTimer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _notifController = AppFirebase.isMocked ? null : NotificationUserController();
    _loadUserData();
    _loadPromotions();
    _recentOrdersStream = _controller.getRecentOrders();
    _recommendedProductsStream = _controller.getRecommendedProducts();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncOrders();
    });
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _syncOrders();
    });
  }

  void _syncOrders() {
    final userId = AppFirebase.auth.currentUser?.uid;
    if (userId != null && userId.isNotEmpty) {
      OrderUserController().syncAllPendingOrders(userId);
    }
  }

  Future<void> _onRefresh() async {
    await Future.wait([_loadUserData(), _loadPromotions()]);
    setState(() {
      _recentOrdersStream = _controller.getRecentOrders();
      _recommendedProductsStream = _controller.getRecommendedProducts();
    });
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _bannerPageController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final fullName = await _controller.getUserFullName();
      if (mounted) {
        setState(() {
          userName = fullName;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _loadPromotions() async {
    try {
      final promos = await _promoController.getActivePromotions();
      if (mounted) {
        setState(() => _activePromos = promos);

        if (promos.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          final bool hasSeenPromo = prefs.getBool('hasSeenPromo_v1') ?? false;

          if (!hasSeenPromo) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showPromoPopup(promos.first);
            });
            await prefs.setBool('hasSeenPromo_v1', true);
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading promotions: $e');
    }
  }

  // ── Pop Up Promo ──────────────────────────────────────────
  void _showPromoPopup(PromotionModel promo) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Image / Icon
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          image:
                              promo.imageUrl != null &&
                                  promo.imageUrl!.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(promo.imageUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: promo.imageUrl == null || promo.imageUrl!.isEmpty
                            ? const Icon(
                                Icons.card_giftcard,
                                color: Colors.white,
                                size: 40,
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Title
                      Text(
                        promo.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Description
                      Text(
                        promo.description,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                          height: 1.4,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.visible,
                      ),
                      const SizedBox(height: 16),

                      // Discount badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.local_offer,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              promo.discountText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Valid until
                      Text(
                        'Berlaku hingga ${_formatDate(promo.endDate)}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Claim button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            promo.isActive ? 'Klaim Penawaran Sekarang' : 'Tunggu sebentar!',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Close button
              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return SafeArea(
      child: Container(
        color: const Color(0xFFF8F9FA),
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _onRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAppBar(),
                const SizedBox(height: 20),
                _buildGreetingSection(),
                const SizedBox(height: 20),
                _buildPromoBanner(),
                const SizedBox(height: 24),
                _buildQuickActions(),
                const SizedBox(height: 24),
                _buildRecentOrders(),
                const SizedBox(height: 24),
                _buildRecommendedProducts(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── APP BAR ───────────────────────────────────────────────
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset(
            'assets/images/logo.png',
            height: 40,
            fit: BoxFit.contain,
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.history, color: Colors.black87),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ComplaintHistoryView(),
                    ),
                  );
                },
              ),
              StreamBuilder<int>(
                stream: _notifController != null ? _notifController.getUnreadCount() : Stream.value(0),
                builder: (context, snapshot) {
                  final unreadCount = snapshot.data ?? 0;
                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.black87,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const NotificationUserView(),
                            ),
                          );
                        },
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 12,
                          top: 12,
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
            ],
          ),
        ],
      ),
    );
  }

  // ── GREETING ──────────────────────────────────────────────
  Widget _buildGreetingSection() {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: _profileController.getRetailProfileStream(),
      builder: (context, snapshot) {
        final name = snapshot.data?['fullName'] ?? userName;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selamat Datang, $name!',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('EEEE, MMMM d, y').format(DateTime.now()),
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPromoBanner() {
    if (_activePromos.isEmpty) {
      return Container(
        height: 130,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'Tidak ada promo aktif',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      children: [
        // Banner carousel
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _bannerPageController,
            itemCount: _activePromos.length,
            onPageChanged: (index) =>
                setState(() => _currentBannerIndex = index),
            itemBuilder: (context, index) {
              final promo = _activePromos[index];
              return _buildSingleBanner(promo);
            },
          ),
        ),

        if (_activePromos.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _activePromos.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentBannerIndex == i ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentBannerIndex == i
                      ? AppColors.primary
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSingleBanner(PromotionModel promo) {
    Color bannerColor;
    switch (promo.discountType) {
      case 'bogo':
        bannerColor = const Color(0xFF6366F1);
        break;
      case 'fixed':
        bannerColor = const Color(0xFFEA580C);
        break;
      case 'bundle':
        bannerColor = const Color(0xFFD97706);
        break;
      default:
        bannerColor = AppColors.primary;
    }

    final bool hasImage = promo.imageUrl != null && promo.imageUrl!.isNotEmpty;

    return GestureDetector(
      onTap: () => _showPromoPopup(promo),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: bannerColor,
          borderRadius: BorderRadius.circular(16),
          image: hasImage
              ? DecorationImage(
                  image: NetworkImage(promo.imageUrl!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.black.withValues(alpha: 0.6),
                Colors.black.withValues(alpha: 0.2),
                Colors.transparent,
              ],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Ending soon badge
                    if (promo.isEndingSoon)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '⏰ Segera Berakhir!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                    // Upcoming badge
                    if (promo.isStartingSoon && !promo.isActive)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '🚀 Akan Datang!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                    Text(
                      promo.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 4,
                            color: Colors.black45,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (promo.discountType != 'percentage')
                      Text(
                        promo.discountText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          shadows: [
                            Shadow(
                              blurRadius: 2,
                              color: Colors.black45,
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => _showPromoPopup(promo),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Klaim Sekarang',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!hasImage) ...[
                const SizedBox(width: 12),
                Icon(
                  promo.discountType == 'bogo'
                      ? Icons.shopping_bag_outlined
                      : promo.discountType == 'bundle'
                      ? Icons.inventory_2_outlined
                      : Icons.card_giftcard,
                  color: Colors.white,
                  size: 56,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ComplaintFormView(
                  orderId: 'Bantuan Umum',
                  orderDate: '-',
                ),
              ),
            );
          },
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.support_agent, color: Colors.purple.shade300),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bantuan',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentOrders() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Pesanan Terbaru',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: _recentOrdersStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              );
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final orders = snapshot.data ?? [];
            if (orders.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'Tidak ada pesanan terbaru',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: orders.length > 3 ? 3 : orders.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final order = orders[index];
                final status = order['status']?.toString() ?? 'Unknown';
                final amount = (order['total'] as num?)?.toDouble() ?? 0.0;
                DateTime? date;
                if (order['createdAt'] is Timestamp) {
                  date = (order['createdAt'] as Timestamp).toDate();
                } else if (order['createdAt'] is String) {
                  date = DateTime.tryParse(order['createdAt']);
                }

                final dateStr = date != null
                    ? DateFormat('MMM dd, yyyy').format(date)
                    : '-';

                final orderIdRaw = order['orderId'] ?? order['id'] ?? '-';

                return _buildOrderItem(
                  orderIdRaw.toString(),
                  status,
                  FormatUtil.formatCompact(amount, isCurrency: true),
                  dateStr,
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildOrderItem(
    String orderId,
    String status,
    String total,
    String date,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                orderId,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              _buildStatusBadge(status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total: $total',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                date,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    IconData icon;
    String label = status.displayStatus;

    if (status == 'Delivered') {
      bg = const Color(0xFFE6F4EA);
      fg = const Color(0xFF1E8E3E);
      icon = Icons.check_circle_outline;
    } else if (status == 'Expired' || status == 'Cancelled') {
      bg = const Color(0xFFFCE8E6);
      fg = const Color(0xFFD93025);
      icon = Icons.cancel_outlined;
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

  Widget _buildRecommendedProducts() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Rekomendasi untuk Anda',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),

        StreamBuilder<List<ProductModel>>(
          stream: _recommendedProductsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              );
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final products = snapshot.data ?? [];
            if (products.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text('Produk rekomendasi tidak ditemukan.'),
                ),
              );
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.65,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProductDetailUserView(product: products[index]),
                      ),
                    );
                  },
                  child: _buildProductCard(products[index]),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildProductCard(ProductModel product) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    // Find best promotion for this product to show badge
    PromotionModel? bestPromo;
    final matchingPromos = _activePromos.where((promo) => 
      promo.applicableTo == 'all' || promo.productIds.contains(product.id)
    ).toList();
    
    if (matchingPromos.isNotEmpty) {
      matchingPromos.sort((a, b) {
        if (a.discountType != b.discountType) return b.discountType == 'percentage' ? -1 : 1;
        return b.discountValue.compareTo(a.discountValue);
      });
      bestPromo = matchingPromos.first;
    }

    bool hasPromo = bestPromo != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: product.imageUrl.isNotEmpty
                            ? Image.network(
                                product.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                      Icons.image,
                                      color: Colors.grey,
                                      size: 50,
                                    ),
                              )
                            : const Icon(Icons.image, color: Colors.grey, size: 50),
                      ),
                    ),
                  ),
                  if (hasPromo && bestPromo.discountType != 'percentage')
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          bestPromo.discountText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              product.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'Min. Pesanan: ${product.moq ?? 1} pcs',
              style: TextStyle(color: Colors.grey[500], fontSize: 10),
            ),
            const SizedBox(height: 8),
            Text(
              currencyFormatter.format(product.price),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // ── HELPERS ───────────────────────────────────────────────
  String _formatDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}
