import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../controllers/order_user_controller.dart';
import '../../payment & checkout/views/payment_status_view.dart';
import '../../payment & checkout/views/payment_webview.dart';

class OrderDetailUserView extends StatefulWidget {
  final String orderId;
  const OrderDetailUserView({super.key, required this.orderId});

  @override
  State<OrderDetailUserView> createState() => _OrderDetailUserViewState();
}

class _OrderDetailUserViewState extends State<OrderDetailUserView> {
  static const _primaryColor = Color(0xFF4A7D3C); 
  static const _bgColor = Color(0xFFF7F8FA);

  final OrderUserController _userController = OrderUserController();
  
  OrderModel? _order; 
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrder();
  }

  Future<void> _fetchOrder() async {
    try {
      final data = await _userController.getOrderById(widget.orderId);
      if (data != null && mounted) {
        setState(() {
          _order = OrderModel.fromMap(data);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String get _shortId {
    final digits = widget.orderId.replaceAll(RegExp(r'[^0-9]'), '');
    final suffix = digits.length >= 4 ? digits.substring(digits.length - 4) : digits;
    return '#ORD-$suffix';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _order == null) {
      return const Scaffold(
        backgroundColor: _bgColor,
        body: Center(child: CircularProgressIndicator(color: _primaryColor)),
      );
    }

    final order = _order!;
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    final txnId = order.orderId.replaceAll(RegExp(r'[^0-9]'), '');
    final invoiceNo = 'INV-${order.createdAt != null ? DateFormat('yyyy').format(order.createdAt!) : '2026'}-${txnId.isNotEmpty && txnId.length >= 4 ? txnId.substring(0, 4) : '0000'}';

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300)),
            child: const Icon(Icons.arrow_back_ios_new, size: 14, color: Colors.black87),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Order Details',
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300)),
              child: const Icon(Icons.print_outlined, size: 16, color: Colors.black87),
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Card
            _buildHeaderCard(_shortId, order.createdAt, order.total, order.status, currency),
            const SizedBox(height: 20),

            // 2. Order Status Stepper
            const Text('Order Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 12),
            _buildStatusStepper(order.status, order),
            
            _buildUserActionButtons(order.status, context),

            const SizedBox(height: 24),

            // 3. Shipping Information
            const Text('Shipping Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Shipping Address', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  const SizedBox(height: 8),
                  Text(order.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black)),
                  const SizedBox(height: 4),
                  Text(
                    order.shippingAddress, 
                    style: TextStyle(
                      fontSize: 13, height: 1.4, 
                      color: order.shippingAddress.contains('tidak tersedia') ? Colors.red : Colors.black87,
                      fontStyle: order.shippingAddress.contains('tidak tersedia') ? FontStyle.italic : FontStyle.normal,
                    )
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. Order Items & Summary
            const Text('Order Items', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
              child: Column(
                children: [
                  ...order.items.map((item) => _buildItemRow(item, currency)),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildSummaryRow('Subtotal', currency.format(order.subtotal)),
                        const SizedBox(height: 8),
                        _buildSummaryRow('Tax (11%)', currency.format(order.tax)),
                        const SizedBox(height: 8),
                        _buildSummaryRow('Shipping', order.shippingCost == 0 ? 'Free' : currency.format(order.shippingCost)),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                            Text(currency.format(order.total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 5. Payment Information
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Payment Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PaymentStatusView(orderId: widget.orderId)),
                  ),
                  child: const Text('View Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _primaryColor)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildPaymentInfoCard(order.paymentMethod, order.createdAt, txnId, invoiceNo),
          ],
        ),
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  HELPER WIDGETS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Widget _buildHeaderCard(String orderId, DateTime? date, double total, String status, NumberFormat currency) {
    bool isDelivered = status == 'Delivered';
    bool isPaid = status != 'Ordered' && status != 'Expired';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(orderId, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDelivered ? const Color(0xFFE6F4EA) : const Color(0xFFFEF7E0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(isDelivered ? Icons.check : Icons.access_time, size: 12, color: isDelivered ? const Color(0xFF1E8E3E) : const Color(0xFFF9AB00)),
                    const SizedBox(width: 4),
                    Text(isDelivered ? 'Delivered' : status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDelivered ? const Color(0xFF1E8E3E) : const Color(0xFFF9AB00))),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 4),
          Text(date != null ? DateFormat('MMMM dd, yyyy • hh:mm a').format(date) : '-', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
          
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Amount', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    const SizedBox(height: 4),
                    Text(currency.format(total), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Payment Status', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: isPaid ? _primaryColor : Colors.orange, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text(isPaid ? 'Paid' : 'Unpaid', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatusStepper(String currentStatus, OrderModel order) {
    final steps = ['Ordered', 'Paid', 'Shipped', 'Delivered'];
    int currentIndex = steps.indexOf(currentStatus);
    if (currentIndex == -1) currentIndex = 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(steps.length, (index) {
        bool isCompleted = index <= currentIndex;
        
        DateTime? stepDate;
        if (index == 0) stepDate = order.createdAt;
        else if (index == 1) stepDate = order.paidAt;
        else if (index == 2) stepDate = order.shippedAt;
        else if (index == 3) stepDate = order.deliveredAt;

        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: Container(height: 3, color: index == 0 ? Colors.transparent : (isCompleted ? _primaryColor : Colors.grey.shade300))),
                  Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      color: isCompleted ? _primaryColor : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: isCompleted ? _primaryColor : Colors.grey.shade300),
                    ),
                    child: Icon(Icons.check, size: 14, color: isCompleted ? Colors.white : Colors.grey.shade300),
                  ),
                  Expanded(child: Container(height: 3, color: index == steps.length - 1 ? Colors.transparent : (isCompleted && index < currentIndex ? _primaryColor : Colors.grey.shade300))),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                steps[index],
                style: TextStyle(fontSize: 12, fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal, color: isCompleted ? Colors.black : Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
              if (stepDate != null)
                Text(
                  DateFormat('MMM dd, HH:mm').format(stepDate),
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildUserActionButtons(String status, BuildContext context) {
    if (status == 'Ordered') {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              final paymentUrl = _order?.paymentUrl; 

              if (paymentUrl != null && paymentUrl.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentWebView( 
                      paymentUrl: paymentUrl, 
                      orderId: widget.orderId,
                    ),
                  ),
                ).then((_) => _fetchOrder());
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Link pembayaran tidak ditemukan.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: const Text('Lanjutkan Pembayaran', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ),
      );
    } else if (status == 'Paid' || status == 'Shipped') {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {}, 
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              side: BorderSide(color: Colors.red.shade200),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Ajukan Refund / Pembatalan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildItemRow(OrderItemModel item, NumberFormat currency) {
    final sku = 'SKU: PRD-${item.title.hashCode.abs().toString().substring(0, 4)}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                  ? Image.network(item.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image_outlined, color: Colors.grey))
                  : const Icon(Icons.image_outlined, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
                const SizedBox(height: 4),
                Text(sku, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                Text('${currency.format(item.price)} per unit', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(currency.format(item.price * item.quantity), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 8),
              Text('Qty: ${item.quantity}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        Text(value, style: const TextStyle(fontSize: 13, color: Colors.black87)),
      ],
    );
  }

  Widget _buildPaymentInfoCard(String paymentMethod, DateTime? date, String transactionId, String invoiceNo) {
    String txnDisplay = transactionId.isEmpty ? '0000' : transactionId;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Payment Method', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.credit_card, size: 16, color: Colors.black54),
                        const SizedBox(width: 6),
                        Flexible(child: Text(paymentMethod, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Transaction ID', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    const SizedBox(height: 4),
                    Text('TXN-$txnDisplay', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Payment Date', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    const SizedBox(height: 4),
                    Text(date != null ? DateFormat('MMMM dd, yyyy').format(date) : '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Invoice Number', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    const SizedBox(height: 4),
                    Text(invoiceNo, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download_outlined, size: 18),
              label: const Text('Download Invoice', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade100,
                foregroundColor: Colors.black87,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}