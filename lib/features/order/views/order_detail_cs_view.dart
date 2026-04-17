import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controllers/order_cs_controller.dart';
import '../models/order.dart';

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
  static const _statusSteps = ['Ordered', 'Processing', 'Shipped', 'Delivered'];

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
      case 'Processing':
        return _order.createdAt != null
            ? _order.createdAt!.add(const Duration(hours: 2))
            : null;
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
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
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
      case 'Ordered': return const Color(0xFFFEF3C7);
      case 'Processing': return const Color(0xFFEFF6FF);
      case 'Shipped': return const Color(0xFFF5F3FF);
      case 'Delivered': return const Color(0xFFDCFCE7);
      case 'Cancelled': return const Color(0xFFFEE2E2);
      default: return Colors.grey.shade100;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'Ordered': return 'Pending';
      case 'Processing': return 'Process';
      case 'Delivered': return 'Delivered';
      case 'Cancelled': return 'Cancelled';
      default: return status;
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
            onPressed: () {},
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
                '#${_order.orderId}',
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
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                        color: _statusColor(_order.status),
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
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Order Type',
                        style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                            fontFamily: 'Inter')),
                    SizedBox(height: 2),
                    Text('Wholesale',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter')),
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
                              isDone ? Icons.check : Icons.circle,
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
              'Tax (1.5%)', currencyFormatter.format(_order.tax)),
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
                      _order.paymentMethodCode ?? '-',
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
                    const Text('Invoice Number',
                        style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7280),
                            fontFamily: 'Inter')),
                    const SizedBox(height: 4),
                    Text(
                      'INV-${DateTime.now().year}-${_order.orderId.replaceAll(RegExp(r'[^0-9]'), '')}',
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Download invoice sedang diproses...'),
              backgroundColor: Color(0xFF2E7D32),
            ),
          );
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