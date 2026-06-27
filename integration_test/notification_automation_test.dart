import 'package:ecommerce/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

void main() {
  // ───────────────────────────────────────────────────────────
  // NOTIFIKASI ADMIN
  // ───────────────────────────────────────────────────────────
  // View  : NotificationAdminView     → title 'Admin Notifications'
  // Ikon  : Icons.shopping_cart_outlined (order)
  //         Icons.error_outline          (complaint)
  //         Icons.settings_outlined      (system)
  // Empty : 'No admin notifications'
  // Action: 'Mark All Read'
  // ───────────────────────────────────────────────────────────

  Future<void> _loginAs($, String email, String password) async {
    await $.pumpWidgetAndSettle(app.MyApp());
    await $(find.bySemanticsLabel('input_login_email')).enterText(email);
    await $(find.bySemanticsLabel('input_login_password')).enterText(password);
    await $('Log In').tap();
    await $.pump(const Duration(seconds: 5));
  }

  Future<void> _tapNotifIconByIcon($, IconData icon) async {
    final btn = find.byIcon(icon);
    await $.tester.ensureVisible(btn);
    await $.tester.tap(btn);
    await $.pump();
    await $.pump(const Duration(seconds: 2));
  }

  group('Admin Notifikasi', () {
    patrolTest('1. Admin login dan buka halaman notifikasi', ($) async {
      await _loginAs($, 'ad@email.com', '12345678');

      await _tapNotifIconByIcon($, Icons.notifications_none_outlined);

      expect($('Admin Notifications'), findsOneWidget);
      expect($('Mark All Read'), findsOneWidget);
    });

    patrolTest('2. Notifikasi admin tampilkan ikon sesuai tipe atau empty state', ($) async {
      await _loginAs($, 'ad@email.com', '12345678');

      await _tapNotifIconByIcon($, Icons.notifications_none_outlined);

      await $.pump(const Duration(seconds: 1));

      final hasOrder = find.byIcon(Icons.shopping_cart_outlined).evaluate().isNotEmpty;
      final hasComplaint = find.byIcon(Icons.error_outline).evaluate().isNotEmpty;
      final isEmpty = find.text('No admin notifications').evaluate().isNotEmpty;

      if (isEmpty) {
        expect($('No admin notifications'), findsOneWidget);
      } else {
        expect(hasOrder || hasComplaint, isTrue,
            reason: 'Seharusnya ada notifikasi (order/complaint) atau empty state');
      }
    });

    patrolTest('3. Admin tombol Mark All Read bisa ditekan', ($) async {
      await _loginAs($, 'ad@email.com', '12345678');

      await _tapNotifIconByIcon($, Icons.notifications_none_outlined);

      final hasMarkAll = find.text('Mark All Read').evaluate().isNotEmpty;
      if (hasMarkAll) {
        await $('Mark All Read').tap();
        await $.pump(const Duration(seconds: 1));
      }

      expect($('Admin Notifications'), findsOneWidget);
    });
  });

  // ───────────────────────────────────────────────────────────
  // NOTIFIKASI USER / RETAILER
  // ───────────────────────────────────────────────────────────
  // View  : NotificationUserView      → title 'Notifikasi'
  // Ikon  : Icons.shopping_bag_outlined (order)
  //         Icons.local_offer_outlined  (promo)
  //         Icons.support_agent_outlined (complaint)
  // Empty : 'Belum ada notifikasi'
  // Action: 'Baca Semua'
  // ───────────────────────────────────────────────────────────

  group('User (Retailer) Notifikasi', () {
    patrolTest('4. User login dan buka halaman notifikasi', ($) async {
      await _loginAs($, 'rt@email.com', '12345678');

      await _tapNotifIconByIcon($, Icons.notifications_outlined);

      expect($('Notifikasi'), findsOneWidget);
      expect($('Baca Semua'), findsOneWidget);
    });

    patrolTest('5. Notifikasi user tampilkan ikon sesuai tipe atau empty state', ($) async {
      await _loginAs($, 'rt@email.com', '12345678');

      await _tapNotifIconByIcon($, Icons.notifications_outlined);

      await $.pump(const Duration(seconds: 1));

      final hasOrder = find.byIcon(Icons.shopping_bag_outlined).evaluate().isNotEmpty;
      final hasPromo = find.byIcon(Icons.local_offer_outlined).evaluate().isNotEmpty;
      final hasComplaint = find.byIcon(Icons.support_agent_outlined).evaluate().isNotEmpty;
      final isEmpty = find.text('Belum ada notifikasi').evaluate().isNotEmpty;

      if (isEmpty) {
        expect($('Belum ada notifikasi'), findsOneWidget);
      } else {
        expect(hasOrder || hasPromo || hasComplaint, isTrue,
            reason: 'Seharusnya ada notifikasi (order/promo/complaint) atau empty state');
      }
    });

    patrolTest('6. User tombol Baca Semua bisa ditekan', ($) async {
      await _loginAs($, 'rt@email.com', '12345678');

      await _tapNotifIconByIcon($, Icons.notifications_outlined);

      final hasBacaSemua = find.text('Baca Semua').evaluate().isNotEmpty;
      if (hasBacaSemua) {
        await $('Baca Semua').tap();
        await $.pump(const Duration(seconds: 1));
      }

      expect($('Notifikasi'), findsOneWidget);
    });
  });

  // ───────────────────────────────────────────────────────────
  // NOTIFIKASI CS (Customer Service)
  // ───────────────────────────────────────────────────────────
  // Saat ini DashboardCsView BELUM memiliki ikon notifikasi
  // dan NotifCsView belum diimplementasikan di lib/.
  // Test di bawah akan login sebagai CS dan mencoba navigasi,
  // lalu melaporkan status infrastruktur CS Notifikasi.
  // ───────────────────────────────────────────────────────────

  group('CS Notifikasi', () {
    patrolTest('7. CS login dan verifikasi dashboard', ($) async {
      await _loginAs($, 'cs@email.com', '12345678');

      await $.pump(const Duration(seconds: 2));

      final hasWelcome = find.textContaining('Welcome').evaluate().isNotEmpty;

      expect(hasWelcome, isTrue,
          reason: 'Dashboard CS seharusnya menampilkan "Welcome [nama]" setelah login');

      final hasNotifIcon = find.byIcon(Icons.notifications_none_outlined).evaluate().isNotEmpty ||
          find.byIcon(Icons.notifications_outlined).evaluate().isNotEmpty;

      if (!hasNotifIcon) {
        print('INFO: Dashboard CS belum memiliki ikon notifikasi. '
            'Perlu: (1) NotifCsController, (2) NotifCsView, (3) ikon di DashboardCsView');
      }
    });
  });
}
