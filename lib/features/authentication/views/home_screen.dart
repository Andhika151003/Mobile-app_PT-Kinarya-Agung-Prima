import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Home',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              color: Color(0xFF2E7D32),
              size: 80,
            ),
            const SizedBox(height: 24),
            const Text(
              'Login Successful!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Welcome to Kinarya Agung Prima',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                fontFamily: 'Inter',
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // Logout - kembali ke welcome screen
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}