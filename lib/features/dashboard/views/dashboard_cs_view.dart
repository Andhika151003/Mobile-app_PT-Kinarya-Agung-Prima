import 'package:flutter/material.dart';

class DashboardCsView extends StatelessWidget {
  const DashboardCsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Logo Section
              Image.asset(
                'assets/logo.png',
                height: 36,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 30),
              
              // 2. Greeting
              const Text(
                'Welcome CS!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              
              // 3. Stats Cards
              Row(
                children: [
                  Expanded(child: _buildStatCard('Open Complaints', '24')),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatCard('Resolved Today', '18')),
                ],
              ),
              const SizedBox(height: 32),
              
              // 4. Section Title
              const Text(
                'Recent Complaints',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              
              // 5. Complaints List Dummy
              _buildComplaintCard(
                timeAgo: '2h ago',
                title: 'Wrong Product Delivery',
                description: "Order #5780 - Product received doesn't\nmatch order specifications",
                storeName: 'Fresh Food Market',
              ),
              const SizedBox(height: 16),
              _buildComplaintCard(
                timeAgo: '3h ago',
                title: 'Delayed Delivery',
                description: 'Order #5781 - Delivery taking longer\nthan estimated time',
                storeName: 'City Convenince', 
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // --- WIDGET SECTIONS ---

  Widget _buildStatCard(String title, String count) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.blueGrey[700],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            count,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B8A3A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintCard({
    required String timeAgo,
    required String title,
    required String description,
    required String storeName,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          // Waktu (Time Ago)
          Align(
            alignment: Alignment.topRight,
            child: Text(
              timeAgo,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Judul Komplain
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          // Deskripsi
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          // Nama Toko
          Row(
            children: [
              const Icon(
                Icons.storefront_outlined,
                color: Color(0xFF1B8A3A),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                storeName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.black87,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      unselectedLabelStyle: const TextStyle(fontSize: 12),
      currentIndex: 0,
      items: [
        BottomNavigationBarItem(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.home_outlined, color: Color(0xFF1B8A3A)),
          ),
          label: 'Home',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.shopping_bag_outlined), 
          label: 'Orders'
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.support_agent_outlined),
          label: 'Supports'
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline), 
          label: 'Profile'
        ),
      ],
    );
  }
}