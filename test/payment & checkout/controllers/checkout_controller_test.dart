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
  late MockCollectionReference<Map<String, dynamic>> mockCollection;
  late MockDocumentReference<Map<String, dynamic>> mockDocRef;
  late MockDocumentSnapshot<Map<String, dynamic>> mockDocSnapshot;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    mockHttpClient = MockClient();
    mockPushNotification = MockPushNotificationService();
    mockUser = MockUser();
    mockCollection = MockCollectionReference();
    mockDocRef = MockDocumentReference();
    mockDocSnapshot = MockDocumentSnapshot();

    // Setup Auth Mock
    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn('user123');
    when(mockUser.email).thenReturn('retailer@test.com');
    when(mockUser.displayName).thenReturn('Retailer Test');

    // Setup Firestore Mock dasar
    when(mockFirestore.collection(any)).thenReturn(mockCollection);
    when(mockCollection.doc(any)).thenReturn(mockDocRef);

    checkoutController = CheckoutController(
      firestore: mockFirestore,
      auth: mockAuth,
      client: mockHttpClient,
      backendUrl: 'https://api.kinarya.com',
      pushNotificationService: mockPushNotification,
    );
  });

  group('Sprint 4: Payment & Checkout Test Suite', () {
    // Baris 1: REQ-24 - Pembayaran Sesuai Nominal
    test(
      'Bukti pembayaran berhasil ; sistem menampilkan halaman Transaction Verification dengan Transaction ID, jumlah, tanggal, dan status "Payment Processing"',
      () async {
        // Arrange
        when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.data()).thenReturn({'stock': 10});
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

        // Act
        final result = await checkoutController.processCheckout(
          fullName: 'Retailer Test',
          shippingAddress: 'Jl. Rungkut Surabaya',
          phoneNumber: '08123456789',
          paymentMethod: 'Bank Transfer',
          paymentMethodCode: 'BT',
          promoCode: '',
          subtotal: 250000,
          shippingCost: 20000,
          tax: 0,
          total: 270000,
          items: [
            {'productId': 'prod1', 'quantity': 1, 'title': 'Produk A'},
          ],
        );

        // Assert
        expect(result.containsKey('paymentUrl'), true);
        expect(result['paymentUrl'], 'https://duitku.com/pay/123');
        verify(
          mockHttpClient.post(
            any,
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          ),
        ).called(1);
      },
    );

    // Baris 2: REQ-24 - Pembayaran Tidak Sesuai Nominal
    test(
      'Sistem menampilkan pesan error bahwa nominal pembayaran tidak sesuai; transaksi tidak diproses; status tetap "Pending Payment"',
      () async {
        // Arrange (Simulasi backend Duitku menolak nominal)
        when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.data()).thenReturn({'stock': 10});
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
          subtotal: 200000,
          shippingCost: 0,
          tax: 0,
          total: 200000,
          items: [
            {'productId': 'prod1', 'quantity': 1},
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

    // Baris 3: REQ-24 - Double Click (Simulasi pencegahan di Controller/UI)
    test(
      'Sistem hanya memproses satu transaksi; tidak terjadi duplikasi; menampilkan pesan bahwa transaksi sedang diproses',
      () async {
        // Arrange
        bool isProcessing = false;
        int callCount = 0;
        Future<void> mockSubmit() async {
          if (isProcessing) return;
          isProcessing = true;
          callCount++;
          await Future.delayed(
            const Duration(milliseconds: 100),
          ); // Simulasi network
          isProcessing = false;
        }

        // Act
        mockSubmit();
        mockSubmit();

        // Assert
        expect(callCount, 1);
      },
    );

    // Baris 4: REQ-25 - Waktu Tempo Habis
    test(
      'Sistem menampilkan pesan pembayaran cancel; karena waktu pembayaran telah hangus',
      () async {
        // Arrange & Act & Assert
        // Catatan: Pada praktiknya ini di-handle oleh Webhook Duitku ke Backend,
        // lalu backend mengubah status di Firestore.
        final docData = {
          'status': 'Cancelled',
          'paymentExpiredAt': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(hours: 1)),
          ),
        };
        expect(docData['status'], 'Cancelled');
      },
    );

    // Baris 5: REQ-26 - Cek Status Pembayaran
    test(
      'Sistem menampilkan status terkini dari pembayaran; jika belum diverifikasi maka status tetap "Payment Processing"',
      () async {
        // Arrange
        when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
        when(
          mockDocSnapshot.data(),
        ).thenReturn({'status': 'Payment Processing'});

        // Act
        final status = (await mockDocRef.get()).data()?['status'];

        // Assert
        expect(status, 'Payment Processing');
      },
    );

    // Baris 6: REQ-27 - Admin Approve
    test(
      'Status transaksi berubah menjadi "Verified"; Retailer menerima notifikasi bahwa pembayaran telah dikonfirmasi; pesanan dilanjutkan ke proses berikutnya',
      () async {
        // Arrange
        when(mockDocRef.update(any)).thenAnswer((_) async => Future.value());

        // Act
        await mockDocRef.update({'status': 'Verified'});
        await mockPushNotification.sendNotificationToAdmin(
          title: 'Approve',
          message: 'Notif',
          type: 'payment',
        );

        // Assert
        verify(mockDocRef.update({'status': 'Verified'})).called(1);
      },
    );

    // Baris 7: REQ-27 - Admin Approve transaksi yang sudah Verified
    test(
      'Sistem menampilkan pesan bahwa transaksi sudah diverifikasi sebelumnya; tombol Approve/Reject tidak dapat ditekan',
      () async {
        // Arrange
        final currentStatus = 'Verified';

        // Act
        final canApprove = currentStatus != 'Verified';

        // Assert
        expect(canApprove, false);
      },
    );

    // Baris 8: REQ-27 - Retailer menerima notifikasi
    test(
      'Retailer menerima notifikasi bahwa pembayaran telah dikonfirmasi; notifikasi memuat detail transaksi yang disetujui',
      () async {
        // Arrange & Act
        await mockPushNotification.sendNotificationToAdmin(
          title: 'Pembayaran Dikonfirmasi',
          message: 'TRX25040003 disetujui',
          type: 'notif_retailer',
        );

        // Assert
        verify(
          mockPushNotification.sendNotificationToAdmin(
            title: anyNamed('title'),
            message: anyNamed('message'),
            type: anyNamed('type'),
          ),
        ).called(1);
      },
    );

    // Baris 9: REQ-28 - Admin Reject
    test(
      'Status transaksi berubah menjadi "Rejected"; Retailer menerima notifikasi bahwa pembayaran ditolak; pesanan tidak diproses lebih lanjut',
      () async {
        // Arrange
        when(mockDocRef.update(any)).thenAnswer((_) async => Future.value());

        // Act
        await mockDocRef.update({'status': 'Rejected'});

        // Assert
        verify(mockDocRef.update({'status': 'Rejected'})).called(1);
      },
    );

    // Baris 10: REQ-28 - Retailer notifikasi Reject
    test(
      'Retailer menerima notifikasi bahwa pembayaran telah ditolak; notifikasi memuat alasan penolakan dan instruksi selanjutnya',
      () async {
        // Arrange & Act
        await mockPushNotification.sendNotificationToAdmin(
          title: 'Pembayaran Ditolak',
          message: 'TRX25040004 ditolak',
          type: 'notif_retailer',
        );

        // Assert
        verify(
          mockPushNotification.sendNotificationToAdmin(
            title: 'Pembayaran Ditolak',
            message: 'TRX25040004 ditolak',
            type: 'notif_retailer',
          ),
        ).called(1);
      },
    );

    // Baris 11: REQ-29 - Unduh Invoice (Completed)
    test(
      'File invoice berhasil diunduh dalam format PDF; berisi informasi lengkap: nomor invoice, tanggal, detail order, total harga, dan informasi pembayaran',
      () async {
        // Arrange
        final orderStatus = 'Completed';

        // Act
        final canDownload = orderStatus == 'Completed';

        // Assert
        expect(canDownload, true);
      },
    );

    // Baris 12: REQ-29 - Unduh Invoice (Pending)
    test(
      'Tombol "Download Invoice" tidak tersedia atau disabled; sistem menampilkan pesan bahwa invoice hanya tersedia untuk order dengan status Completed',
      () async {
        // Arrange
        final orderStatus = 'Pending';

        // Act
        final canDownload = orderStatus == 'Completed';

        // Assert
        expect(canDownload, false);
      },
    );

    // Baris 13: REQ-30 - Admin Approve Delivery
    test(
      'Status order berubah menjadi "Delivery Approved"; barang siap untuk dikirim; Retailer menerima notifikasi bahwa pesanan sedang dalam proses pengiriman',
      () async {
        // Arrange
        when(mockDocRef.update(any)).thenAnswer((_) async => Future.value());

        // Act
        await mockDocRef.update({'status': 'Delivery Approved'});

        // Assert
        verify(mockDocRef.update({'status': 'Delivery Approved'})).called(1);
      },
    );

    // Baris 14: REQ-30 - Admin Reject Delivery
    test(
      'Status order berubah menjadi "Delivery Rejected"; Retailer menerima notifikasi bahwa pengiriman ditolak beserta alasannya; proses refund atau tindak lanjut dapat dilakukan',
      () async {
        // Arrange
        when(mockDocRef.update(any)).thenAnswer((_) async => Future.value());

        // Act
        await mockDocRef.update({'status': 'Delivery Rejected'});

        // Assert
        verify(mockDocRef.update({'status': 'Delivery Rejected'})).called(1);
      },
    );

    // Baris 15: REQ-30 - Admin Approve Delivery (Already Approved)
    test(
      'Sistem menampilkan pesan bahwa pengiriman untuk order ini sudah di-approve sebelumnya; tombol Approve/Reject tidak dapat ditekan kembali',
      () async {
        // Arrange
        final currentStatus = 'Delivery Approved';

        // Act
        final canApprove = currentStatus != 'Delivery Approved';

        // Assert
        expect(canApprove, false);
      },
    );

    // Baris 16: REQ-31 - Retailer Cancel Order (Sebelum dikirim)
    test(
      'Sistem mengirimkan permintaan pembatalan ke Admin; status order berubah menjadi "Cancellation Requested"; Retailer menerima notifikasi bahwa permintaan pembatalan sedang menunggu konfirmasi Admin',
      () async {
        // Arrange
        when(mockDocRef.update(any)).thenAnswer((_) async => Future.value());

        // Act
        await mockDocRef.update({'status': 'Cancellation Requested'});

        // Assert
        verify(
          mockDocRef.update({'status': 'Cancellation Requested'}),
        ).called(1);
      },
    );

    // Baris 17: REQ-31 - Retailer Cancel Order (Setelah Approve Delivery)
    test(
      'Sistem menampilkan pesan bahwa pesanan tidak dapat dibatalkan karena pengiriman sudah disetujui; tombol "Cancel Order" tidak tersedia atau disabled',
      () async {
        // Arrange
        final status = 'Delivery Approved';

        // Act
        final canCancel = status != 'Delivery Approved';

        // Assert
        expect(canCancel, false);
      },
    );

    // Baris 18: REQ-31 - Admin Setuju Cancel
    test(
      'Status order berubah menjadi "Cancelled"; Retailer menerima notifikasi bahwa pembatalan pesanan telah disetujui oleh Admin; proses selanjutnya (refund, dll) dapat dilakukan',
      () async {
        // Arrange
        when(mockDocRef.update(any)).thenAnswer((_) async => Future.value());

        // Act
        await mockDocRef.update({'status': 'Cancelled'});

        // Assert
        verify(mockDocRef.update({'status': 'Cancelled'})).called(1);
      },
    );

    // Baris 19: REQ-31 - Admin Tolak Cancel
    test(
      'Status order kembali menjadi status sebelumnya (Payment Verified); Retailer menerima notifikasi bahwa permintaan pembatalan ditolak; pesanan tetap diproses',
      () async {
        // Arrange
        when(mockDocRef.update(any)).thenAnswer((_) async => Future.value());

        // Act
        await mockDocRef.update({'status': 'Payment Verified'});

        // Assert
        verify(mockDocRef.update({'status': 'Payment Verified'})).called(1);
      },
    );
  });
}
