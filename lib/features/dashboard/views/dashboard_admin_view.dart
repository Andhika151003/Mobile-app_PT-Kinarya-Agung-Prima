import 'package:flutter/material.dart';
import '../../authentication/views/profile_admin_view.dart';
import '../controllers/dashboard_admin_controller.dart';
import '../../admin/view/admin_master_view.dart'; 

class DashboardAdminView extends StatefulWidget {
  const DashboardAdminView({super.key});

  @override
  State<DashboardAdminView> createState() => _DashboardAdminViewState();
}

class _DashboardAdminViewState extends State<DashboardAdminView> {
  final DashboardAdminController _controller = DashboardAdminController();

  // State untuk overview stats
  Map<String, dynamic> overviewStats = {};
  List<Map<String, dynamic>> promotions = [];
  List<Map<String, dynamic>> retailers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B8A3A)),
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 30),
                      const Text(
                        'Overview',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 15),
                      _buildOverviewCards(),
                      const SizedBox(height: 30),
                      _buildSectionHeader('Active Promotions', '+ New Promo'),
                      const SizedBox(height: 15),
                      _buildPromoList(),
                      const SizedBox(height: 30),
                      // ========== MY RETAILERS DENGAN VIEW ALL ==========
                      _buildSectionHeader(
                        'My Retailers', 
                        'View All',
                        onAction: () {
                          // Navigasi ke Admin Master View (Manage Retail)
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
    );
  }

  // --- WIDGET HEADER ---
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Image.asset(
          'assets/images/logo.png',
          height: 35,
        ),
        Row(
          children: [
            const Icon(Icons.chat_bubble_outline, color: Colors.black87),
            const SizedBox(width: 10),
            IconButton(
              icon: const Icon(Icons.person_outline, color: Colors.black87),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileAdminView(), 
                  ),
                );
              },
            ),
          ],
        )
      ],
    );
  }
  
  // --- WIDGET OVERVIEW CARDS ---
  Widget _buildOverviewCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSingleCard(
                title: 'Total Sales',
                value: overviewStats['totalSales'] ?? '\$0',
                subtitle: overviewStats['salesChange'] ?? '+0%',
                subtitleColor: Colors.green,
                icon: Icons.attach_money,
                iconColor: Colors.blue,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSingleCard(
                title: 'Orders',
                value: '${overviewStats['totalOrders'] ?? 0}',
                subtitle: overviewStats['ordersChange'] ?? '+0%',
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
                title: 'Total Customers',
                value: '${overviewStats['totalCustomers'] ?? 0}',
                subtitle: overviewStats['customersChange'] ?? '+0%',
                subtitleColor: Colors.orange,
                icon: Icons.people_outline,
                iconColor: Colors.teal,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSingleCard(
                title: 'Conversion Rate',
                value: '${overviewStats['conversionRate'] ?? 0}%',
                subtitle: overviewStats['conversionChange'] ?? '+0%',
                subtitleColor: Colors.green,
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
          Text(
            subtitle,
            style: TextStyle(color: subtitleColor, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // --- WIDGET SECTION HEADER (DENGAN CALLBACK) ---
  Widget _buildSectionHeader(String title, String actionText, {VoidCallback? onAction}) {
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

  // --- WIDGET ACTIVE PROMOTIONS ---
  Widget _buildPromoList() {
    if (promotions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text('No active promotions'),
        ),
      );
    }

    return Column(
      children: [
        ...promotions.asMap().entries.map((entry) {
          final isLast = entry.key == promotions.length - 1;
          final promo = entry.value;

          return Column(
            children: [
              _buildPromoItem(
                icon: Icons.local_offer_outlined,
                title: promo['name'] ?? 'Promo',
                subtitle: promo['description'] ?? 'No description',
                badgeText: promo['status']?.toString().toUpperCase() ?? 'ACTIVE',
                badgeColor: promo['status'] == 'active'
                    ? Colors.blue.shade50
                    : Colors.orange.shade50,
                badgeTextColor: promo['status'] == 'active'
                    ? Colors.blue
                    : Colors.orange,
              ),
              if (!isLast) Divider(color: Colors.grey.shade200),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildPromoItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required Color badgeTextColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
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
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
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
              const Text(
                'Edit',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- WIDGET MY RETAILERS ---
  Widget _buildRetailerList() {
    if (retailers.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text('No retailers found'),
        ),
      );
    }

    final displayRetailers = retailers.take(3).toList();

    return Column(
      children: [
        ...displayRetailers.asMap().entries.map((entry) {
          final isLast = entry.key == displayRetailers.length - 1;
          final retailer = entry.value;

          return Column(
            children: [
              _buildRetailerItem(
                title: retailer['fullName'] ?? 'Retailer',
                location: retailer['address'] ?? 'No location',
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

  Widget _buildRetailerItem({required String title, required String location}) {
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
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(
                location,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.chat_bubble, color: Colors.blueAccent, size: 18),
        ),
      ],
    );
  }
}