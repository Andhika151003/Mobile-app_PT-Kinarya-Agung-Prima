import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controllers/order_cs_controller.dart';
import '../controllers/order_user_controller.dart';
import '../models/order.dart';
import '../../shared/services/pdf_service.dart';
import '../../../core/utils/status_helper.dart';

class OrderDetailCsView extends StatefulWidget {
  final OrderModel order;
  const OrderDetailCsView({super.key, required this.order});

  @override
  State<OrderDetailCsView> createState() => _OrderDetailCsViewState();
}

class _OrderDetailCsViewState extends State<OrderDetailCsView> {
  late OrderModel _order;

  final currencyFormatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  static const _statusSteps = ['Ordered', 'Paid', 'Shipped', 'Delivered'];

  final OrderCsController _controller = OrderCsController();

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _fetchOrder();
  }

  int get _currentStep {
    if (_order.status == 'Cancelled' || _order.status == 'Expired') {
      if (_order.deliveredAt != null) return 3;
      if (_order.shippedAt != null) return 2;
      if (_order.paidAt != null) return 1;
      return 0;
    }
    return _statusSteps.indexOf(_order.status);
  }

  DateTime? _getStepTime(String status) {
    switch (status) {
      case 'Ordered':
        return _order.createdAt;
      case 'Paid':
        return _order.paidAt;
      case 'Shipped':
        return _order.shippedAt;
      case 'Delivered':
        return _order.deliveredAt;
      default:
        return null;
    }
  }

  String _stepTimeLabel(String status) {
    final t = _getStepTime(status);
    if (t == null) return 'Menunggu';
    return '${_monthAbbr(t.month)} ${t.day}\n${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  String _monthAbbr(int m) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return months[m];
  }

  Future<void> _fetchOrder() async {
    try {
      final updated = await _controller.getOrderById(_order.orderId);
      if (updated != null && mounted) {
        
        if (updated.status == 'Ordered') {
          final userCtrl = OrderUserController();
          await userCtrl.syncDuitkuPayment(_order.orderId);
          
          final finalData = await _controller.getOrderById(_order.orderId);
          if (finalData != null && mounted) {
            setState(() {
              _order = finalData;
            });
            return;
          }
        }

        setState(() {
          _order = updated;
        });
      }
    } catch (e) {
      debugPrint("OrderDetailCsView Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Detail Pesanan',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_order.status == 'Delivered' ||
              _order.status == 'Cancelled' ||
              _order.status == 'Paid')
            IconButton(
              key: const Key('btn_print_invoice_header_cs'),
              icon: const Icon(Icons.print_outlined, color: Colors.black),
              onPressed: () {
                PdfService.generateAndOpenInvoice(_order);
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderInfoCard(),
            const SizedBox(height: 16),
            _buildOrderStatusTracker(),
            const SizedBox(height: 16),
            _buildShippingInfo(),
            const SizedBox(height: 16),
            _buildOrderItems(),
            const SizedBox(height: 16),
            _buildPaymentInfo(),
            if (_order.status == 'Delivered' ||
                _order.status == 'Cancelled' ||
                _order.status == 'Paid') ...[
              const SizedBox(height: 16),
              _buildDownloadInvoiceButton(),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ─── Order Info Card ─────────────────────────────────────────────
  Widget _buildOrderInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _order.orderId,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
              _buildStatusBadge(_order.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _formatFullDateTime(_order.createdAt ?? DateTime.now()),
            style: const TextStyle(
              fontSize: 12,
              fontFamily: 'Inter',
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Pembayaran',
                        style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                            fontFamily: 'Inter')),
                    const SizedBox(height: 2),
                    Text(
                      currencyFormatter.format(_order.total),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Status Pembayaran',
                        style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                            fontFamily: 'Inter')),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF16A34A),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _order.status == 'Cancelled' ? 'Dibatalkan' : (_order.status == 'Expired' ? 'Kedaluwarsa' : (_order.paidAt != null ? 'Lunas' : 'Belum bayar')),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Order Status Tracker ─────────────────────────────────────────
  Widget _buildOrderStatusTracker() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status Pesanan',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(_statusSteps.length, (i) {
              final isDone = _currentStep >= i;
              final isLast = i == _statusSteps.length - 1;
              final isCancelledOrExpired = _order.status == 'Cancelled' || _order.status == 'Expired';
              return Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          // Circle
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isDone
                                  ? (isCancelledOrExpired && i == _currentStep ? Colors.red : const Color(0xFF2E7D32))
                                  : const Color(0xFFE5E7EB),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isDone ? (isCancelledOrExpired && i == _currentStep ? Icons.close : Icons.check) : (i == _currentStep + 1 && !isCancelledOrExpired ? Icons.access_time : Icons.circle),
                              color: isDone
                                  ? Colors.white
                                  : const Color(0xFFD1D5DB),
                              size: isDone ? 16 : 10,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _statusSteps[i].displayStatus,
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                              color: isDone
                                  ? Colors.black
                                  : const Color(0xFF9CA3AF),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.visible,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _stepTimeLabel(_statusSteps[i]),
                            style: const TextStyle(
                              fontSize: 10,
                              fontFamily: 'Inter',
                              color: Color(0xFF9CA3AF),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.visible,
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Padding(
                        padding: const EdgeInsets.only(top: 13),
                        child: Container(
                          width: 16,
                          height: 2,
                          color: _currentStep > i
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ─── Shipping Info ────────────────────────────────────────────────
  Widget _buildShippingInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informasi Pengiriman',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Alamat Pengiriman',
            style: TextStyle(
                fontSize: 12, color: Color(0xFF6B7280), fontFamily: 'Inter'),
          ),
          const SizedBox(height: 4),
          Text(
            _order.fullName,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
            ),
          ),
          Text(
            _order.shippingAddress,
            style: const TextStyle(
                fontSize: 13, fontFamily: 'Inter', color: Color(0xFF374151)),
          ),
          if (_order.phoneNumber != null && _order.phoneNumber!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 14, color: Color(0xFF6B7280)),
                const SizedBox(width: 6),
                Text(
                  _order.phoneNumber!,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563), fontFamily: 'Inter'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─── Order Items ──────────────────────────────────────────────────
  Widget _buildOrderItems() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Produk Pesanan',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(_order.items.length, (i) {
            final item = _order.items[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  // Product image
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(item.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.image,
                                        color: Color(0xFF9CA3AF))),
                          )
                        : const Icon(Icons.image, color: Color(0xFF9CA3AF)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${currencyFormatter.format(item.price)} per unit',
                          style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                              fontFamily: 'Inter'),
                        ),
                        Text(
                          'Qty: ${item.quantity}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                              fontFamily: 'Inter'),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    currencyFormatter.format(item.price * item.quantity),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            );
          }),
          const Divider(color: Color(0xFFF3F4F6)),
          const SizedBox(height: 8),
          _summaryRow('Subtotal', currencyFormatter.format(_order.subtotal)),
          if (_order.discountAmount > 0) ...[
            const SizedBox(height: 4),
            _summaryRow(
              'Diskon', 
              '-${currencyFormatter.format(_order.discountAmount)}',
              valueColor: Colors.red.shade600,
            ),
          ],
          const SizedBox(height: 4),
          _summaryRow(
              'Pajak (11%)', currencyFormatter.format(_order.tax)),
          const SizedBox(height: 4),
          _summaryRow('Pengiriman', currencyFormatter.format(_order.shippingCost)),
          const Divider(color: Color(0xFFE5E7EB), height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter'),
              ),
              Text(
                currencyFormatter.format(_order.total),
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter',
                    color: Color(0xFF2E7D32)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: Color(0xFF6B7280), fontFamily: 'Inter')),
        Text(value,
            style:
                TextStyle(fontSize: 13, fontFamily: 'Inter', color: valueColor ?? Colors.black)),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg; Color fg; IconData icon; String label = status.displayStatus;

    if (status == 'Delivered') {
      bg = const Color(0xFFE6F4EA); fg = const Color(0xFF1E8E3E); icon = Icons.check_circle_outline;
    } else if (status == 'Cancelled') {
      bg = const Color(0xFFFCE8E6); fg = const Color(0xFFD93025); icon = Icons.cancel_outlined;
    } else if (status == 'Expired') {
      bg = const Color(0xFFFCE8E6); fg = const Color(0xFFD93025); icon = Icons.timer_off_outlined;
    } else if (status == 'Ordered') {
      bg = const Color(0xFFFEF7E0); fg = const Color(0xFFF9AB00); icon = Icons.access_time;
    } else if (status == 'Shipped') {
      bg = const Color(0xFFE3F2FD); fg = const Color(0xFF1976D2); icon = Icons.local_shipping_outlined;
    } else if (status == 'Paid') {
      bg = const Color(0xFFE8EAF6); fg = const Color(0xFF3949AB); icon = Icons.payment;
    } else {
      bg = const Color(0xFFE8EAF6); fg = const Color(0xFF3949AB); icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
        ],
      ),
    );
  }

  // ─── Payment Info ─────────────────────────────────────────────────
  Widget _buildPaymentInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informasi Pembayaran',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Metode Pembayaran',
                        style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7280),
                            fontFamily: 'Inter')),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.credit_card,
                            size: 16, color: Color(0xFF374151)),
                        const SizedBox(width: 6),
                        Text(
                          _order.paymentMethod,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Inter'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ID Transaksi',
                        style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7280),
                            fontFamily: 'Inter')),
                    const SizedBox(height: 4),
                    Text(
                      'TXN-${_order.orderId.replaceAll(RegExp(r'[^0-9]'), '')}',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Inter'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tanggal Pembayaran',
                        style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7280),
                            fontFamily: 'Inter')),
                    const SizedBox(height: 4),
                    Text(
                      _order.paidAt != null
                          ? _formatDate(_order.paidAt!)
                          : '-',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Inter'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ID Invoice',
                        style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7280),
                            fontFamily: 'Inter')),
                    const SizedBox(height: 4),
                    Text(
                      'KNY-${_order.orderId.replaceAll(RegExp(r'[^0-9]'), '')}',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Inter'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Download Invoice Button ──────────────────────────────────────
  Widget _buildDownloadInvoiceButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        key: const Key('btn_download_invoice_cs'),
        onPressed: () {
          PdfService.generateAndOpenInvoice(_order);
        },
        icon: const Icon(Icons.download_outlined,
            color: Color(0xFF374151), size: 18),
        label: const Text(
          'Unduh Invoice',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
            fontSize: 14,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: Color(0xFFE5E7EB)),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          backgroundColor: Colors.white,
        ),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────
  String _formatFullDateTime(DateTime date) {
    final months = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '${months[date.month]} ${date.day}, ${date.year} • $h:$m WIB';
  }

  String _formatDate(DateTime date) {
    final months = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${months[date.month]} ${date.day}, ${date.year}';
  }
}