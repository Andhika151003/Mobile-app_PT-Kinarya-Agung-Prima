import 'package:ecommerce/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

void main() {
  patrolTest('User harus bisa login sampai ke Dashboard', ($) async {
    // 1. Jalankan aplikasi
    await $.pumpWidgetAndSettle(app.MyApp());

    // 2. Masukkan Email
    // Patrol akan mencari TextFormField dan mengisi teks
    await $(#email_field).enterText('ad@email.com');

    // 3. Masukkan Password
    await $(#password_field).enterText('12345678');

    // 4. Klik tombol Login
    await $('LOGIN').tap();

    // 5. Tunggu transisi (Mirip wait di Playwright)
    await $.pumpAndSettle();

    // 6. Verifikasi apakah muncul Dashboard
    expect($('Dashboard'), findsOneWidget);
  });
}
