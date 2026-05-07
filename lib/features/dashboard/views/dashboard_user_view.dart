import 'package:ecommerce/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/format_util.dart';
import '../controllers/dashboard_user_controller.dart';
import '../../promotion/controllers/promotion_user_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../promotion/models/promotion.dart';
import '../../product/models/product.dart';
import '../../product/views/product_detail_user_view.dart';
import '../../complaint/views/complaint_form_view.dart';
import '../../complaint/views/complaint_history_view.dart';
import '../../notification/views/notif_user_view.dart';
import '../../order/models/order.dart';
import '../../../core/notifications/navigation_notifications.dart';

class DashboardUserView extends StatefulWidget {
  const DashboardUserView({super.key});

  @override
  State<DashboardUserView> createState() => _DashboardUserViewState();
}

class _DashboardUserViewState extends State<DashboardUserView> {
  final DashboardUserController _controller = DashboardUserController();
  final PromotionUserController _promoController = PromotionUserController();

  bool isLoading = true;
  String userName = 'Retailer';
  List<PromotionModel> _activePromos = [];

  final PageController _bannerPageController = PageController();

  late Stream<List<OrderModel>> _recentOrdersStream;
  late Stream<List<ProductModel>> _recommendedProductsStream;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadPromotions();
    _recentOrdersStream = _controller.getRecentOrders();
    _recommendedProductsStream = _controller.getRecommendedProducts();
  }

  Future<void> _onRefresh() async {
    // Firestore streams are real-time — do NOT recreate them on refresh.
    // Recreating causes StreamBuilder to reset, showing empty state briefly.
    await Future.wait([_loadUserData(), _loadPromotions()]);
  }

  @override
  void dispose() {
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
                          image: promo.imageUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(promo.imageUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: promo.imageUrl == null
                            ? const Icon(
                                Icons.star,
                                color: Colors.white,
                                size: 50,
                              )
                            : null,
                      ),
                      const SizedBox(height: 24),

                      // Title
                      Text(
                        promo.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Desc
                      Text(
                        promo.description,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Discount tag
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          'Save ${promo.discountValue}% Off',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // CTA Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'CLAIM NOW',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              // Close Button
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close, color: Colors.white),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        displacement: 40,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeText(),
                    const SizedBox(height: 24),
                    _buildPromoCard(),
                    const SizedBox(height: 24),
                    _buildSupportIcon(),
                    const SizedBox(height: 24),
                    _buildRecentOrders(),
                    const SizedBox(height: 24),
                    _buildRecommendedProducts(),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: const Color(0xFFF8F9FA),
      elevation: 0,
      pinned: true,
      title: Row(
        children: [
          Image.asset(
            'assets/images/logo.png',
            height: 35,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.eco, color: Colors.green, size: 35),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ComplaintHistoryView()),
            );
          },
          icon: const Icon(Icons.history, color: Colors.black87),
        ),
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationUserView()),
            );
          },
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildWelcomeText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome Back, $userName!',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildPromoCard() {
    if (_activePromos.isEmpty) return const SizedBox.shrink();
    final promo = _activePromos.first;
    final bool hasImage = promo.imageUrl != null && promo.imageUrl!.isNotEmpty;

    return GestureDetector(
      onTap: () => _showPromoPopup(promo),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        height: 150,
        decoration: BoxDecoration(
          color: const Color(0xFF107C32),
          borderRadius: BorderRadius.circular(16),
          image: hasImage
              ? DecorationImage(
                  image: NetworkImage(promo.imageUrl!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                Colors.black.withValues(alpha: 0.55),
                Colors.black.withValues(alpha: 0.15),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        promo.discountText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      promo.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      promo.description.isNotEmpty
                          ? promo.description
                          : 'Berlaku hingga ${DateFormat('dd MMM yyyy').format(promo.endDate)}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!hasImage) ...[
                const SizedBox(width: 16),
                const Icon(Icons.card_giftcard, color: Colors.white, size: 48),
              ],
            ],
          ),
        ),
      ),
      ), // ClipRRect
    ); // GestureDetector
  }

  Widget _buildSupportIcon() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ComplaintFormView(
                  orderId: 'Bantuan Umum',
                  orderDate: 'Bantuan Umum',
                ),
              ),
            );
          },
          child: Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: Color(0xFFEFE8FF), // Light purple
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.headset_mic_outlined,
              color: Color(0xFF6A1B9A),
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Support',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentOrders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Orders',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            InkWell(
              onTap: () {
                ChangeTabNotification(1).dispatch(context);
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                child: Text(
                  'View All',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<OrderModel>>(
          stream: _recentOrdersStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final orders = snapshot.data ?? [];
            if (orders.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.shopping_basket_outlined,
                      color: Colors.grey[300],
                      size: 64,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'No recent orders yet',
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: orders.length > 3 ? 3 : orders.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final order = orders[index];
                final status = order.status;
                final amount = order.total;
                final date = order.createdAt;

                final dateStr = date != null
                    ? DateFormat('MMM dd, yyyy').format(date)
                    : '-';

                final orderIdRaw = order.orderId;

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

  Widget _buildOrderItem(String id, String status, String price, String date) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                id,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                status,
                style: TextStyle(
                  color: _getStatusColor(status),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total: $price',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              Text(
                date,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedProducts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recommended for You',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        StreamBuilder<List<ProductModel>>(
          stream: _recommendedProductsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 40,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
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
                  child: Text('No recommended products found.'),
                ),
              );
            }
            return GridView.builder(
              padding: EdgeInsets.zero,
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
    // Find best promotion for this product to show badge
    PromotionModel? bestPromo;
    final matchingPromos = _activePromos
        .where(
          (promo) =>
              promo.applicableTo == 'all' ||
              promo.productIds.contains(product.id),
        )
        .toList();

    if (matchingPromos.isNotEmpty) {
      matchingPromos.sort((a, b) {
        if (a.discountType != b.discountType) {
          return b.discountType == 'percentage' ? -1 : 1;
        }
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
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    color: Colors.white,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: product.imageUrl.isNotEmpty
                        ? Image.network(product.imageUrl, fit: BoxFit.contain)
                        : Icon(
                            Icons.image_outlined,
                            size: 50,
                            color: Colors.grey.shade300,
                          ),
                  ),
                ),
                if (hasPromo)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        bestPromo.discountText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Text and Price
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Min. Order: ${product.moq ?? 1} pcs',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),

                  Text(
                    '${FormatUtil.formatCompact(product.price, isCurrency: true)} ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Delivered':
      case 'Settled':
        return const Color(0xFF1E8E3E);
      case 'Shipped':
      case 'Paid':
        return const Color(0xFF1976D2);
      case 'Ordered':
      case 'Pending Payment':
        return const Color(0xFFF9AB00);
      case 'Cancelled':
      case 'Expired':
        return const Color(0xFFD93025);
      default:
        return Colors.grey;
    }
  }
}
