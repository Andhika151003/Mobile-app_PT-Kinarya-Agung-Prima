import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import '../../order/controllers/order_stats_helper.dart';

class PaymentWebView extends StatefulWidget {
  final String paymentUrl;
  final String orderId;

  const PaymentWebView({
    super.key,
    required this.paymentUrl,
    required this.orderId,
  });

  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isUpdating = false; 
  bool _hasError = false; 
  String _errorMsg = '';
  int _errorCode = 0;
  StreamSubscription<DocumentSnapshot>? _statusSubscription;

  static const String _merchantReturnUrl = 'https://backend-payment-kinarya.vercel.app';

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (url) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            debugPrint('❌ WebView Error: [${error.errorCode}] ${error.description}');
            
            // Filter non-fatal errors
            // -10: ERR_UNKNOWN_URL_SCHEME (Handled in onNavigationRequest or sub-resource)
            // -1: Generic error / Connection closed
            // -6: Connection refused (often transient during gateway handshake)
            // -8: Connection timed out (transient)
            // -3: ERR_ABORTED (often happens when navigation is cancelled or interrupted)
            final nonFatalCodes = [-10, -1, -6, -8, -3, 102];
            if (nonFatalCodes.contains(error.errorCode)) {
              debugPrint('ℹ️ Ignoring non-fatal error: ${error.errorCode}');
              return;
            }

            if (mounted) {
              setState(() {
                _isLoading = false;
                _hasError = true;
                _errorCode = error.errorCode;
                _errorMsg = error.description;
              });
            }
          },
          onNavigationRequest: (request) async {
            final url = request.url;
            debugPrint('🧭 Navigation Request: $url');

            // Handle Merchant Return URL
            if (url.startsWith(_merchantReturnUrl) && !_isUpdating) {
              _onPaymentFinished();
              return NavigationDecision.prevent;
            }

            // Handle Deep Links (E-wallets, Banking Apps, WhatsApp)
            if (!url.startsWith('http://') && !url.startsWith('https://')) {
              debugPrint('🔗 Deep Link Detected: $url');
              
              if (mounted) setState(() => _isLoading = false);

              try {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                  return NavigationDecision.prevent;
                }
              } catch (e) {
                debugPrint('❌ Failed to parse/launch URI: $e');
                
                // Special handling for Android Intent strings if Uri.parse fails
                if (url.startsWith('intent://')) {
                  try {
                    // Fallback to external application launch for intent schemes
                    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                    return NavigationDecision.prevent;
                  } catch (e2) {
                    debugPrint('❌ Intent fallback failed: $e2');
                  }
                }
              }
              // Prevent WebView from trying to load it and showing an error
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));

    _statusSubscription = FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final status = data['status'];
        
        if (status == 'Paid' && !_isUpdating) {
          debugPrint('Order ${widget.orderId} status detected as PAID in real-time');
          _onPaymentFinished(alreadyUpdated: true);
        }
      }
    });
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    super.dispose();
  }

  Future<void> _onPaymentFinished({bool alreadyUpdated = false}) async {
    if (_isUpdating) return;
    if (mounted) setState(() => _isUpdating = true);

    try {
      if (!alreadyUpdated) {
        await OrderStatsHelper.markOrderAsPaid(widget.orderId);
        debugPrint('Order ${widget.orderId} updated via Duitku Redirect');
      }
    } catch (e) {
      debugPrint('Gagal update Firestore: $e');
    }

    if (mounted) {
      Navigator.pop(context, true); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: _showCancelDialog,
        ),
        title: const Text(
          'Pembayaran Duitku',
          style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          _hasError 
            ? _buildErrorPlaceholder()
            : WebViewWidget(controller: _controller),

          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF458833)),
            ),

          if (_isUpdating)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                    SizedBox(height: 16),
                    Text('Mengonfirmasi pembayaran...', style: TextStyle(color: Colors.white, fontSize: 14)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Gagal Memuat Halaman Pembayaran',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Link pembayaran mungkin telah kadaluwarsa atau terjadi masalah koneksi.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (_errorCode != 0)
              Text(
                'Error: [$_errorCode] $_errorMsg',
                style: TextStyle(color: Colors.red[300], fontSize: 12, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _isLoading = true;
                  });
                  _controller.loadRequest(Uri.parse(widget.paymentUrl));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF458833),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kembali ke Pesanan', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Batalkan Pembayaran?'),
        content: const Text('Apakah Anda yakin ingin membatalkan? Pesanan tetap tersimpan, Anda bisa bayar nanti melalui halaman Orders.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Lanjutkan Bayar', style: TextStyle(color: Color(0xFF458833))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, false); 
            },
            child: const Text('Keluar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}