import 'package:flutter/material.dart';

// Import halaman-halaman yang akan dituju
import '../dashboard/views/dashboard_user_view.dart';
import '../authentication/views/profile_user_view.dart'; 
// (Sesuaikan path import-nya dengan struktur folder Anda)

class NavbarUser extends StatelessWidget {
  // Parameter ini agar kita tahu tab mana yang sedang aktif
  final int currentIndex;

  const NavbarUser({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.green,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      currentIndex: currentIndex, // Gunakan parameter di sini
      onTap: (index) {
        // Cegah pindah halaman kalau ngeklik tab yang sama
        if (index == currentIndex) return; 

        // Logika pindah halaman menggunakan pushReplacement agar tidak numpuk
        if (index == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardUserView()),
          );
        } 
        // Index 1 dan 2 bisa ditambahkan nanti kalau halamannya sudah ada
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