import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ecommerce/features/complaint/controllers/complaint_retail_controller.dart';
import 'package:ecommerce/supabase_storage_service.dart';
import 'package:ecommerce/features/notification/services/push_notification_service.dart';

class MockSupabaseStorageService extends Mock implements SupabaseStorageService {}
class MockPushNotificationService extends Mock implements PushNotificationService {}
class FakeFile extends Fake implements File {
  final String _path;
  FakeFile(this._path);
  @override
  String get path => _path;
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeFile('dummy.jpg'));
  });

  group('ComplaintUserController Unit Tests', () {
    late FakeFirebaseFirestore mockFirestore;
    late MockFirebaseAuth mockAuth;
    late MockSupabaseStorageService mockStorage;
    late MockPushNotificationService mockPush;
    late ComplaintUserController controller;

    const testUid = 'user123';

    setUp(() {
      mockFirestore = FakeFirebaseFirestore();
      final mockUser = MockUser(uid: testUid, email: 'retail@test.com');
      mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
      mockStorage = MockSupabaseStorageService();
      mockPush = MockPushNotificationService();

      controller = ComplaintUserController(
        auth: mockAuth,
        firestore: mockFirestore,
        storageService: mockStorage,
        pushNotificationService: mockPush,
      );
    });

    test('submitComplaint() berhasil jika user login dan mengirim data valid', () async {
      // Mock Storage Upload
      when(() => mockStorage.uploadComplaintImage(any(), any()))
          .thenAnswer((_) async => 'http://mock-url.com/image.jpg');

      // Mock Push Notification
      when(() => mockPush.sendNotificationToAdmin(
            title: any(named: 'title'),
            message: any(named: 'message'),
            type: any(named: 'type'),
            relatedId: any(named: 'relatedId'),
          )).thenAnswer((_) async => true);

      final files = [FakeFile('path/to/img.jpg')];

      final result = await controller.submitComplaint(
        orderId: 'ORDER-123',
        productName: 'Produk A',
        issueType: 'Barang Rusak',
        description: 'Barang pecah saat diterima',
        images: files,
      );

      expect(result, isTrue);

      final snapshot = await mockFirestore.collection('complaints').get();
      expect(snapshot.docs.length, 1);

      final data = snapshot.docs.first.data();
      expect(data['userId'], testUid);
      expect(data['orderId'], 'ORDER-123');
      expect(data['productName'], 'Produk A');
      expect(data['issueType'], 'Barang Rusak');
      expect(data['description'], 'Barang pecah saat diterima');
      expect(data['status'], 'pending');
      expect(data['imgUrl'], 'http://mock-url.com/image.jpg');
      
      // Verifikasi notifikasi terkirim
      verify(() => mockPush.sendNotificationToAdmin(
            title: 'Komplain Baru!',
            message: 'Ada komplain baru untuk pesanan ORDER-123: Barang Rusak.',
            type: 'complaint',
            relatedId: 'ORDER-123',
          )).called(1);
    });

    test('submitComplaint() gagal jika user belum login', () async {
      final unauthMockAuth = MockFirebaseAuth(signedIn: false);
      final unauthController = ComplaintUserController(
        auth: unauthMockAuth,
        firestore: mockFirestore,
        storageService: mockStorage,
        pushNotificationService: mockPush,
      );

      final result = await unauthController.submitComplaint(
        orderId: 'ORDER-123',
        issueType: 'Kurang Barang',
        description: 'Isi tidak sesuai',
        images: [],
      );

      expect(result, isFalse);
    });

    test('getUserComplaints() mengembalikan list komplain milik user diurutkan descending', () async {
      // Seed Data: Komplain Lama
      await mockFirestore.collection('complaints').add({
        'userId': testUid,
        'orderId': 'ORDER-LAMA',
        'issueType': 'Test Lama',
        'createdAt': DateTime(2026, 1, 1),
      });

      // Seed Data: Komplain Baru
      await mockFirestore.collection('complaints').add({
        'userId': testUid,
        'orderId': 'ORDER-BARU',
        'issueType': 'Test Baru',
        'createdAt': DateTime(2026, 1, 2),
      });

      // Seed Data: Komplain User Lain (seharusnya tidak terambil)
      await mockFirestore.collection('complaints').add({
        'userId': 'other_user',
        'orderId': 'ORDER-LAIN',
        'issueType': 'Lain',
        'createdAt': DateTime(2026, 1, 3),
      });

      final stream = controller.getUserComplaints();
      final complaints = await stream.first;

      expect(complaints.length, 2);
      // Diurutkan secara descending (terbaru di atas)
      expect(complaints[0].orderId, 'ORDER-BARU');
      expect(complaints[1].orderId, 'ORDER-LAMA');
    });

    test('getUserComplaints() mengembalikan list kosong jika user belum login', () async {
      final unauthMockAuth = MockFirebaseAuth(signedIn: false);
      final unauthController = ComplaintUserController(
        auth: unauthMockAuth,
        firestore: mockFirestore,
        storageService: mockStorage,
        pushNotificationService: mockPush,
      );

      final stream = unauthController.getUserComplaints();
      final complaints = await stream.first;

      expect(complaints.isEmpty, isTrue);
    });
  });
}
