import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
// Ganti 'ecommerce' dengan nama package aplikasi Anda yang ada di pubspec.yaml
import 'package:ecommerce/main.dart' as app;

void main() {
  // Wajib dipanggil untuk menginisialisasi binding integration test
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Login Flow Test', () {
    testWidgets('Pengguna berhasil login dengan kredensial yang valid', (
      WidgetTester tester,
    ) async {
      // 1. Jalankan aplikasi
      app.main();

      // Tunggu hingga aplikasi selesai melakukan rendering frame pertama dan animasi awal
      await tester.pumpAndSettle();

      // 2. Verifikasi bahwa kita berada di halaman Login
      expect(find.text('Welcome Back'), findsWidgets);

      // 3. Cari field email menggunakan SemanticsLabel dan masukkan email
      final emailField = find.bySemanticsLabel('input_login_email');
      expect(emailField, findsOneWidget);
      await tester.enterText(
        emailField,
        'test_user@kinarya.com',
      ); // Ganti dengan email valid

      // Beri waktu sejenak agar UI merespons input teks
      await tester.pump();

      // 4. Cari field password dan masukkan password
      final passwordField = find.bySemanticsLabel('input_login_password');
      expect(passwordField, findsOneWidget);
      await tester.enterText(
        passwordField,
        'password123',
      ); // Ganti dengan password valid

      await tester.pump();

      // 5. Tutup keyboard agar tidak menutupi tombol login di layar kecil
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // 6. Cari dan tekan tombol Login
      final loginButton = find.bySemanticsLabel('btn_login_submit');
      expect(loginButton, findsOneWidget);
      await tester.tap(loginButton);

      // 7. Tunggu proses asinkron (seperti request API dan CircularProgressIndicator) hingga navigasi selesai
      await tester.pumpAndSettle();

      // 8. Verifikasi bahwa navigasi berhasil dan pengguna berada di halaman selanjutnya (contoh: Dashboard)
      // Silakan sesuaikan teks 'Dashboard' dengan judul AppBar atau elemen UI di halaman utama Anda.
      // expect(find.text('Dashboard'), findsOneWidget);
    });
  });
}
