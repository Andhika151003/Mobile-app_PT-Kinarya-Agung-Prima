import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:ecommerce/features/promotion/controllers/promotion_admin_controller.dart';
import 'package:ecommerce/features/promotion/models/promotion.dart';

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

  group('PromotionAdminController Tests', () {
    test('fetchAllPromotions fetches data and sets to list', () async {
      await fakeFirestore.collection('promotions').doc('promo1').set({
        'title': 'Promo A',
        'description': 'Desc A',
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

      await adminPromotionController.fetchAllPromotions();
      
      expect(adminPromotionController.promotions.length, 1);
      expect(adminPromotionController.promotions.first.title, 'Promo A');
      expect(adminPromotionController.filteredPromotions.length, 1);
    });

    test('createPromotion inserts into firestore', () async {
      final result = await adminPromotionController.createPromotion(
        title: 'New Promo',
        description: 'Promo Baru',
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

      expect(result, isTrue);
      final snapshot = await fakeFirestore.collection('promotions').get();
      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.data()['title'], 'New Promo');
    });

    test('deletePromotion removes document from firestore', () async {
      await fakeFirestore.collection('promotions').doc('promo1').set({'title': 'Promo A'});

      final result = await adminPromotionController.deletePromotion('promo1');
      
      expect(result, isTrue);
      final snapshot = await fakeFirestore.collection('promotions').get();
      expect(snapshot.docs.length, 0);
    });
  });
}
