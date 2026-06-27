import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:ecommerce/features/dashboard/controllers/dashboard_cs_controller.dart';
import 'package:intl/intl.dart';

void main() {
  group('Complaint CS Controller Unit Tests', () {
    late MockFirebaseAuth mockAuth;
    late FakeFirebaseFirestore mockFirestore;
    late DashboardCsController controller;

    setUp(() {
      final mockUser = MockUser(uid: 'cs_uid', email: 'cs@email.com');
      mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
      mockFirestore = FakeFirebaseFirestore();
      controller = DashboardCsController(auth: mockAuth, firestore: mockFirestore);
    });

    test('TC-128: Customer Support melihat daftar komplain masuk', () async {
      final now = DateTime.now();
      await mockFirestore.collection('complaints').doc('comp_1').set({
        'issueType': 'Barang Rusak',
        'description': 'Packing pecah',
        'status': 'pending',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(minutes: 5))),
      });
      await mockFirestore.collection('complaints').doc('comp_2').set({
        'issueType': 'Salah Produk',
        'description': 'Kirimnya beda',
        'status': 'pending',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(minutes: 10))),
      });

      final stream = controller.getRecentComplaintsStream();
      final list = await stream.first;

      expect(list.length, 2);
      expect(list[0]['title'], 'Barang Rusak');
      expect(list[1]['title'], 'Salah Produk');
      expect(list[0]['timeAgo'], '5m ago');
      expect(list[1]['timeAgo'], '10m ago');
    });

    test('TC-129: Customer Support merespons komplain dan Resolve (menyelesaikan)', () async {
      await mockFirestore.collection('users').doc('cs_uid').set({
        'fullName': 'Budi CS',
        'role': 'cs',
      });
      await mockFirestore.collection('complaints').doc('comp_resolve').set({
        'status': 'pending',
      });

      final result = await controller.resolveComplaint('comp_resolve');
      expect(result, true);

      final doc = await mockFirestore.collection('complaints').doc('comp_resolve').get();
      expect(doc.data()?['status'], 'resolved');
      expect(doc.data()?['resolvedBy'], 'cs_uid');
      expect(doc.data()?['resolvedByName'], 'Budi CS');
      expect(doc.data()?['resolvedAt'], isNotNull);
    });

    test('TC-130: Customer Support merespons komplain dan Reject (menolak)', () async {
      await mockFirestore.collection('users').doc('cs_uid').set({
        'fullName': 'Budi CS',
        'role': 'cs',
      });
      await mockFirestore.collection('complaints').doc('comp_reject').set({
        'status': 'pending',
      });

      final result = await controller.rejectComplaint('comp_reject');
      expect(result, true);

      final doc = await mockFirestore.collection('complaints').doc('comp_reject').get();
      expect(doc.data()?['status'], 'rejected');
      expect(doc.data()?['resolvedBy'], 'cs_uid');
      expect(doc.data()?['resolvedByName'], 'Budi CS');
    });

    test('TC-131: Customer Support mengakses detail pesanan Retailer untuk validasi', () async {
      await mockFirestore.collection('users').doc('retailer_123').set({
        'fullName': 'Toko Makmur',
        'storeName': 'Toko Makmur Sejahtera',
        'phoneNumber': '08123456789',
        'role': 'retailer',
      });

      final profile = await controller.getUserProfile('retailer_123');
      expect(profile, isNotNull);
      expect(profile!['fullName'], 'Toko Makmur');
      expect(profile['storeName'], 'Toko Makmur Sejahtera');
      expect(profile['phoneNumber'], '08123456789');
    });
  });
}
