import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce/features/notification/views/notif_admin_view.dart';
import 'package:ecommerce/features/notification/views/notif_user_view.dart';
import 'package:ecommerce/features/notification/controllers/notif_admin_controller.dart';
import 'package:ecommerce/features/notification/controllers/notif_user_controller.dart';

void main() {
  group('NotificationAdminView Widget Tests', () {
    testWidgets('Menampilkan empty state ketika tidak ada notifikasi admin',
        (tester) async {
      final fakeFirestore = FakeFirebaseFirestore();
      final controller =
          NotificationAdminController(firestore: fakeFirestore);

      await tester.pumpWidget(
        MaterialApp(
          home: NotificationAdminView(controller: controller),
        ),
      );

      // Tunggu stream selesai loading
      await tester.pumpAndSettle();

      expect(find.text('No admin notifications'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none_outlined), findsOneWidget);
    });

    testWidgets('Menampilkan notifikasi admin tipe order', (tester) async {
      final fakeFirestore = FakeFirebaseFirestore();
      final controller =
          NotificationAdminController(firestore: fakeFirestore);

      await fakeFirestore.collection('admin_notifications').doc('notif_1').set({
        'title': 'Pesanan Baru #123',
        'message': 'Pesanan dari Toko ABC',
        'timestamp': Timestamp.fromDate(DateTime(2026, 6, 24, 10, 30)),
        'isRead': false,
        'type': 'order',
        'relatedId': 'order_123',
      });

      await tester.pumpWidget(
        MaterialApp(
          home: NotificationAdminView(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pesanan Baru #123'), findsOneWidget);
      expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);
      expect(find.text('Admin Notifications'), findsOneWidget);
      expect(find.text('Mark All Read'), findsOneWidget);
    });

    testWidgets('Menampilkan notifikasi admin tipe complaint', (tester) async {
      final fakeFirestore = FakeFirebaseFirestore();
      final controller =
          NotificationAdminController(firestore: fakeFirestore);

      await fakeFirestore.collection('admin_notifications').doc('notif_2').set({
        'title': 'Komplain Baru',
        'message': 'Pelanggan mengajukan komplain',
        'timestamp': Timestamp.fromDate(DateTime(2026, 6, 24, 11, 0)),
        'isRead': false,
        'type': 'complaint',
        'relatedId': 'complaint_456',
      });

      await tester.pumpWidget(
        MaterialApp(
          home: NotificationAdminView(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Komplain Baru'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('Tombol Mark All Read bisa ditekan', (tester) async {
      final fakeFirestore = FakeFirebaseFirestore();
      final controller =
          NotificationAdminController(firestore: fakeFirestore);

      await fakeFirestore.collection('admin_notifications').doc('notif_1').set({
        'title': 'Notif 1',
        'message': 'Test',
        'timestamp': Timestamp.fromDate(DateTime(2026, 6, 24)),
        'isRead': false,
        'type': 'order',
      });
      await fakeFirestore.collection('admin_notifications').doc('notif_2').set({
        'title': 'Notif 2',
        'message': 'Test 2',
        'timestamp': Timestamp.fromDate(DateTime(2026, 6, 24)),
        'isRead': false,
        'type': 'complaint',
      });

      await tester.pumpWidget(
        MaterialApp(
          home: NotificationAdminView(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      // Pastikan tombol Mark All Read ada
      await tester.tap(find.text('Mark All Read'));
      await tester.pumpAndSettle();

      // Verifikasi masih di halaman yang sama
      expect(find.text('Admin Notifications'), findsOneWidget);
    });
  });

  group('NotificationUserView Widget Tests', () {
    testWidgets('Menampilkan empty state ketika user belum login',
        (tester) async {
      final fakeFirestore = FakeFirebaseFirestore();
      final mockAuth = MockFirebaseAuth();
      final controller = NotificationUserController(
        firestore: fakeFirestore,
        auth: mockAuth,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: NotificationUserView(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Belum ada notifikasi'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none_outlined), findsOneWidget);
    });

    testWidgets('Menampilkan notifikasi user setelah login', (tester) async {
      final fakeFirestore = FakeFirebaseFirestore();
      const uid = 'user_123';
      final mockUser = MockUser(uid: uid, email: 'user@test.com');
      final mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
      final controller = NotificationUserController(
        firestore: fakeFirestore,
        auth: mockAuth,
      );

      await fakeFirestore
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc('n1')
          .set({
        'title': 'Pesanan Diproses',
        'message': 'Pesanan kamu sedang diproses',
        'timestamp': Timestamp.fromDate(DateTime(2026, 6, 24)),
        'isRead': false,
        'type': 'order',
        'relatedId': 'order_789',
      });

      await tester.pumpWidget(
        MaterialApp(
          home: NotificationUserView(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pesanan Diproses'), findsOneWidget);
      expect(find.byIcon(Icons.shopping_bag_outlined), findsOneWidget);
      expect(find.text('Notifikasi'), findsOneWidget);
      expect(find.text('Baca Semua'), findsOneWidget);
    });

    testWidgets('Menampilkan notifikasi user tipe promo', (tester) async {
      final fakeFirestore = FakeFirebaseFirestore();
      const uid = 'user_456';
      final mockUser = MockUser(uid: uid, email: 'user2@test.com');
      final mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
      final controller = NotificationUserController(
        firestore: fakeFirestore,
        auth: mockAuth,
      );

      await fakeFirestore
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc('n2')
          .set({
        'title': 'Promo Spesial!',
        'message': 'Diskon 50% untuk produk terpilih',
        'timestamp': Timestamp.fromDate(DateTime(2026, 6, 24)),
        'isRead': false,
        'type': 'promo',
      });

      await tester.pumpWidget(
        MaterialApp(
          home: NotificationUserView(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Promo Spesial!'), findsOneWidget);
      expect(find.byIcon(Icons.local_offer_outlined), findsOneWidget);
    });

    testWidgets('Tombol Baca Semua bisa ditekan', (tester) async {
      final fakeFirestore = FakeFirebaseFirestore();
      const uid = 'user_789';
      final mockUser = MockUser(uid: uid, email: 'user3@test.com');
      final mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
      final controller = NotificationUserController(
        firestore: fakeFirestore,
        auth: mockAuth,
      );

      await fakeFirestore
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc('n1')
          .set({
        'title': 'Notif 1',
        'message': 'Test',
        'timestamp': Timestamp.fromDate(DateTime(2026, 6, 24)),
        'isRead': false,
        'type': 'order',
      });

      await tester.pumpWidget(
        MaterialApp(
          home: NotificationUserView(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Baca Semua'));
      await tester.pumpAndSettle();

      expect(find.text('Notifikasi'), findsOneWidget);
    });
  });
}
