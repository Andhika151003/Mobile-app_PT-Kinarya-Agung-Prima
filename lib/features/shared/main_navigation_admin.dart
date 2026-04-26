import 'package:flutter/material.dart';
import '../dashboard/views/dashboard_admin_view.dart';
import '../product/views/product_admin_view.dart';
import '../order/views/order_admin_view.dart';
import '../promotion/views/promotion_admin_view.dart';

class MainNavigationAdmin extends StatefulWidget {
  const MainNavigationAdmin({super.key});

  @override
  State<MainNavigationAdmin> createState() => _MainNavigationAdminState();
}

class _MainNavigationAdminState extends State<MainNavigationAdmin> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardAdminView(),
    const OrderAdminView(),
    const ProductAdminView(),
    const Center(child: Text('Halaman Analytics')),
    const PromotionAdminView(),
  ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Semantics(
        label: 'main_navigation_bar',
        child: BottomNavigationBar(
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
        ),
      ),
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
