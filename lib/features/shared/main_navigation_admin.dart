import 'package:flutter/material.dart';
import '../dashboard/views/dashboard_admin_view.dart';
import '../product/views/product_admin_view.dart';
import '../order/views/order_admin_view.dart';
import '../statistic/views/admin_statistic_view.dart';
import '../statistic/controllers/statistic_controller.dart';
import '../authentication/views/profile_admin_view.dart';
import 'package:provider/provider.dart';

class MainNavigationAdmin extends StatefulWidget {
  final List<Widget>? pages;
  const MainNavigationAdmin({super.key, this.pages});

  @override
  State<MainNavigationAdmin> createState() => MainNavigationAdminState();

  static MainNavigationAdminState? of(BuildContext context) {
    return context.findAncestorStateOfType<MainNavigationAdminState>();
  }
}

class MainNavigationAdminState extends State<MainNavigationAdmin> {
  int _selectedIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void setIndex(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  late final List<Widget> _pages = widget.pages ?? [
    const DashboardAdminView(),
    const ProductAdminView(),
    const OrderAdminView(),
    const AdminStatisticView(),
    const ProfileAdminView(),
  ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ChangeNotifierProvider(
        create: (_) => AdminStatisticController()..fetchAnalyticsData(),
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          children: _pages,
        ),
      ),
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
            setIndex(index);
          },
          items: [
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.home, 0),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.storefront_outlined, 1),
              label: 'Products',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.shopping_basket_outlined, 2),
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.bar_chart_outlined, 3),
              label: 'Analytics',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.person_outline, 4),
              label: 'Profile',
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
