import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controllers/dashboard_user_controller.dart';
import '../../promotion/controllers/promotion_user_controller.dart';
import '../../promotion/models/promotion.dart';
import '../../product/models/product.dart';
import '../../product/views/product_detail_user_view.dart';

class DashboardUserView extends StatefulWidget {
  const DashboardUserView({super.key});

  @override
  State<DashboardUserView> createState() => _DashboardUserViewState();
}

class _DashboardUserViewState extends State<DashboardUserView> {
  final DashboardUserController _controller = DashboardUserController();
  final PromotionUserController _promoController = PromotionUserController();

  String userName = 'Retailer';
  bool isLoading = true;

  List<PromotionModel> _activePromos = [];
  int _currentBannerIndex = 0;
  final PageController _bannerPageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadPromotions();
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
        // Tampilkan pop up kalau ada promo aktif
        if (promos.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showPromoPopup(promos.first);
          });
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
          decoration: BoxDecoration(
            color: const Color(0xFF1B8A3A),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon hadiah
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.card_giftcard,
                        color: Colors.white,
                        size: 44,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    Text(
                      promo.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
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
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),

                    // Discount badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_offer,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            promo.discountText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Valid until
                    Text(
                      'Valid until ${_formatDate(promo.endDate)}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
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
                          foregroundColor: const Color(0xFF1B8A3A),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Claim Offer Now',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
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
                    child: const Icon(Icons.close,
                        color: Colors.white, size: 16),
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
    return SafeArea(
      child: Container(
        color: const Color(0xFFF8F9FA),
        child: SingleChildScrollView(
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
    );
  }

  // ── APP BAR ───────────────────────────────────────────────
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset('assets/images/logo.png',
              height: 40, fit: BoxFit.contain),
          Row(
            children: [
              // Notification bell icon (bisa ditambah badge promo)
              if (_activePromos.isNotEmpty)
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined,
                          color: Colors.black87),
                      onPressed: () {},
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                )
              else
                IconButton(
                  icon: const Icon(Icons.notifications_outlined,
                      color: Colors.black87),
                  onPressed: () {},
                ),
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline,
                    color: Colors.black87),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── GREETING ──────────────────────────────────────────────
  Widget _buildGreetingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isLoading ? 'Welcome Back!' : 'Welcome Back, $userName!',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          DateFormat('EEEE, MMMM d, y').format(DateTime.now()),
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  // ── PROMO BANNER (DYNAMIC FROM FIREBASE) ─────────────────
  Widget _buildPromoBanner() {
    // Kalau belum ada data promo, tampilkan shimmer/placeholder
    if (_activePromos.isEmpty) {
      return Container(
        height: 130,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'No active promotions',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      children: [
        // Banner carousel
        SizedBox(
          height: 140,
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

        // Dot indicator (kalau promo > 1)
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
                      ? const Color(0xFF1B8A3A)
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
    // Warna banner berdasarkan discount type
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
        bannerColor = const Color(0xFF1B8A3A);
    }

    return GestureDetector(
      onTap: () => _showPromoPopup(promo),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bannerColor,
          borderRadius: BorderRadius.circular(16),
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
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '⏰ Ending Soon!',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600),
                      ),
                    ),

                  Text(
                    promo.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    promo.discountText,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => _showPromoPopup(promo),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: bannerColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Claim Now',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
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
        ),
      ),
    );
  }

  // ── QUICK ACTIONS ─────────────────────────────────────────
  Widget _buildQuickActions() {
    return Column(
      children: [
        GestureDetector(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  shape: BoxShape.circle,
                ),
                child:
                    Icon(Icons.support_agent, color: Colors.purple.shade300),
              ),
              const SizedBox(height: 8),
              const Text(
                'Support',
                style:
                    TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── RECENT ORDERS ─────────────────────────────────────────
  Widget _buildRecentOrders() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Orders',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'View All',
                style: TextStyle(
                    color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        _buildOrderItem(
            '#ORD-7844', 'Processing', '\$845', 'Mar 14, 2025', Colors.blue),
        const SizedBox(height: 12),
        _buildOrderItem(
            '#ORD-7845', 'Delivered', '\$1,234', 'Mar 16, 2025', Colors.green),
      ],
    );
  }

  Widget _buildOrderItem(String orderId, String status, String total,
      String date, Color statusColor) {
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
              Text(orderId,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(status,
                  style: TextStyle(
                      color: statusColor, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total: $total',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              Text(date,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  // ── RECOMMENDED PRODUCTS ──────────────────────────────────
  Widget _buildRecommendedProducts() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recommended for You',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'See All',
                style: TextStyle(
                    color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        StreamBuilder<List<ProductModel>>(
          stream: _controller.getRecommendedProducts(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
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
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
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
                        builder: (context) => ProductDetailUserView(
                            product: products[index]),
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
        locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

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
              child: Center(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: product.imageUrl.isNotEmpty
                        ? Image.network(product.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.image,
                                    color: Colors.grey, size: 50))
                        : const Icon(Icons.image,
                            color: Colors.grey, size: 50),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              product.name,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'Min. Order: ${product.moq ?? 1} pcs',
              style: TextStyle(color: Colors.grey[500], fontSize: 11),
            ),
            const SizedBox(height: 8),
            Text(
              currencyFormatter.format(product.price),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // ── HELPERS ───────────────────────────────────────────────
  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}