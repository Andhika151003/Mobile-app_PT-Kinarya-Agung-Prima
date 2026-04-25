import 'package:flutter/material.dart';
import '../../features/dashboard/views/dashboard_cs_view.dart';
import '../../features/order/views/order_cs_view.dart'; 
import '../../features/authentication/views/profile_cs_view.dart';
import '../../features/complaint/views/complaint_list_cs_view.dart';

class MainNavigationCs extends StatefulWidget {
  const MainNavigationCs({super.key});

  @override
  State<MainNavigationCs> createState() => _MainNavigationCsState();
}

class _MainNavigationCsState extends State<MainNavigationCs> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardCsView(),
    const OrderCsView(), 
    const ComplaintListCsView(),
    const ProfileCsView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
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
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_basket_outlined), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.support_agent), label: 'Supports'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}