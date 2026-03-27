import 'package:flutter/material.dart';

class DashboardUserView extends StatefulWidget {
  const DashboardUserView({Key? key}) : super(key: key);

  @override
  State<DashboardUserView> createState() => _DashboardUserViewState();
}

class _DashboardUserViewState extends State<DashboardUserView> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
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
                _buildSectionHeader('My Retailers', 'View All'),
                const SizedBox(height: 15),
                _buildRetailerList(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // --- WIDGET HEADER ---
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Image.asset(
          'assets/logo.png',
          height: 35,
        ),
        Row(
          children: const [
            Icon(Icons.chat_bubble_outline, color: Colors.black87),
            SizedBox(width: 20),
            Icon(Icons.person_outline, color: Colors.black87),
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
                value: '\$10,000',
                subtitle: '+20%',
                subtitleColor: Colors.green,
                icon: Icons.attach_money,
                iconColor: Colors.blue,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSingleCard(
                title: 'Orders',
                value: '\$10,000',
                subtitle: '+8.2%',
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
                title: 'Active Promos',
                value: '8',
                subtitle: '3 ending soon',
                subtitleColor: Colors.orange,
                icon: Icons.card_giftcard,
                iconColor: Colors.orange,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSingleCard(
                title: 'Retailer Member',
                value: '+2',
                subtitle: 'new 2 member',
                subtitleColor: Colors.orange,
                icon: Icons.people_outline,
                iconColor: Colors.teal,
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

  // --- WIDGET SECTION HEADER ---
  Widget _buildSectionHeader(String title, String actionText) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          actionText,
          style: const TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // --- WIDGET ACTIVE PROMOTIONS DUMMY ---
  Widget _buildPromoList() {
    return Column(
      children: [
        _buildPromoItem(
          icon: Icons.percent,
          title: 'Spring Sale 2025',
          subtitle: '20% off on all items',
          badgeText: 'Active',
          badgeColor: Colors.blue.shade50,
          badgeTextColor: Colors.blue,
        ),
        Divider(color: Colors.grey.shade200),
        _buildPromoItem(
          icon: Icons.local_offer_outlined,
          title: 'Bulk Purchase Discount',
          subtitle: '15% off on orders over \$5,000',
          badgeText: 'Ending Soon',
          badgeColor: Colors.orange.shade50,
          badgeTextColor: Colors.orange,
        ),
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

  // --- WIDGET MY RETAILERS DUMMY ---
  Widget _buildRetailerList() {
    return Column(
      children: [
        _buildRetailerItem(
          title: 'Sunshine Retail Store',
          location: 'Kabupaten Sidoarjo, Jawa Timur',
        ),
        const SizedBox(height: 5),
        Divider(color: Colors.grey.shade200),
        const SizedBox(height: 5),
        _buildRetailerItem(
          title: 'Fresh Foods Market',
          location: 'Surabaya, Jawa Timur',
        ),
        const SizedBox(height: 10),
        Divider(color: Colors.grey.shade200),
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

  // --- WIDGET BOTTOM NAVIGATION BAR ---
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _selectedIndex,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.grey,
      selectedFontSize: 11,
      unselectedFontSize: 11,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      items: [
        BottomNavigationBarItem(
          icon: _buildNavIcon(Icons.home, 0),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: _buildNavIcon(Icons.shopping_basket_outlined, 1),
          label: 'Orders',
        ),
        BottomNavigationBarItem(
          icon: _buildNavIcon(Icons.storefront_outlined, 2),
          label: 'Products',
        ),
        BottomNavigationBarItem(
          icon: _buildNavIcon(Icons.bar_chart_outlined, 3),
          label: 'Analytics',
        ),
        BottomNavigationBarItem(
          icon: _buildNavIcon(Icons.card_giftcard_outlined, 4),
          label: 'Promotions',
        ),
      ],
    );
  }

  Widget _buildNavIcon(IconData icon, int index) {
    bool isSelected = _selectedIndex == index;
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.green.shade100 : Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: isSelected ? Colors.green.shade700 : Colors.grey,
        size: 24,
      ),
    );
  }
}