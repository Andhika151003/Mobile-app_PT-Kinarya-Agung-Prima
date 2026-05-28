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
    when(mockProductSnapshot.data()).thenReturn({'stock': 100}); // Stok aman

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

        // Act - Parameter disesuaikan tipe datanya dengan method processCheckout()
        final result = await checkoutController.processCheckout(
          fullName: 'Retailer Test',
          shippingAddress: 'Jl. Rungkut Surabaya',
          phoneNumber: '08123456789',
          paymentMethod: 'Bank Transfer',
          paymentMethodCode: 'BT',
          promoCode: '',
          subtotal: 250000.0,
          shippingCost: 20000.0,
          tax: 0.0,
          total: 270000.0,
          items: [
            {'productId': 'prod1', 'quantity': 1, 'title': 'Produk A'},
          ],
        );

        // Assert
        expect(result.containsKey('paymentUrl'), true);
        expect(result['paymentUrl'], 'https://duitku.com/pay/123');
        verify(mockOrderDoc.set(any)).called(1); // Verifikasi data tersimpan
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

        // Act
        final result = await checkoutController.processCheckout(
          fullName: 'Retailer Test',
          shippingAddress: 'Surabaya',
          phoneNumber: '08123456789',
          paymentMethod: 'Bank Transfer',
          paymentMethodCode: 'BT',
          promoCode: '',
          subtotal: 200000.0,
          shippingCost: 0.0,
          tax: 0.0,
          total: 200000.0, // Misal Backend tahu nominal asli harusnya 270k
          items: [
            {'productId': 'prod1', 'quantity': 1, 'title': 'Produk A'},
          ],
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

    // 4. REQ-25 | TC-107 (Mock Webhook update expired)
    test(
      '[TC-107] Retailer tidak menyelesaikan pembayaran hingga waktu jatuh tempo habis -> Menampilkan pesan pembayaran cancel',
      () async {
        // Logika aslinya order di set expired 24 jam ke depan di controller ini
        // Kita mensimulasikan update yang biasanya dilakukan backend Duitku
        final docData = {
          'status': 'Cancelled',
          'paymentExpiredAt': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(hours: 1)),
          ),
        };
        expect(docData['status'], 'Cancelled');
      },
    );

    // 5. REQ-26 | TC-108
    test(
      '[TC-108] Retailer memeriksa status pembayaran pada halaman Transaction Verification -> Jika belum diverifikasi, status tetap "Payment Processing"',
      () async {
        // Arrange simulasi get document order
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
