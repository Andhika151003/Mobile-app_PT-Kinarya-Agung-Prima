import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controllers/order_cs_controller.dart';
import '../models/order.dart';
import '../../shared/services/pdf_service.dart';

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

  // Status step index
  static const _statusSteps = ['Ordered', 'Paid', 'Shipped', 'Delivered'];

  bool _isUpdating = false;
  final OrderCsController _controller = OrderCsController();

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  int get _currentStep {
    if (_order.status == 'Cancelled') return -1;
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
    if (t == null) return 'Pending';
    return '${_monthAbbr(t.month)} ${t.day}\n${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  String _monthAbbr(int m) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return months[m];
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Ordered': return const Color(0xFFD97706);
      case 'Processing': return const Color(0xFF2563EB);
      case 'Shipped': return const Color(0xFF7C3AED);
      case 'Delivered': return const Color(0xFF16A34A);
      case 'Cancelled': return const Color(0xFFDC2626);
      default: return Colors.grey;
    }
  }

  Color _statusBgColor(String status) {
    switch (status) {
      case 'Ordered': return const Color(0xFFFEF7E0);
      case 'Paid': return const Color(0xFFE8EAF6);
      case 'Shipped': return const Color(0xFFF5F3FF);
      case 'Delivered': return const Color(0xFFE6F4EA);
      case 'Cancelled': return const Color(0xFFFCE8E6);
      default: return Colors.grey.shade100;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'Ordered': return 'Ordered';
      case 'Paid': return 'Paid';
      case 'Delivered': return 'Delivered';
      case 'Cancelled': return 'Cancelled';
      default: return status;
    }
  }

  Future<void> _fetchOrder() async {
    final updated = await _controller.getOrderById(_order.orderId);
    if (updated != null && mounted) {
      setState(() {
        _order = updated;
      });
    }
  }

  Future<void> _updateStatus() async {
    final currentStatus = _order.status;
    String newStatus = '';
    String actionLabel = '';

    if (currentStatus == 'Ordered') {
      newStatus = 'Paid'; actionLabel = 'Tandai sudah dibayar (Paid)';
    } else if (currentStatus == 'Paid') {
      newStatus = 'Shipped'; actionLabel = 'Kirim Pesanan (Shipped)';
    } else if (currentStatus == 'Shipped') {
      newStatus = 'Delivered'; actionLabel = 'Pesanan Selesai (Delivered)';
    } else {
      return; 
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Update Status Pesanan?'),
        content: Text('Melanjutkan pesanan ke tahap: $actionLabel?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), elevation: 0),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Konfirmasi', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isUpdating = true);
    try {
      await _controller.updateOrderStatus(_order.orderId, newStatus);
      await _fetchOrder();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal update: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _cancelOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Batalkan Pesanan?'),
        content: const Text('Tindakan ini akan mengembalikan stok produk dan membatalkan pesanan secara permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Tutup', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, elevation: 0),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Batalkan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isUpdating = true);
    try {
      await _controller.cancelOrder(_order.orderId);
      await _fetchOrder();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pesanan berhasil dibatalkan dan stok dikembalikan'), backgroundColor: Colors.orange));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal pembatalan: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Order Details',
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
          IconButton(
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
            if (_order.status != 'Delivered' && _order.status != 'Cancelled' && _order.status != 'Expired')
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isUpdating ? null : _updateStatus,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0
                        ),
                        child: _isUpdating 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Update Status', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _isUpdating ? null : _cancelOrder,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Batalkan Pesanan', style: TextStyle(color: Colors.red, fontSize: 15, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            _buildShippingInfo(),
            const SizedBox(height: 16),
            _buildOrderItems(),
            const SizedBox(height: 16),
            _buildPaymentInfo(),
            const SizedBox(height: 16),
            _buildDownloadInvoiceButton(),
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: _statusBgColor(_order.status),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_order.status == 'Delivered')
                      const Icon(Icons.check_circle,
                          size: 13, color: Color(0xFF16A34A)),
                    if (_order.status == 'Ordered')
                      const Icon(Icons.access_time,
                          size: 13, color: Color(0xFFD97706)),
                    if (_order.status == 'Processing')
                      const Icon(Icons.access_time,
                          size: 13, color: Color(0xFF2563EB)),
                    if (_order.status == 'Cancelled')
                      const Icon(Icons.cancel,
                          size: 13, color: Color(0xFFDC2626)),
                    const SizedBox(width: 4),
                    Text(
                      _statusLabel(_order.status),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                        color: _order.status == 'Cancelled' ? Colors.red : ( _order.status == 'Delivered' ? const Color(0xFF1E8E3E) : const Color(0xFFF9AB00)),
                      ),
                    ),
                  ],
                ),
              ),
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
                    const Text('Total Amount',
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
                    const Text('Payment Status',
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
                          _order.paidAt != null ? 'Paid' : 'Pending',
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
            'Order Status',
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
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFFE5E7EB),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isDone ? Icons.check : (i == _currentStep + 1 && _order.status != 'Cancelled' ? Icons.access_time : Icons.circle),
                              color: isDone
                                  ? Colors.white
                                  : const Color(0xFFD1D5DB),
                              size: isDone ? 16 : 10,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _statusSteps[i],
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
            'Shipping Information',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Shipping Address',
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
            'Order Items',
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
          const SizedBox(height: 4),
          _summaryRow(
              'Pajak (11%)', currencyFormatter.format(_order.tax)),
          const SizedBox(height: 4),
          _summaryRow('Shipping', currencyFormatter.format(_order.shippingCost)),
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

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: Color(0xFF6B7280), fontFamily: 'Inter')),
        Text(value,
            style:
                const TextStyle(fontSize: 13, fontFamily: 'Inter')),
      ],
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
            'Payment Information',
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
                    const Text('Payment Method',
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
                    const Text('Transaction ID',
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
                    const Text('Payment Date',
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
                    const Text('Invoice ID',
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
        onPressed: () {
          PdfService.generateAndOpenInvoice(_order);
        },
        icon: const Icon(Icons.download_outlined,
            color: Color(0xFF374151), size: 18),
        label: const Text(
          'Download Invoice',
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
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '${months[date.month]} ${date.day}, ${date.year} • $h:$m AM';
  }

  String _formatDate(DateTime date) {
    final months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month]} ${date.day}, ${date.year}';
  }
}