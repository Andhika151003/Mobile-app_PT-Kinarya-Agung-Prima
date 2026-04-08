import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
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
    test('getComplaintStats returns default static structure', () async {
      final stats = await dashboardController.getComplaintStats();
      expect(stats, isNotNull);
      expect(stats['openComplaints'], equals(24));
      expect(stats['resolvedToday'], equals(18));
    });

    test('getRecentComplaints returns mock active list', () async {
      final complaints = await dashboardController.getRecentComplaints();
      expect(complaints.length, equals(2));
      expect(complaints[0]['id'], equals('001'));
      expect(complaints[0]['status'], equals('open'));
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

    test('resolveComplaint updates complaint status to resolved', () async {
      await fakeFirestore.collection('complaints').doc('comp001').set({
        'status': 'open',
        'title': 'Problem ABC',
      });

      final result = await dashboardController.resolveComplaint('comp001');
      expect(result, isTrue);

      final doc = await fakeFirestore.collection('complaints').doc('comp001').get();
      expect(doc.data()!['status'], equals('resolved'));
      expect(doc.data()!['resolvedBy'], equals('cs123'));
      expect(doc.data()!['resolvedAt'], isNotNull);
    });
  });
}
