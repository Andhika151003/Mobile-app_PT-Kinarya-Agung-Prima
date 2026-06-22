import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'features/authentication/views/auth_gate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'features/notification/services/push_notification_service.dart';

import 'core/firebase_provider.dart';

final GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('--- Memulai Inisialisasi Aplikasi ---');

    if (AppFirebase.isMocked) {
      debugPrint('Bypassing real initializations for testing.');
      runApp(const MyApp());
      return;
    }

    debugPrint('Loading .env...');
    await dotenv.load(fileName: ".env");

    debugPrint('Inisialisasi Firebase...');
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } on FirebaseException catch (e) {
      if (e.code != 'duplicate-app') rethrow;
      debugPrint('Firebase sudah diinisialisasi sebelumnya, melanjutkan...');
    }

    debugPrint('Inisialisasi Supabase...');
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
    debugPrint('Supabase berhasil diinisialisasi.');

    debugPrint('Mengatur Background Message Handler...');
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    debugPrint('Inisialisasi Layanan Notifikasi...');
    PushNotificationService().initialize().catchError((e) {
      debugPrint('Gagal inisialisasi notifikasi: $e');
    });

    debugPrint('Menjalankan Aplikasi (runApp)...');
    runApp(const MyApp());
  } catch (e, stackTrace) {
    debugPrint('Kritikal Error saat Startup: $e');
    debugPrint('Stack Trace: $stackTrace');

    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SelectableText('Error saat memuat aplikasi:\n$e'),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: globalNavigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Kinarya E-Commerce',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
      home: const AuthGate(),
    );
  }
}
