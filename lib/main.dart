import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'features/authentication/views/register_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Sementara matikan Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
      home: const RegisterView(),
      debugShowCheckedModeBanner: false,
    );
  }
}