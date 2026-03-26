import 'package:flutter/material.dart';
import 'features/authentication/views/register_view.dart';
import 'features/authentication/views/login_view.dart';
import 'features/authentication/views/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kinarya Agung Prima',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      // Langsung ke RegisterView
      home: const RegisterView(),
      routes: {
        '/login': (context) => const LoginView(),
        '/home': (context) => const HomeScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}