import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'features/authentication/views/auth_gate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Supabase.initialize(
    url: 'https://vlteziwgraboxkqvoklw.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZsdGV6aXdncmFib3hrcXZva2x3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU0NTcyODMsImV4cCI6MjA5MTAzMzI4M30.tun4E2VDe8QdpG-wrnPv9UqeQzAcbBKsWf0ukFQNZIE',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'E-Commerce App',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}
