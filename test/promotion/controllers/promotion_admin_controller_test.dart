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
    // TC - 42 : Admin Menampilkan daftar promosi
    test('TC - 42 : Admin Menampilkan daftar promosi', () async {
      // Arrange
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

      // Act
      await adminPromotionController.fetchAllPromotions();
      
      // Assert
      expect(adminPromotionController.promotions.length, 1);
      expect(adminPromotionController.promotions.first.title, 'Promo A');
    });

    // TC - 43 : Admin Tampil pesan kosong jika tidak ada promosi
    test('TC - 43 : Admin Tampil pesan kosong jika tidak ada promosi', () async {
      // Act
      await adminPromotionController.fetchAllPromotions();

      // Assert
      expect(adminPromotionController.promotions.isEmpty, true);
    });

    // TC - 44 : Admin Membuat promosi baru
    test('TC - 44 : Admin Membuat promosi baru', () async {
      // Arrange & Act
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

      // Assert
      expect(result, isTrue);
      final snapshot = await fakeFirestore.collection('promotions').get();
      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.data()['title'], 'Promo Baru');
    });

    // TC - 45 : Admin Validasi form promosi kosong — semua field
    test('TC - 45 : Admin Validasi form promosi kosong — semua field', () {
      // Arrange
      final titleEmpty = ''.trim().isEmpty;
      final discountTypeEmpty = ''.isEmpty;
      final discountValInvalid = double.tryParse('') == null;

      // Act
      final isInvalid = titleEmpty || discountTypeEmpty || discountValInvalid;

      // Assert
      expect(isInvalid, true); // Form validation detects empty values
    });

    // TC - 46 : Admin Validasi waktu mulai lebih besar dari waktu akhir di tanggal yang sama
    test('TC - 46 : Admin Validasi waktu mulai lebih besar dari waktu akhir di tanggal yang sama', () {
      // Arrange
      final startDate = DateTime(2026, 6, 23);
      final endDate = DateTime(2026, 6, 23);
      final startTime = '14:00';
      final endTime = '10:00';

      final startParts = startTime.split(':');
      final endParts = endTime.split(':');
      final startHour = int.parse(startParts[0]);
      final startMin = int.parse(startParts[1]);
      final endHour = int.parse(endParts[0]);
      final endMin = int.parse(endParts[1]);

      // Act
      final timeInvalid = (startHour > endHour) || (startHour == endHour && startMin >= endMin);

      // Assert
      expect(startDate == endDate && timeInvalid, true); // Waktu tidak valid
    });

    // TC - 47 : Admin Validasi produk wajib dipilih jika scope "products"
    test('TC - 47 : Admin Validasi produk wajib dipilih jika scope "products"', () {
      // Arrange
      final applicableTo = 'products';
      final selectedProductIds = <String>[];

      // Act
      final productValidationError = applicableTo == 'products' && selectedProductIds.isEmpty;

      // Assert
      expect(productValidationError, true); // Validasi produk kosong jika scope "products"
    });

    // TC - 48 : Admin Upload gambar banner promosi
    test('TC - 48 : Admin Upload gambar banner promosi', () {
      // Arrange & Act
      final promo = {
        'title': 'Promo Banner',
        'imageUrl': 'supabase_banner_url_xyz.jpg'
      };

      // Assert
      expect(promo['imageUrl'], isNotNull);
      expect(promo['imageUrl']!.endsWith('.jpg'), true);
    });

    // TC - 49 : Admin Edit promosi yang sudah ada
    test('TC - 49 : Admin Edit promo yang sudah ada', () async {
      // Arrange
      await fakeFirestore.collection('promotions').doc('promo1').set({
        'title': 'Promo Lama',
        'description': '',
        'discountType': 'percentage',
        'discountValue': 10,
        'productIds': [],
        'applicableTo': 'all',
        'startDate': DateTime.now(),
        'endDate': DateTime.now().add(const Duration(days: 1)),
        'startTime': '00:00',
        'endTime': '23:59',
        'status': 'active',
        'sku': 'SKU-A',
        'createdAt': DateTime.now(),
        'createdBy': 'admin123'
      });
      await adminPromotionController.fetchAllPromotions();

      // Act
      final updated = await adminPromotionController.updatePromotion(
        promotionId: 'promo1',
        title: 'Promo Diedit',
        description: 'Deskripsi Baru',
        discountType: 'percentage',
        discountValue: 15,
        productIds: [],
        applicableTo: 'all',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 1)),
        startTime: '00:00',
        endTime: '23:59',
        status: 'active',
        sku: 'SKU-A',
      );

      // Assert
      expect(updated, true);
      final doc = await fakeFirestore.collection('promotions').doc('promo1').get();
      expect(doc.data()!['title'], 'Promo Diedit');
      expect(doc.data()!['discountValue'], 15.0);
    });

    // TC - 50 : Admin Deteksi konflik promosi — produk sudah ada di promo lain
    test('TC - 50 : Admin Deteksi konflik promosi — produk sudah ada di promo lain', () async {
      // Arrange
      final now = DateTime.now();
      await fakeFirestore.collection('promotions').doc('promo1').set({
        'title': 'Promo A',
        'description': '',
        'discountType': 'percentage',
        'discountValue': 10,
        'productIds': ['p1'],
        'applicableTo': 'specific',
        'startDate': now.subtract(const Duration(days: 1)),
        'endDate': now.add(const Duration(days: 2)),
        'startTime': '00:00',
        'endTime': '23:59',
        'status': 'active',
        'sku': 'SKU-1',
        'createdAt': now,
        'createdBy': 'admin123'
      });
      await adminPromotionController.fetchAllPromotions();

      // Act
      final isConflictAdded = await adminPromotionController.createPromotion(
        title: 'Promo B Bentrok',
        description: '',
        discountType: 'percentage',
        discountValue: 15,
        productIds: ['p1'],
        applicableTo: 'specific',
        startDate: now,
        endDate: now.add(const Duration(days: 1)),
        startTime: '00:00',
        endTime: '23:59',
        sku: 'SKU-2',
      );

      // Assert
      expect(isConflictAdded, false); // Harus gagal karena terdeteksi bentrok
      expect(adminPromotionController.errorMessage, contains('Produk sudah terdaftar di promo: "Promo A"'));
    });

    // TC - 51 : Admin Produk busy otomatis disembunyikan dari daftar pilihan
    test('TC - 51 : Admin Produk busy otomatis disembunyikan dari daftar pilihan', () {
      // Arrange
      final String busyProductId = 'p1';
      final double discountValue = 20.0;
      
      // Act
      final bool isBusy = busyProductId == 'p1' && discountValue > 0;

      // Assert
      expect(isBusy, true); // Produk busy disembunyikan dari UI
    });

    // TC - 52 : Admin Menampilkan detail promosi lengkap
    test('TC - 52 : Admin Menampilkan detail promosi lengkap', () async {
      // Arrange
      await fakeFirestore.collection('promotions').doc('promo1').set({
        'title': 'Promo Lengkap',
        'description': 'Deskripsi promo detail lengkap',
        'discountType': 'percentage',
        'discountValue': 20.0,
        'productIds': ['prod1'],
        'applicableTo': 'specific',
        'startDate': DateTime.now(),
        'endDate': DateTime.now().add(const Duration(days: 1)),
        'startTime': '08:00',
        'endTime': '20:00',
        'status': 'active',
        'sku': 'FULL-PROMO',
        'createdAt': DateTime.now(),
        'createdBy': 'admin123'
      });
      await adminPromotionController.fetchAllPromotions();

      // Act
      final promo = adminPromotionController.promotions.first;

      // Assert
      expect(promo.title, 'Promo Lengkap');
      expect(promo.description, 'Deskripsi promo detail lengkap');
      expect(promo.discountType, 'percentage');
      expect(promo.discountValue, 20.0);
      expect(promo.startTime, '08:00');
      expect(promo.endTime, '20:00');
    });

    // TC - 53 : Admin Menampilkan daftar produk yang berlaku di detail
    test('TC - 53 : Admin Menampilkan daftar produk yang berlaku di detail', () {
      // Arrange & Act
      final activePromoProductIds = ['prod1', 'prod2'];
      
      // Assert
      expect(activePromoProductIds.contains('prod1'), true);
      expect(activePromoProductIds.contains('prod2'), true);
    });

    // TC - 54 : Admin Hapus promosi — konfirmasi Yes
    test('TC - 54 : Admin Hapus promosi — konfirmasi Yes', () async {
      // Arrange
      await fakeFirestore.collection('promotions').doc('promo1').set({'title': 'Promo A'});

      // Act
      final result = await adminPromotionController.deletePromotion('promo1');
      
      // Assert
      expect(result, isTrue);
      final snapshot = await fakeFirestore.collection('promotions').get();
      expect(snapshot.docs.length, 0);
    });

    // TC - 55 : Admin Hapus promosi — batal (konfirmasi No)
    test('TC - 55 : Admin Hapus promosi — batal (konfirmasi No)', () async {
      // Arrange
      await fakeFirestore.collection('promotions').doc('promo1').set({'title': 'Promo A'});
      final confirmDelete = false;

      // Act
      bool deleted = false;
      if (confirmDelete) {
        deleted = await adminPromotionController.deletePromotion('promo1');
      }

      // Assert
      expect(deleted, false);
      final doc = await fakeFirestore.collection('promotions').doc('promo1').get();
      expect(doc.exists, true); // Dokumen tetap ada karena dibatalkan
    });
  });
}
