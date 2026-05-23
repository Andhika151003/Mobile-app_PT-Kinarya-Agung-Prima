import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_view.dart';
import '../../shared/main_navigation_user.dart';
import '../../shared/main_navigation_admin.dart';
import '../../shared/main_navigation_cs.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {

        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator(color: Color(0xFF458833))),
          );
        }

        if (!authSnapshot.hasData || authSnapshot.data == null) {
          return const LoginView();
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(authSnapshot.data!.uid)
              .snapshots(),
          builder: (context, userSnapshot) {

            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Colors.white,
                body: Center(child: CircularProgressIndicator(color: Color(0xFF458833))),
              );
            }

            if (userSnapshot.hasError) {
              return Scaffold(
                body: Center(child: Text('Error loading user data: ${userSnapshot.error}')),
              );
            }

            if (userSnapshot.hasData && userSnapshot.data!.exists) {
              final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
              
              if (userData == null) {
                return const Scaffold(
                  body: Center(child: Text('User data is empty!')),
                );
              }

              // Jika data belum tersinkronisasi penuh (hanya pending write token), kita tunggu sebentar
              if (!userData.containsKey('role') && userSnapshot.data!.metadata.hasPendingWrites) {
                return const Scaffold(
                  backgroundColor: Colors.white,
                  body: Center(child: CircularProgressIndicator(color: Color(0xFF458833))),
                );
              }

              debugPrint('AuthGate FULL DATA Fetched: $userData for UID: ${authSnapshot.data!.uid}');

              final String role = (userData['role']?.toString().trim().toLowerCase()) ?? 'user';
              debugPrint('AuthGate Role Fetched: "$role" for UID: ${authSnapshot.data!.uid}');

              final bool isActive = userData['isActive'] ?? true;

              if (!isActive) {
                // Jangan sign out otomatis di sini untuk menghindari loop Stream
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  FirebaseAuth.instance.signOut();
                });
                return const LoginView();
              }

              if (role == 'admin') {
                return const MainNavigationAdmin();
              } else if (role == 'cs' || role == 'customer_support') {
                return const MainNavigationCs();
              } else if (role == 'retailer' || role == 'user') {
                return const MainNavigationUser();
              } else {
                return Scaffold(
                  body: Center(child: Text('Unknown role: "$role"')),
                );
              }
            }
            
            // Jika dokumen benar-benar tidak ada di database
            WidgetsBinding.instance.addPostFrameCallback((_) {
              FirebaseAuth.instance.signOut();
            });
            return const LoginView();
          },
        );
      },
    );
  }
}