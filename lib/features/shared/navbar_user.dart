import 'package:flutter/material.dart';
import '../dashboard/views/dashboard_user_view.dart';
import '../authentication/views/profile_user_view.dart';

class NavbarUser extends StatelessWidget {
  final int currentIndex;

  const NavbarUser({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.green,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      currentIndex: currentIndex,
      onTap: (index) {
        if (index == currentIndex) return; 
        if (index == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardUserView()),
          );
        } 
        else if (index == 3) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ProfileUserView()),
          );
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), label: 'Orders'),
        BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined), label: 'Products'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    );
  }
}