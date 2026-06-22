import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:ecommerce/features/dashboard/controllers/dashboard_cs_controller.dart';
import 'package:intl/intl.dart';

void main() {
  group('DashboardCsController Unit Tests (Whitebox)', () {
    late MockFirebaseAuth mockAuth;
    late FakeFirebaseFirestore mockFirestore;
    late DashboardCsController controller;

    setUp(() {
      final mockUser = MockUser(uid: 'cs_uid', email: 'cs@email.com');
      mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
      mockFirestore = FakeFirebaseFirestore();
      controller = DashboardCsController(auth: mockAuth, firestore: mockFirestore);
    });

    group('Stats & Streams Mappings (TC-20)', () {
      test('getComplaintStatsStream returns correct counts for pending and resolved today', () async {
        final now = DateTime.now();
        final subResolved = now.hour > 0 ? const Duration(minutes: 30) : const Duration(seconds: 1);
        final subCreated = now.hour > 0 ? const Duration(hours: 1) : const Duration(seconds: 2);

        // 1. Pending (open) complaint
        await mockFirestore.collection('complaints').doc('comp1').set({
          'status': 'pending',
          'createdAt': Timestamp.fromDate(now),
        });

        // 2. Resolved today complaint
        await mockFirestore.collection('complaints').doc('comp2').set({
          'status': 'resolved',
          'resolvedAt': Timestamp.fromDate(now.subtract(subResolved)),
          'createdAt': Timestamp.fromDate(now.subtract(subCreated)),
        });

        // 3. Resolved yesterday complaint (should not count as resolved today)
        await mockFirestore.collection('complaints').doc('comp3').set({
          'status': 'resolved',
          'resolvedAt': Timestamp.fromDate(now.subtract(const Duration(days: 1, hours: 2))),
          'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
        });

        final stream = controller.getComplaintStatsStream();
        final stats = await stream.first;

        expect(stats['openComplaints'], 1);
        expect(stats['resolvedToday'], 1);
      });

      test('getRecentComplaintsStream correctly maps issue parameters and formats time-ago strings', () async {
        final now = DateTime.now();

        // Seed complaints with different durations for time-ago checking
        // Just now
        await mockFirestore.collection('complaints').doc('comp_justnow').set({
          'issueType': 'Wrong Items Sent',
          'description': 'Description 1',
          'status': 'pending',
          'createdAt': Timestamp.fromDate(now.subtract(const Duration(seconds: 10))),
        });

        // 5 minutes ago
        await mockFirestore.collection('complaints').doc('comp_5m').set({
          'issueType': 'Damaged Package',
          'description': 'Description 2',
          'status': 'pending',
          'createdAt': Timestamp.fromDate(now.subtract(const Duration(minutes: 5))),
        });

        // 3 hours ago
        await mockFirestore.collection('complaints').doc('comp_3h').set({
          'issueType': 'Refund Delayed',
          'description': 'Description 3',
          'status': 'pending',
          'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 3))),
        });

        // 2 days ago
        await mockFirestore.collection('complaints').doc('comp_2d').set({
          'issueType': 'Wrong Billing',
          'description': 'Description 4',
          'status': 'resolved',
          'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
        });

        // 10 days ago (formatted Date)
        final tenDaysAgo = now.subtract(const Duration(days: 10));
        await mockFirestore.collection('complaints').doc('comp_10d').set({
          'issueType': 'Delivery Agent Rude',
          'description': 'Description 5',
          'status': 'rejected',
          'createdAt': Timestamp.fromDate(tenDaysAgo),
        });

        final stream = controller.getRecentComplaintsStream();
        final list = await stream.first;

        expect(list.length, 5);

        // Check first item (just now)
        final justNowItem = list.firstWhere((item) => item['id'] == 'comp_justnow');
        expect(justNowItem['timeAgo'], 'Just now');
        expect(justNowItem['title'], 'Wrong Items Sent');

        // Check 5m ago
        final fiveMinItem = list.firstWhere((item) => item['id'] == 'comp_5m');
        expect(fiveMinItem['timeAgo'], '5m ago');

        // Check 3h ago
        final threeHourItem = list.firstWhere((item) => item['id'] == 'comp_3h');
        expect(threeHourItem['timeAgo'], '3h ago');

        // Check 2d ago
        final twoDayItem = list.firstWhere((item) => item['id'] == 'comp_2d');
        expect(twoDayItem['timeAgo'], '2d ago');

        // Check 10d ago
        final tenDayItem = list.firstWhere((item) => item['id'] == 'comp_10d');
        expect(tenDayItem['timeAgo'], DateFormat('dd MMM yyyy').format(tenDaysAgo));
      });
    });

    group('CS Actions & Profiles', () {
      test('getCsInfo returns CS data', () async {
        await mockFirestore.collection('users').doc('cs_uid').set({
          'fullName': 'Agung Customer Service',
          'role': 'cs',
        });

        final info = await controller.getCsInfo();
        expect(info, isNotNull);
        expect(info!['fullName'], 'Agung Customer Service');
      });

      test('getUserProfile returns details of a given UID', () async {
        await mockFirestore.collection('users').doc('user123').set({
          'fullName': 'Retailer Buyer',
          'storeName': 'Kinarya Retail',
        });

        final profile = await controller.getUserProfile('user123');
        expect(profile, isNotNull);
        expect(profile!['storeName'], 'Kinarya Retail');
      });

      test('resolveComplaint sets status resolved, resolvedByName, and timestamp', () async {
        // Seed complaint and CS user
        await mockFirestore.collection('users').doc('cs_uid').set({
          'fullName': 'Sari CS',
          'role': 'cs',
        });
        await mockFirestore.collection('complaints').doc('complaint_abc').set({
          'status': 'pending',
        });

        final result = await controller.resolveComplaint('complaint_abc');

        expect(result, true);
        final doc = await mockFirestore.collection('complaints').doc('complaint_abc').get();
        expect(doc.data()?['status'], 'resolved');
        expect(doc.data()?['resolvedBy'], 'cs_uid');
        expect(doc.data()?['resolvedByName'], 'Sari CS');
        expect(doc.data()?['resolvedAt'], isNotNull);
      });

      test('rejectComplaint sets status rejected, resolvedByName, and timestamp', () async {
        // Seed complaint and CS user
        await mockFirestore.collection('users').doc('cs_uid').set({
          'fullName': 'Sari CS',
          'role': 'cs',
        });
        await mockFirestore.collection('complaints').doc('complaint_xyz').set({
          'status': 'pending',
        });

        final result = await controller.rejectComplaint('complaint_xyz');

        expect(result, true);
        final doc = await mockFirestore.collection('complaints').doc('complaint_xyz').get();
        expect(doc.data()?['status'], 'rejected');
        expect(doc.data()?['resolvedBy'], 'cs_uid');
        expect(doc.data()?['resolvedByName'], 'Sari CS');
      });
    });

    group('Error Paths & Exception Propagation', () {
      test('CsInfo returns null if unauthenticated', () async {
        await mockAuth.signOut();
        final info = await controller.getCsInfo();
        expect(info, null);
      });

      test('resolveComplaint throws exception if unauthenticated', () async {
        await mockAuth.signOut();
        expect(() => controller.resolveComplaint('complaint_id'), throwsA(isA<Exception>()));
      });

      test('rejectComplaint throws exception if unauthenticated', () async {
        await mockAuth.signOut();
        expect(() => controller.rejectComplaint('complaint_id'), throwsA(isA<Exception>()));
      });

      test('getUserProfile returns null if firestore throws error', () async {
        final badFirestore = MockFirestoreCustomException();
        final badController = DashboardCsController(auth: mockAuth, firestore: badFirestore);

        final profile = await badController.getUserProfile('uid');
        expect(profile, null);
      });
    });
  });
}

// Custom mock class
class MockFirestoreCustomException extends FakeFirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    throw Exception('Firestore query failed');
  }
}
