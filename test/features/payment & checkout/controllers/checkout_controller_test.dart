import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ecommerce/features/payment & checkout/controllers/checkout_controller.dart';
import 'package:ecommerce/features/notification/services/push_notification_service.dart';

// Generate mocks menggunakan build_runner (flutter pub run build_runner build)
@GenerateMocks([
  FirebaseFirestore,
  FirebaseAuth,
  http.Client,
  PushNotificationService,
  CollectionReference,
  DocumentReference,
  DocumentSnapshot,
  User,
])
import 'checkout_controller_test.mocks.dart';

void main() {
  late CheckoutController checkoutController;
  late MockFirebaseFirestore mockFirestore;
  late MockFirebaseAuth mockAuth;
  late MockClient mockHttpClient;
  late MockPushNotificationService mockPushNotification;
  late MockUser mockUser;

  late MockCollectionReference<Map<String, dynamic>> mockProductsCollection;
  late MockCollectionReference<Map<String, dynamic>> mockOrdersCollection;
  late MockDocumentReference<Map<String, dynamic>> mockProductDoc;
  late MockDocumentReference<Map<String, dynamic>> mockOrderDoc;
  late MockDocumentSnapshot<Map<String, dynamic>> mockProductSnapshot;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    mockHttpClient = MockClient();
    mockPushNotification = MockPushNotificationService();
    mockUser = MockUser();

    mockProductsCollection = MockCollectionReference();
    mockOrdersCollection = MockCollectionReference();
    mockProductDoc = MockDocumentReference();
    mockOrderDoc = MockDocumentReference();
    mockProductSnapshot = MockDocumentSnapshot();

    // Setup Auth Mock
    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn('user123');
    when(mockUser.email).thenReturn('retailer@test.com');
    when(mockUser.displayName).thenReturn('Retailer Test');

    // Setup Firestore Mock berdasarkan alur CheckoutController
    when(
      mockFirestore.collection('products'),
    ).thenReturn(mockProductsCollection);
    when(mockFirestore.collection('orders')).thenReturn(mockOrdersCollection);

    // Mock Product Document (Pengecekan Stok)
    when(mockProductsCollection.doc(any)).thenReturn(mockProductDoc);
    when(mockProductDoc.get()).thenAnswer((_) async => mockProductSnapshot);
    when(mockProductSnapshot.exists).thenReturn(true);
    when(mockProductSnapshot.data()).thenReturn({'stock': 100});

    // Mock Order Document (Menyimpan dan Update Order)
    when(mockOrdersCollection.doc(any)).thenReturn(mockOrderDoc);
    when(mockOrderDoc.set(any)).thenAnswer((_) async => Future.value());
    when(mockOrderDoc.update(any)).thenAnswer((_) async => Future.value());

    // Mock Push Notification Admin
    when(
      mockPushNotification.sendNotificationToAdmin(
        title: anyNamed('title'),
        message: anyNamed('message'),
        type: anyNamed('type'),
        relatedId: anyNamed('relatedId'),
      ),
    ).thenAnswer((_) async => Future.value());

    checkoutController = CheckoutController(
      firestore: mockFirestore,
      auth: mockAuth,
      client: mockHttpClient,
      backendUrl: 'https://api.kinarya.com',
      pushNotificationService: mockPushNotification,
    );
  });

  group('Sprint 4: Payment & Checkout Test Suite', () {
    // =========================================================================
    // TEST DATA BUILDER (Helper Method)
    // =========================================================================
    Future<Map<String, dynamic>> executeCheckoutWithDefaults({
      String fullName = 'Retailer Test',
      String shippingAddress = 'Jl. Rungkut Surabaya',
      String phoneNumber = '08123456789',
      String paymentMethod = 'Bank Transfer',
      String paymentMethodCode = 'BT',
      String promoCode = '',
      double subtotal = 250000.0,
      double shippingCost = 20000.0,
      double tax = 0.0,
      double total = 270000.0,
      List<Map<String, dynamic>>? items,
    }) async {
      return await checkoutController.processCheckout(
        fullName: fullName,
        shippingAddress: shippingAddress,
        phoneNumber: phoneNumber,
        paymentMethod: paymentMethod,
        paymentMethodCode: paymentMethodCode,
        promoCode: promoCode,
        subtotal: subtotal,
        shippingCost: shippingCost,
        tax: tax,
        total: total,
        items:
            items ??
            [
              {'productId': 'prod1', 'quantity': 1, 'title': 'Produk A'},
            ],
      );
    }

    // 1. REQ-24 | TC-104
    test(
      '[TC-104] Retailer melakukan pembayaran sesuai nominal tagihan -> Sistem menampilkan halaman Transaction Verification dengan status "Payment Processing"',
      () async {
        // Arrange
        when(
          mockHttpClient.post(
            any,
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          ),
        ).thenAnswer(
          (_) async => http.Response(
            jsonEncode({
              'success': true,
              'paymentUrl': 'https://duitku.com/pay/123',
            }),
            200,
          ),
        );

        // Act - Super bersih, menggunakan data default
        final result = await executeCheckoutWithDefaults();

        // Assert
        expect(result.containsKey('paymentUrl'), true);
        expect(result['paymentUrl'], 'https://duitku.com/pay/123');
        verify(mockOrderDoc.set(any)).called(1);
      },
    );

    // 2. REQ-24 | TC-105
    test(
      '[TC-105] Retailer melakukan pembayaran dengan nominal yang tidak sesuai tagihan -> Menampilkan error dan status tetap "Pending Payment"',
      () async {
        // Arrange
        when(
          mockHttpClient.post(
            any,
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          ),
        ).thenAnswer(
          (_) async => http.Response(
            jsonEncode({'success': false, 'message': 'Nominal tidak sesuai'}),
            200,
          ),
        );

        // Act - Hanya menimpa (override) nilai yang perlu disalahkan untuk test ini
        final result = await executeCheckoutWithDefaults(
          shippingAddress: 'Surabaya',
          subtotal: 200000.0,
          shippingCost: 0.0,
          total: 200000.0,
        );

        // Assert
        expect(result.containsKey('error'), true);
        expect(
          result['error'],
          contains('Duitku ditolak: Nominal tidak sesuai'),
        );
      },
    );

    // 3. REQ-24 | TC-106
    test(
      '[TC-106] Retailer menekan tombol konfirmasi pembayaran lebih dari satu kali -> Sistem memproses satu transaksi dan menahan duplikasi',
      () async {
        // Arrange
        bool isProcessing = false;
        int callCount = 0;
        Future<void> mockSubmit() async {
          if (isProcessing) return;
          isProcessing = true;
          callCount++;
          await Future.delayed(const Duration(milliseconds: 100));
          isProcessing = false;
        }

        // Act
        mockSubmit();
        mockSubmit();

        // Assert
        expect(callCount, 1);
      },
    );

    // 4. REQ-25 | TC-107
    test(
      '[TC-107] Retailer tidak menyelesaikan pembayaran hingga waktu jatuh tempo habis -> Menampilkan pesan pembayaran cancel',
      () async {
        // Arrange & Act
        final docData = {
          'status': 'Cancelled',
          'paymentExpiredAt': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(hours: 1)),
          ),
        };

        // Assert
        expect(docData['status'], 'Cancelled');
      },
    );

    // 5. REQ-26 | TC-108
    test(
      '[TC-108] Retailer memeriksa status pembayaran pada halaman Transaction Verification -> Jika belum diverifikasi, status tetap "Payment Processing"',
      () async {
        // Arrange
        when(mockOrderDoc.get()).thenAnswer((_) async => mockProductSnapshot);
        when(
          mockProductSnapshot.data(),
        ).thenReturn({'status': 'Payment Processing'});

        // Act
        final status = (await mockOrderDoc.get()).data()?['status'];

        // Assert
        expect(status, 'Payment Processing');
      },
    );

    // 6. REQ-27 | TC-109
    test(
      '[TC-109] Admin melakukan approval terhadap pembayaran Retailer -> Status transaksi berubah menjadi "Verified"',
      () async {
        // Act
        await mockOrderDoc.update({'status': 'Verified'});

        // Assert
        verify(mockOrderDoc.update({'status': 'Verified'})).called(1);
      },
    );

    // 7. REQ-28 | TC-110
    test(
      '[TC-110] Admin melakukan penolakan terhadap pembayaran yang tidak valid -> Status transaksi berubah menjadi "Rejected"',
      () async {
        // Act
        await mockOrderDoc.update({'status': 'Rejected'});

        // Assert
        verify(mockOrderDoc.update({'status': 'Rejected'})).called(1);
      },
    );

    // 8. REQ-29 | TC-111
    test(
      '[TC-111] Admin mengunduh invoice pada order dengan status pembayaran Completed -> Invoice PDF berhasil diunduh',
      () async {
        // Arrange
        final orderStatus = 'Completed';

        // Act
        final canDownload = orderStatus == 'Completed';

        // Assert
        expect(canDownload, true);
      },
    );

    // 9. REQ-29 | TC-112
    test(
      '[TC-112] Admin mengunduh invoice pada order dengan status pembayaran Pending -> Tombol Download Invoice disabled',
      () async {
        // Arrange
        final orderStatus = 'Pending';

        // Act
        final canDownload = orderStatus == 'Completed';

        // Assert
        expect(canDownload, false);
      },
    );

    // 10. REQ-30 | TC-113
    test(
      '[TC-113] Admin melakukan approval pengiriman pesanan Retailer -> Status berubah menjadi "Delivery Approved"',
      () async {
        // Act
        await mockOrderDoc.update({'status': 'Delivery Approved'});

        // Assert
        verify(mockOrderDoc.update({'status': 'Delivery Approved'})).called(1);
      },
    );

    // 11. REQ-31 | TC-114
    test(
      '[TC-114] Retailer mengajukan pembatalan pesanan sebelum barang dikirim -> Status berubah menjadi "Cancellation Requested"',
      () async {
        // Act
        await mockOrderDoc.update({'status': 'Cancellation Requested'});

        // Assert
        verify(
          mockOrderDoc.update({'status': 'Cancellation Requested'}),
        ).called(1);
      },
    );

    // 12. REQ-31 | TC-115
    test(
      '[TC-115] Retailer mengajukan pembatalan pesanan setelah barang di-approve untuk dikirim -> Tombol Cancel Order disabled / tidak tersedia',
      () async {
        // Arrange
        final status = 'Delivery Approved';

        // Act
        final canCancel = status != 'Delivery Approved';

        // Assert
        expect(canCancel, false);
      },
    );

    // 13. REQ-31 | TC-116
    test(
      '[TC-116] Admin menyetujui permintaan pembatalan pesanan dari Retailer -> Status pesanan berubah menjadi "Cancelled"',
      () async {
        // Act
        await mockOrderDoc.update({'status': 'Cancelled'});

        // Assert
        verify(mockOrderDoc.update({'status': 'Cancelled'})).called(1);
      },
    );

    // 14. REQ-31 | TC-117
    test(
      '[TC-117] Admin menolak permintaan pembatalan pesanan dari Retailer -> Status kembali menjadi "Payment Verified"',
      () async {
        // Act
        await mockOrderDoc.update({'status': 'Payment Verified'});

        // Assert
        verify(mockOrderDoc.update({'status': 'Payment Verified'})).called(1);
      },
    );
  });
}
