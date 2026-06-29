import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_view.dart';
import 'profile_admin_view.dart';
import 'profile_cs_view.dart';
import 'profile_user_view.dart';
import '../../dashboard/views/dashboard_admin_view.dart';
import '../../dashboard/views/dashboard_cs_view.dart';
import '../../dashboard/views/dashboard_user_view.dart';
import '../../../core/firebase_provider.dart';
import '../../shared/main_navigation_user.dart';
import '../../shared/main_navigation_admin.dart';
import '../../shared/main_navigation_cs.dart';
import '../../../main.dart'; // Import for globalNavigatorKey

Future<void> _launchWhatsApp(String? phone) async {
  if (phone == null || phone.isEmpty) return;
  String formatted = phone.replaceAll(RegExp(r'\D'), '');
  if (formatted.startsWith('0')) {
    formatted = '62${formatted.substring(1)}';
  }
  final url = Uri.parse('https://wa.me/$formatted?text=Halo%20Admin,%20akun%20saya%20dinonaktifkan.');
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}

void _showDeactivatedDialog(String? adminPhone) {
  final context = globalNavigatorKey.currentContext;
  if (context == null) return;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Akun Dinonaktifkan', 
              style: TextStyle(fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Maaf, akun Anda telah dinonaktifkan oleh administrator.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          const Text(
            'Silakan hubungi Admin untuk informasi lebih lanjut:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.phone, size: 18, color: Color(0xFF2E7D32)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  adminPhone ?? 'Admin',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup', style: TextStyle(color: Colors.grey)),
        ),
        if (adminPhone != null && adminPhone.isNotEmpty)
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _launchWhatsApp(adminPhone);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Hubungi Admin', style: TextStyle(color: Colors.white)),
          ),
      ],
    ),
  );
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isHandlingDeactivation = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AppFirebase.auth.authStateChanges(),
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
          stream: AppFirebase.firestore
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
                if (!_isHandlingDeactivation) {
                  _isHandlingDeactivation = true;
                  // Fetch admin phone BEFORE signing out just in case
                  // Tampilkan popup menggunakan global navigator key
                  AppFirebase.firestore
                      .collection('users')
                      .where('role', isEqualTo: 'admin')
                      .limit(1)
                      .get()
                      .then((adminSnapshot) {
                    String? adminPhone;
                    if (adminSnapshot.docs.isNotEmpty) {
                      adminPhone = adminSnapshot.docs.first.data()['phoneNumber'];
                    }
                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                      await AppFirebase.auth.signOut();
                      _showDeactivatedDialog(adminPhone);
                      if (mounted) {
                        setState(() {
                          _isHandlingDeactivation = false;
                        });
                      }
                    });
                  }).catchError((e) {
                    debugPrint('Error fetching admin phone: $e');
                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                      await AppFirebase.auth.signOut();
                      _showDeactivatedDialog(null);
                      if (mounted) {
                        setState(() {
                          _isHandlingDeactivation = false;
                        });
                      }
                    });
                  });
                }
                return const Scaffold(
                  backgroundColor: Colors.white,
                  body: Center(child: CircularProgressIndicator(color: Color(0xFF458833))),
                );
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
              AppFirebase.auth.signOut();
            });
            return const LoginView();
          },
        );
      },
    );
  }
}