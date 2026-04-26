import 'package:flutter/material.dart';
import '../../features/dashboard/views/dashboard_user_view.dart';
import '../../features/authentication/views/profile_user_view.dart';
import '../product/views/product_user_view.dart';
import '../order/views/order_user_view.dart';

class MainNavigationUser extends StatefulWidget {
  const MainNavigationUser({super.key});

  @override
  State<MainNavigationUser> createState() => _MainNavigationUserState();
}

class _MainNavigationUserState extends State<MainNavigationUser> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardUserView(),
    const OrderUserView(),
    const ProductUserView(),
    const ProfileUserView(),
  ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex], 
      
      bottomNavigationBar: Semantics(
        label: 'main_navigation_bar',
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF458833),
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), label: 'Orders'),
            BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined), label: 'Products'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}