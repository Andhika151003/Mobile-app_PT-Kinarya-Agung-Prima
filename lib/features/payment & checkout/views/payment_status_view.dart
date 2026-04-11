import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PaymentStatusView extends StatefulWidget {
  final String orderId;

  const PaymentStatusView({super.key, required this.orderId});

  @override
  State<PaymentStatusView> createState() => _PaymentStatusViewState();
}

class _PaymentStatusViewState extends State<PaymentStatusView> {
  static const _green = Color(0xFF4A7D3C);

  Map<String, dynamic>? _order;
  bool _isLoading = true;
  bool _isChecking = false;
  String? _syncMessage;

  @override
  void initState() {
    super.initState();
    _fetchOrder();
  }

  Future<void> _fetchOrder() async {
    setState(() {
      _isChecking = true;
      _syncMessage = null;
    });
    try {
      final doc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _order = data;
          _isLoading = false;
        });

        final status = data['status'] as String? ?? 'Ordered';
        if (status == 'Ordered' || status == 'Pending Payment') {
          await _syncFromDuitku();
        } else {
          setState(() => _isChecking = false);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _syncFromDuitku() async {
    try {
      final response = await http.post(
        Uri.parse(
            'https://backend-payment-kinarya.vercel.app/check-status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'orderId': widget.orderId}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final duitkuStatus = body['statusCode'] as String?;

        if (duitkuStatus == '00') {
          await FirebaseFirestore.instance
              .collection('orders')
              .doc(widget.orderId)
              .update({
            'status': 'Paid',
            'paidAt': FieldValue.serverTimestamp(),
          });

          final doc = await FirebaseFirestore.instance
              .collection('orders')
              .doc(widget.orderId)
              .get();
          if (mounted && doc.exists) {
            setState(() {
              _order = doc.data();
              _syncMessage = '✅ Status diperbarui dari Duitku';
            });
          }
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  String get _normalizedStatus {
    String raw = _order?['status'] as String? ?? 'Ordered';
    if (raw == 'Pending Payment') return 'Ordered';
    if (raw == 'Settled') return 'Delivered';
    return raw;
  }

  double _progressValue(String status) {
    switch (status) {
      case 'Paid':
      case 'Shipped':
      case 'Delivered':
        return 1.0; 
      case 'Ordered':
        return 0.4;
      case 'Expired':
      case 'Cancelled':
        return 0.0;
      default:
        return 0.3;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Paid':
      case 'Shipped':
      case 'Delivered':
        return _green;
      case 'Expired':
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'Paid':
      case 'Shipped':
      case 'Delivered':
        return 'Payment Successful';
      case 'Expired':
      case 'Cancelled':
        return 'Payment Expired';
      default:
        return 'Payment Processing';
    }
  }

  String _statusSubtitle(String status) {
    switch (status) {
      case 'Paid':
      case 'Shipped':
      case 'Delivered':
        return 'Your payment has been confirmed.';
      case 'Expired':
      case 'Cancelled':
        return 'This transaction has expired/cancelled.';
      default:
        return 'Your payment is being verified. Please wait.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final status = _normalizedStatus;
    final total = (_order?['total'] as num?)?.toDouble() ?? 0.0;
    final paymentMethod = _order?['paymentMethod'] as String? ?? '-';
    final Timestamp? createdAt = _order?['createdAt'] as Timestamp?;
    final DateTime? date =
        createdAt != null ? createdAt.toDate().toLocal() : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: _green),
              )
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 32),
                      child: Column(
                        children: [
                          _Card(
                            child: Column(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: _statusColor(status).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    status == 'Paid' || status == 'Shipped' || status == 'Delivered'
                                        ? Icons.check_circle_outline_rounded
                                        : status == 'Expired' || status == 'Cancelled'
                                            ? Icons.cancel_outlined
                                            : Icons.history_rounded,
                                    color: _statusColor(status),
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  _statusLabel(status),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _statusSubtitle(status),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: _progressValue(status),
                                    minHeight: 8,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      _statusColor(status),
                                    ),
                                  ),
                                ),
                                if (_syncMessage != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Text(
                                      _syncMessage!,
                                      style: TextStyle(fontSize: 12, color: _green, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          _Card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Transaction Details',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _DetailRow(
                                  label: 'Transaction ID',
                                  value: '#${widget.orderId.substring(0, 12).toUpperCase()}',
                                ),
                                _DetailRow(
                                  label: 'Amount',
                                  value: currencyFmt.format(total),
                                ),
                                _DetailRow(
                                  label: 'Date',
                                  value: date != null
                                      ? DateFormat('MMM dd, yyyy').format(date)
                                      : '-',
                                ),
                                _DetailRow(
                                  label: 'Time',
                                  value: date != null
                                      ? DateFormat('hh:mm a').format(date)
                                      : '-',
                                  isLast: true,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          _Card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Payment Method',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.grey.shade200),
                                      ),
                                      child: Icon(
                                        _paymentIcon(paymentMethod),
                                        color: _green,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          paymentMethod,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          'Order via Kinarya App',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Column(
                      children: [
                        if (status == 'Ordered')
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isChecking ? null : _fetchOrder,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _green,
                                  disabledBackgroundColor: Colors.grey.shade400,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isChecking
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Check Status Again',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).popUntil((route) => route.isFirst);
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              side: const BorderSide(color: Color(0xFFD0D0D0)),
                            ),
                            child: const Text(
                              'Back to Home',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  IconData _paymentIcon(String method) {
    final m = method.toLowerCase();
    if (m.contains('va') || m.contains('virtual')) return Icons.account_balance;
    if (m.contains('credit') || m.contains('card')) return Icons.credit_card;
    if (m.contains('qris') || m.contains('qr')) return Icons.qr_code;
    if (m.contains('ovo') || m.contains('dana') || m.contains('gopay')) {
      return Icons.wallet;
    }
    return Icons.payment;
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: Colors.grey.shade100),
      ],
    );
  }
}