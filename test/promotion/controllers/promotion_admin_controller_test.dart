import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:ecommerce/features/promotion/controllers/promotion_admin_controller.dart';

void main() {
  late PromotionAdminController adminPromotionController;
  late MockFirebaseAuth mockAuth;
  late FakeFirebaseFirestore fakeFirestore;
  late MockUser mockUser;

  setUp(() {
    mockUser = MockUser(isAnonymous: false, uid: 'admin123');
    mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
    fakeFirestore = FakeFirebaseFirestore();

    adminPromotionController = PromotionAdminController(
      firestore: fakeFirestore,
      auth: mockAuth,
    );
  });

  group('Unit Test PromotionAdminController', () {
    test('fetchAllPromotions harus mengambil data dan memasukkannya ke dalam list', () async {
      // Arrange — Menambahkan dokumen promo ke Fake Firestore sebagai data simulasi
      await fakeFirestore.collection('promotions').doc('promo1').set({
        'title': 'Promo A',
        'description': 'Deskripsi A',
        'discountType': 'percentage',
        'discountValue': 10,
        'productIds': [],
        'applicableTo': 'all',
        'startDate': DateTime.now().subtract(const Duration(days: 1)),
        'endDate': DateTime.now().add(const Duration(days: 1)),
        'startTime': '00:00',
        'endTime': '23:59',
        'status': 'active',
        'imageUrl': '',
        'sku': 'SKU-A',
        'createdAt': DateTime.now(),
        'createdBy': 'admin123'
      });

      // Act — Memanggil fetchAllPromotions() untuk mengambil data dari Firestore
      await adminPromotionController.fetchAllPromotions();
      
      // Assert — Memverifikasi data berhasil masuk ke list promotions dan filteredPromotions
      expect(adminPromotionController.promotions.length, 1);
      expect(adminPromotionController.promotions.first.title, 'Promo A');
      expect(adminPromotionController.filteredPromotions.length, 1);
    });

    test('createPromotion harus menyimpan data ke Firestore', () async {
      // Arrange — Menyiapkan parameter untuk membuat promo baru (tidak perlu data awal di Firestore)

      // Act — Memanggil createPromotion() dengan data promo baru
      final result = await adminPromotionController.createPromotion(
        title: 'Promo Baru',
        description: 'Deskripsi Promo Baru',
        discountType: 'fixed',
        discountValue: 5000,
        productIds: [],
        applicableTo: 'specific',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 5)),
        startTime: '10:00',
        endTime: '12:00',
        sku: 'NEW-PROMO-5000',
      );

      // Assert — Memverifikasi promo berhasil disimpan ke Firestore
      expect(result, isTrue);
      final snapshot = await fakeFirestore.collection('promotions').get();
      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.data()['title'], 'Promo Baru');
    });

    test('deletePromotion harus menghapus dokumen dari Firestore', () async {
      // Arrange — Menambahkan dokumen promo yang akan dihapus
      await fakeFirestore.collection('promotions').doc('promo1').set({'title': 'Promo A'});

      // Act — Memanggil deletePromotion() untuk menghapus dokumen
      final result = await adminPromotionController.deletePromotion('promo1');
      
      // Assert — Memverifikasi dokumen berhasil dihapus dari Firestore
      expect(result, isTrue);
      final snapshot = await fakeFirestore.collection('promotions').get();
      expect(snapshot.docs.length, 0);
    });
  });
}
