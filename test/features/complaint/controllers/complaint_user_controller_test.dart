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
  group('Unit Test: Controller Komplain Retailer (ComplaintUserController)', () {
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

    test('TC-122: Mengajukan komplain dengan mengisi seluruh data wajib (berhasil)', () async {
      // Menyiapkan tiruan upload gambar ke Supabase Storage
      final fakeFile = FakeFile('path/to/img.jpg');
      when(() => mockStorage.uploadComplaintImage(fakeFile, any()))
          .thenAnswer((_) async => 'http://mock-url.com/image.jpg');

      // Menyiapkan tiruan pengiriman notifikasi ke Admin
      when(() => mockPush.sendNotificationToAdmin(
            title: any(named: 'title'),
            message: any(named: 'message'),
            type: any(named: 'type'),
            relatedId: any(named: 'relatedId'),
          )).thenAnswer((_) async => true);

      final files = [fakeFile];

      final result = await controller.submitComplaint(
        orderId: 'ORDER-123',
        productName: 'Produk A',
        issueType: 'Barang Rusak',
        description: 'Barang pecah saat diterima',
        images: files,
      );

      // Memastikan pengajuan berhasil
      expect(result, isTrue);

      // Memastikan dokumen komplain tersimpan di Firestore
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

      // Memastikan notifikasi terkirim ke Admin
      verify(() => mockPush.sendNotificationToAdmin(
            title: 'Komplain Baru!',
            message: 'Ada komplain baru untuk pesanan ORDER-123: Barang Rusak.',
            type: 'complaint',
            relatedId: 'ORDER-123',
          )).called(1);
    });

    test('TC-123: Mengajukan komplain tanpa mengisi/memilih jenis kendala', () async {
      when(() => mockPush.sendNotificationToAdmin(
            title: any(named: 'title'),
            message: any(named: 'message'),
            type: any(named: 'type'),
            relatedId: any(named: 'relatedId'),
          )).thenAnswer((_) async => true);

      final result = await controller.submitComplaint(
        orderId: 'ORDER-123',
        issueType: '',
        description: 'Barang yang saya terima mengalami kerusakan parah',
        images: [],
      );

      expect(result, isTrue);

      final snapshot = await mockFirestore.collection('complaints').get();
      expect(snapshot.docs.length, 1);

      final data = snapshot.docs.first.data();
      expect(data['issueType'], '');
    });

    test('TC-124: Mengajukan komplain tanpa mengisi deskripsi kendala', () async {
      when(() => mockPush.sendNotificationToAdmin(
            title: any(named: 'title'),
            message: any(named: 'message'),
            type: any(named: 'type'),
            relatedId: any(named: 'relatedId'),
          )).thenAnswer((_) async => true);

      final result = await controller.submitComplaint(
        orderId: 'ORDER-123',
        issueType: 'Barang Rusak',
        description: '',
        images: [],
      );

      expect(result, isTrue);

      final snapshot = await mockFirestore.collection('complaints').get();
      expect(snapshot.docs.length, 1);

      final data = snapshot.docs.first.data();
      expect(data['description'], '');
    });

    test('TC-125: Mengajukan komplain tanpa memilih produk spesifik (nama produk kosong)', () async {
      when(() => mockPush.sendNotificationToAdmin(
            title: any(named: 'title'),
            message: any(named: 'message'),
            type: any(named: 'type'),
            relatedId: any(named: 'relatedId'),
          )).thenAnswer((_) async => true);

      final result = await controller.submitComplaint(
        orderId: 'ORDER-123',
        issueType: 'Barang Rusak',
        description: 'Barang yang saya terima mengalami kerusakan parah',
        images: [],
      );

      expect(result, isTrue);

      final snapshot = await mockFirestore.collection('complaints').get();
      final data = snapshot.docs.first.data();
      expect(data.containsKey('productName'), isFalse);
    });

    test('TC-126: Mengajukan komplain tanpa mengunggah foto bukti (lampiran kosong)', () async {
      when(() => mockPush.sendNotificationToAdmin(
            title: any(named: 'title'),
            message: any(named: 'message'),
            type: any(named: 'type'),
            relatedId: any(named: 'relatedId'),
          )).thenAnswer((_) async => true);

      final result = await controller.submitComplaint(
        orderId: 'ORDER-456',
        issueType: 'Barang Kurang',
        description: 'Isi tidak lengkap',
        images: [],
      );

      expect(result, isTrue);

      final snapshot = await mockFirestore.collection('complaints').get();
      expect(snapshot.docs.length, 1);

      final data = snapshot.docs.first.data();
      expect(data['imgUrl'], '');
      expect(data['imageUrls'], []);
    });

    test('TC-127: Memformat nomor telepon agar sesuai dengan format WhatsApp API (kode negara 62)', () {
      expect(ComplaintUserController.formatPhoneForWhatsApp('08123456789'), '628123456789');
      expect(ComplaintUserController.formatPhoneForWhatsApp('628123456789'), '628123456789');
      expect(ComplaintUserController.formatPhoneForWhatsApp('+62 812-3456-789'), '628123456789');
      expect(ComplaintUserController.formatPhoneForWhatsApp('021-1234567'), '62211234567');
      expect(ComplaintUserController.formatPhoneForWhatsApp(''), '');
    });
  });
}