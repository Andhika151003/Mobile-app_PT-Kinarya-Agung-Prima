import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/utils/format_util.dart';
import '../controllers/dashboard_admin_controller.dart';
import '../../admin/view/admin_master_view.dart';
import '../../promotion/views/form_promotion_admin_view.dart';
import '../../promotion/models/promotion.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../shared/main_navigation_admin.dart';
import '../../shared/widgets/shimmer_loading.dart';
import '../../notification/views/notif_admin_view.dart';
import '../../notification/controllers/notif_admin_controller.dart';
import 'package:ecommerce/features/order/controllers/order_admin_controller.dart';


class DashboardAdminView extends StatefulWidget {
  const DashboardAdminView({super.key});

  @override
  State<DashboardAdminView> createState() => _DashboardAdminViewState();
}

class _DashboardAdminViewState extends State<DashboardAdminView> with AutomaticKeepAliveClientMixin {
  final DashboardAdminController _controller = DashboardAdminController();
  final NotificationAdminController _notifController = NotificationAdminController();

  Map<String, dynamic> overviewStats = {};
  List<Map<String, dynamic>> promotions = [];
  List<Map<String, dynamic>> retailers = [];
  bool isLoading = true;
  Timer? _syncTimer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    
    // Sinkronisasi berkala setiap 5 menit agar status Expired/Paid terupdate otomatis
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    try {
      // Sinkronisasi pesanan yang tertunda agar data overview akurat
      final OrderAdminController adminOrderCtrl = OrderAdminController();
      await adminOrderCtrl.syncAllPendingOrders();

      final stats = await _controller.getOverviewStats();
      final proms = await _controller.getPromotions();
      final retails = await _controller.getRetailers();

      if (mounted) {
        setState(() {
          overviewStats = stats;
          promotions = proms;
          retailers = retails;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading admin dashboard data: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        color: const Color(0xFF1B8A3A),
        child: isLoading && overviewStats.isEmpty
            ? const SafeArea(child: DashboardShimmer())
            : SafeArea(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 10.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isLoading)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 15),
                            child: LinearProgressIndicator(
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF1B8A3A)),
                              minHeight: 2,
                            ),
                          ),
                        _buildHeader(),
                      const SizedBox(height: 30),
                      _buildSectionHeader(
                        'Overview',
                        'Advanced Analytics',
                        onAction: () {
                          MainNavigationAdmin.of(context)?.setIndex(3);
                        },
                      ),
                      const SizedBox(height: 15),
                      _buildOverviewCards(),
                      const SizedBox(height: 30),
                      _buildSectionHeader(
                        'Active Promotions',
                        '+ New Promo',
                        onAction: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const FormPromotionAdminView(),
                            ),
                          );
                          _loadDashboardData();
                        },
                      ),
                      const SizedBox(height: 15),
                      _buildPromoList(),
                      const SizedBox(height: 30),
                      _buildSectionHeader(
                        'My Retailers',
                        'View All',
                        onAction: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AdminMasterView(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 15),
                      _buildRetailerList(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
      ),
    );
  }




  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Image.asset('assets/images/logo.png', height: 35),
        StreamBuilder<int>(
          stream: _notifController.getUnreadCount(),
          builder: (context, snapshot) {
            final unreadCount = snapshot.data ?? 0;
            return Stack(
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NotificationAdminView()),
                    );
                  },
                  icon: const Icon(Icons.notifications_none_outlined, color: Colors.black87),
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
      ],
    );
  }

  Widget _buildOverviewCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSingleCard(
                title: 'Total Sales',
                value: FormatUtil.formatCompact(overviewStats['totalSales'] ?? 0, isCurrency: true),
                subtitle: 'Real-time revenue',
                subtitleColor: Colors.blue.shade300,
                icon: Icons.attach_money,
                iconColor: Colors.blue,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSingleCard(
                title: 'Orders',
                value: FormatUtil.formatCompact(overviewStats['totalOrders'] ?? 0),
                subtitle: 'Paid orders',
                subtitleColor: Colors.green,
                icon: Icons.shopping_basket_outlined,
                iconColor: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildSingleCard(
                title: 'Customers',
                value: FormatUtil.formatCompact(overviewStats['totalCustomers'] ?? 0),
                subtitle: 'Registered Retailers',
                subtitleColor: Colors.orange.shade300,
                icon: Icons.people_outline,
                iconColor: Colors.teal,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSingleCard(
                title: 'Conversion Rate',
                value: '${overviewStats['conversionRate'] ?? 0}%',
                subtitle: 'Sales per Customer',
                subtitleColor: Colors.purple.shade300,
                icon: Icons.trending_up,
                iconColor: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSingleCard({
    required String title,
    required String value,
    required String subtitle,
    required Color subtitleColor,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              Icon(icon, color: iconColor, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(subtitle, style: TextStyle(color: subtitleColor, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    String actionText, {
    VoidCallback? onAction,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        GestureDetector(
          onTap: onAction,
          child: Text(
            actionText,
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPromoList() {
    if (promotions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text('No active promotions'),
        ),
      );
    }

    final filteredPromos = promotions
        .map((promoMap) {
          return PromotionModel.fromMap(promoMap['id'] ?? '', promoMap);
        })
        .where((promoModel) {
          return promoModel.isActive || promoModel.isUpcoming;
        })
        .take(3)
        .toList();

    if (filteredPromos.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text('No active or upcoming promotions'),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ...filteredPromos.asMap().entries.map((entry) {
            final isLast = entry.key == filteredPromos.length - 1;
            final promoModel = entry.value;

            String badgeText;
            Color badgeColor;
            Color badgeTextColor;

            if (promoModel.isUpcoming) {
              badgeText = 'UPCOMING';
              badgeColor = Colors.cyan.shade50;
              badgeTextColor = Colors.cyan.shade700;
            } else if (promoModel.isEndingSoon) {
              badgeText = 'ENDING SOON';
              badgeColor = Colors.orange.shade50;
              badgeTextColor = Colors.orange;
            } else {
              badgeText = 'ACTIVE';
              badgeColor = Colors.blue.shade50;
              badgeTextColor = Colors.blue;
            }

            return Column(
              children: [
                _buildPromoItem(
                  icon: Icons.local_offer_outlined,
                  title: promoModel.title,
                  subtitle: promoModel.description,
                  badgeText: badgeText,
                  badgeColor: badgeColor,
                  badgeTextColor: badgeTextColor,
                  promotionId: promoModel.id,
                  promotionModel: promoModel,
                ),
                if (!isLast) Divider(height: 1, color: Colors.grey.shade100),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPromoItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required Color badgeTextColor,
    String? promotionId,
    required PromotionModel promotionModel,
  }) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.green, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeTextColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () async {
                  if (promotionId != null) {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            FormPromotionAdminView(promotion: promotionModel),
                      ),
                    );
                    _loadDashboardData();
                  }
                },
                child: const Text(
                  'Edit',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRetailerList() {
    if (retailers.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text('No retailers found'),
        ),
      );
    }

    final displayRetailers = retailers.take(2).toList();

    return Column(
      children: [
        ...displayRetailers.asMap().entries.map((entry) {
          final isLast = entry.key == displayRetailers.length - 1;
          final retailer = entry.value;

          return Column(
            children: [
              _buildRetailerItem(
                title: retailer['fullName'] ?? 'Retailer',
                phoneNumber: retailer['phoneNumber'] ?? '',
              ),
              if (!isLast) ...[
                const SizedBox(height: 5),
                Divider(color: Colors.grey.shade200),
                const SizedBox(height: 5),
              ] else
                const SizedBox(height: 10),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildRetailerItem({
    required String title,
    required String phoneNumber,
  }) {
    return Row(
      children: [
        const Icon(Icons.storefront, color: Colors.grey, size: 28),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                phoneNumber,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => _launchWhatsApp(phoneNumber, title),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF25D366).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble,
              color: Color(0xFF25D366),
              size: 18,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _launchWhatsApp(String phoneNumber, String name) async {
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nomor telepon tidak ditemukan')),
      );
      return;
    }

    String cleanNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (cleanNumber.startsWith('0')) {
      cleanNumber = '62${cleanNumber.substring(1)}';
    }

    final String message =
        'Halo $name,\n\nSaya Admin dari PT Kinarya Agung Prima.';
    final Uri whatsappUri = Uri.parse(
      'whatsapp://send?phone=$cleanNumber&text=${Uri.encodeComponent(message)}',
    );

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri);
      } else {
        final Uri webUri = Uri.parse(
          'https://wa.me/$cleanNumber?text=${Uri.encodeComponent(message)}',
        );
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membuka WhatsApp: $e')));
      }
    }
  }
}
