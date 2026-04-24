import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce/features/dashboard/controllers/dashboard_cs_controller.dart';

void main() {
  late DashboardCsController dashboardController;
  late MockFirebaseAuth mockAuth;
  late FakeFirebaseFirestore fakeFirestore;
  late MockUser mockUser;

  setUp(() {
    mockUser = MockUser(
      isAnonymous: false,
      uid: 'cs123',
      email: 'cs@test.com',
    );
    mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
    fakeFirestore = FakeFirebaseFirestore();

    dashboardController = DashboardCsController(
      auth: mockAuth,
      firestore: fakeFirestore,
    );
  });

  group('DashboardCsController Tests', () {
    test('getComplaintStatsStream returns real-time stats', () async {
      // Seed data
      await fakeFirestore.collection('complaints').add({
        'status': 'pending',
        'createdAt': Timestamp.now(),
      });
      await fakeFirestore.collection('complaints').add({
        'status': 'resolved',
        'resolvedAt': Timestamp.now(),
        'createdAt': Timestamp.now(),
      });

      final statsStream = dashboardController.getComplaintStatsStream();
      final stats = await statsStream.first;

      expect(stats['openComplaints'], equals(1));
      expect(stats['resolvedToday'], equals(1));
    });

    test('getRecentComplaintsStream returns real-time list', () async {
      // Seed data
      await fakeFirestore.collection('complaints').add({
        'userId': 'user1',
        'imgUrl': '',
        'orderId': 'KNY-123',
        'issueType': 'Broken Item',
        'description': 'Item arrived broken',
        'status': 'pending',
        'createdAt': Timestamp.now(),
      });

      final complaintsStream = dashboardController.getRecentComplaintsStream();
      final complaints = await complaintsStream.first;

      expect(complaints.length, equals(1));
      expect(complaints[0]['storeName'], equals('Order #KNY-123'));
      expect(complaints[0]['status'], equals('pending'));
    });

    test('getCsInfo returns CS doc data', () async {
      await fakeFirestore.collection('users').doc('cs123').set({
        'role': 'cs',
        'fullName': 'Sari CS',
      });

      final info = await dashboardController.getCsInfo();
      expect(info, isNotNull);
      expect(info!['fullName'], equals('Sari CS'));
    });

    test('resolveComplaint updates complaint status to resolved and records CS name', () async {
      await fakeFirestore.collection('users').doc('cs123').set({
        'role': 'cs',
        'fullName': 'Sari CS',
      });

      await fakeFirestore.collection('complaints').doc('comp001').set({
        'status': 'pending',
        'orderId': 'KNY-999',
        'createdAt': Timestamp.now(),
      });

      final result = await dashboardController.resolveComplaint('comp001');
      expect(result, isTrue);

      final doc = await fakeFirestore.collection('complaints').doc('comp001').get();
      expect(doc.data()!['status'], equals('resolved'));
      expect(doc.data()!['resolvedBy'], equals('cs123'));
      expect(doc.data()!['resolvedByName'], equals('Sari CS'));
      expect(doc.data()!['resolvedAt'], isNotNull);
    });
  });
}
