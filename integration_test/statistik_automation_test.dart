import 'package:ecommerce/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

void main() {
  // ───────────────────────────────────────────────────────────────
  // STATISTIK ADMIN
  // ───────────────────────────────────────────────────────────────
  // Controller: AdminStatisticController
  //   Filter  : StatFilter { today, week, month }  (default: week)
  //   Summary : totalRevenue, totalOrders, cancelledOrders, totalComplaints
  //   Advanced: topProducts (5 item), topRetailers (3 item),
  //             salesTrend, categoryOrderCounts
  //
  // View: AdminStatisticView
  //   Title  : 'Admin Statistics'
  //   Filter : 'Today', 'Last 7 Days', 'Last 30 Days'
  //   Cards  : Total Revenue, Total Orders, Total Cancel, Total Complaint
  //   Section: Sales Trend, Category Popularity
  //   Action : Icons.refresh, Icons.download_outlined
  // ───────────────────────────────────────────────────────────────

  Future<void> _loginAndGoToStatistik($) async {
    await $.pumpWidgetAndSettle(app.MyApp());
    await $(find.bySemanticsLabel('input_login_email')).enterText('ad@email.com');
    await $(find.bySemanticsLabel('input_login_password')).enterText('12345678');
    await $('Log In').tap();
    await $.pumpAndSettle(const Duration(seconds: 10));

    await $('Analytics').tap();
    await $.pumpAndSettle(const Duration(seconds: 10));
  }

  patrolTest('1. Login admin dan buka halaman statistik', ($) async {
    await _loginAndGoToStatistik($);

    // Verifikasi halaman statistik terbuka
    expect($('Admin Statistics'), findsOneWidget);

    // Verifikasi 3 filter chip selalu ada
    expect($('Today'), findsOneWidget);
    expect($('Last 7 Days'), findsOneWidget);
    expect($('Last 30 Days'), findsOneWidget);
  });

  patrolTest('2. Summary cards Total Revenue, Orders, Cancel, Complaint', ($) async {
    await _loginAndGoToStatistik($);

    // 4 summary card selalu muncul
    expect($('Total Revenue'), findsOneWidget);
    expect($('Total Orders'), findsOneWidget);
    expect($('Total Cancel'), findsOneWidget);
    expect($('Total Complaint'), findsOneWidget);
  });

  patrolTest('3. Filter switching Today, Last 7 Days, Last 30 Days', ($) async {
    await _loginAndGoToStatistik($);

    // Ganti filter ke Today
    await $('Today').tap();
    await $.pumpAndSettle();
    // Filter Today aktif (warna hijau terpilih)
    expect($('Today'), findsOneWidget);

    // Ganti filter ke Last 30 Days
    await $('Last 30 Days').tap();
    await $.pumpAndSettle();
    expect($('Last 30 Days'), findsOneWidget);

    // Kembali ke Last 7 Days
    await $('Last 7 Days').tap();
    await $.pumpAndSettle();
    expect($('Last 7 Days'), findsOneWidget);
  });

  patrolTest('4. Section headers dan tombol action', ($) async {
    await _loginAndGoToStatistik($);

    // Section Sales Trend
    expect($('Sales Trend'), findsOneWidget);
    expect($('Category Popularity'), findsOneWidget);

    // Tombol refresh
    final refreshBtn = find.byIcon(Icons.refresh);
    await $.tester.tap(refreshBtn);
    await $.tester.pumpAndSettle();

    // Tombol download
    expect(find.byIcon(Icons.download_outlined), findsOneWidget);
  });
}
