import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../controllers/order_user_controller.dart';
import '../../payment & checkout/views/payment_status_view.dart';
import '../../payment & checkout/views/payment_webview.dart';
import '../../shared/services/pdf_service.dart';
import '../../../core/utils/status_helper.dart';

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
        final order = OrderModel.fromMap(data);
        
        if (order.status == 'Ordered') {
          await _userController.syncDuitkuPayment(widget.orderId);
          final updatedData = await _userController.getOrderById(widget.orderId);
          if (updatedData != null && mounted) {
            setState(() {
              _order = OrderModel.fromMap(updatedData);
              _isLoading = false;
            });
            return;
          }
        }

        setState(() {
          _order = order;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
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

    final txnDigits = order.orderId.replaceAll(RegExp(r'[^0-9]'), '');
    final invoiceId = 'KNY-${txnDigits.isNotEmpty ? txnDigits : '0000'}';
    final transactionId = 'TXN-${txnDigits.isNotEmpty ? txnDigits : '0000'}';

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
          'Detail Pesanan',
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_order != null &&
              (_order!.status == 'Delivered' ||
                  _order!.status == 'Cancelled' ||
                  _order!.status == 'Paid'))
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300)),
                child: const Icon(Icons.print_outlined,
                    size: 16, color: Colors.black87),
              ),
              onPressed: () {
                PdfService.generateAndOpenInvoice(_order!);
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Card
            _buildHeaderCard(order.orderId, order.createdAt, order.total, order.status, currency),
            const SizedBox(height: 20),

            // 2. Order Status Stepper
            const Text('Status Pesanan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 12),
            _buildStatusStepper(order),
            
            _buildUserActionButtons(order.status, context),

            const SizedBox(height: 24),

            // 3. Shipping Information
            const Text('Informasi Pengiriman', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Alamat Pengiriman', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
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
                  if (order.phoneNumber != null && order.phoneNumber!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.phone_outlined, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 6),
                        Text(
                          order.phoneNumber!,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. Order Items & Summary
            const Text('Produk Pesanan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
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
                        if (order.discountAmount > 0) ...[
                          const SizedBox(height: 8),
                          _buildSummaryRow(
                            'Diskon', 
                            '-${currency.format(order.discountAmount)}',
                            valueColor: Colors.red.shade600,
                          ),
                        ],
                        const SizedBox(height: 8),
                        _buildSummaryRow('Pajak (11%)', currency.format(order.tax)),
                        const SizedBox(height: 8),
                        _buildSummaryRow('Pengiriman', order.shippingCost == 0 ? 'Gratis' : currency.format(order.shippingCost)),
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
                const Text('Informasi Pembayaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PaymentStatusView(orderId: widget.orderId)),
                  ),
                  child: const Text('Lihat Detail', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _primaryColor)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildPaymentInfoCard(order.paymentMethod, order.createdAt, transactionId, invoiceId),
            if (order.status == 'Shipped') ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  key: const Key('btn_confirm_received'),
                  onPressed: () async {
                    setState(() => _isLoading = true);
                    final success = await _userController.receiveOrder(order.orderId);
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Pesanan berhasil diterima!'), backgroundColor: _primaryColor),
                      );
                      await _fetchOrder();
                    } else if (context.mounted) {
                      setState(() => _isLoading = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Gagal memperbarui status.'), backgroundColor: Colors.red),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Pesanan Diterima', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  HELPER WIDGETS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Widget _buildHeaderCard(String orderId, DateTime? date, double total, String status, NumberFormat currency) {
    bool isCancelledOrExpired = status == 'Cancelled' || status == 'Expired';
    bool isPaid = status != 'Ordered' && !isCancelledOrExpired;
    
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
              _buildStatusBadge(status)
            ],
          ),
          const SizedBox(height: 4),
          Text(date != null ? DateFormat('MMMM dd, yyyy • hh:mm a').format(date) : '-', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          if (status == 'Ordered' && date != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.timer_outlined, size: 14, color: Colors.red.shade700),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Bayar sebelum ${DateFormat('hh:mm a').format(date.add(const Duration(minutes: 1)))} (Masa berlaku 1 menit)',
                      style: TextStyle(fontSize: 11, color: Colors.red.shade700, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
          
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Pembayaran', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    const SizedBox(height: 4),
                    Text(currency.format(total), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status Pembayaran', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: isCancelledOrExpired ? Colors.red : (isPaid ? _primaryColor : Colors.orange), shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Flexible(child: Text(status == 'Cancelled' ? 'Dibatalkan' : (status == 'Expired' ? 'Kedaluwarsa' : (isPaid ? 'Lunas' : 'Belum bayar')), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isCancelledOrExpired ? Colors.red : Colors.black), overflow: TextOverflow.ellipsis)),
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

  Widget _buildStatusStepper(OrderModel order) {
    final steps = ['Ordered', 'Paid', 'Shipped', 'Delivered'];
    final currentIndex = order.stepperIndex;
    final isCancelledOrExpired = order.isCancelledOrExpired;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(steps.length, (index) {
        bool isCompleted = index <= currentIndex;
        
        DateTime? stepDate;
        if (index == 0) {
          stepDate = order.createdAt;
        } else if (index == 1) {
          stepDate = order.paidAt;
        } else if (index == 2) {
          stepDate = order.shippedAt;
        } else if (index == 3) {
          stepDate = order.deliveredAt;
        }

        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: Container(height: 3, color: index == 0 ? Colors.transparent : (isCompleted ? _primaryColor : Colors.grey.shade300))),
                  Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      color: isCompleted ? (isCancelledOrExpired && index == currentIndex ? Colors.red : _primaryColor) : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: isCompleted ? (isCancelledOrExpired && index == currentIndex ? Colors.red : _primaryColor) : Colors.grey.shade300),
                    ),
                    child: Icon(isCancelledOrExpired && index == currentIndex ? Icons.close : Icons.check, size: 14, color: isCompleted ? Colors.white : Colors.grey.shade300),
                  ),
                  Expanded(child: Container(height: 3, color: index == steps.length - 1 ? Colors.transparent : (isCompleted && index < currentIndex ? _primaryColor : Colors.grey.shade300))),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                steps[index].displayStatus,
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
    List<Widget> actions = [];

    if (_order?.cancellationStatus == 'Requested') {
      actions.add(
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pengajuan Pembatalan Diproses', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Alasan: ${_order?.cancellationReason ?? "-"}', style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
      );
    } else if (_order?.cancellationStatus == 'Rejected') {
      actions.add(
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: const Text('Pengajuan pembatalan Anda sebelumnya ditolak oleh Admin.', style: TextStyle(color: Colors.red, fontSize: 12)),
          ),
        ),
      );
    }

    if (status == 'Ordered') {
      actions.add(
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              key: const Key('btn_pay_now'),
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
        ),
      );
    }

    if ((status == 'Ordered' || status == 'Paid') && _order?.cancellationStatus != 'Requested') {
      actions.add(
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              key: const Key('btn_cancel_order'),
              onPressed: () => _showCancelDialog(),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Batalkan Pesanan', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      );
    }

    if (actions.isEmpty) return const SizedBox.shrink();
    return Column(children: actions);
  }

  Future<void> _showCancelDialog() async {
    final reasonController = TextEditingController();

    final bool? submit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Batalkan Pesanan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Silakan masukkan alasan pembatalan:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Alasan...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false), 
            child: const Text('Tutup', style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, elevation: 0),
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Alasan tidak boleh kosong')));
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('Kirim Pengajuan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (submit == true) {
      setState(() => _isLoading = true);
      final success = await _userController.requestCancellation(_order!.orderId, reasonController.text.trim());
      
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengajuan pembatalan berhasil dikirim'), backgroundColor: Colors.green));
        await _fetchOrder();
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mengirim pengajuan'), backgroundColor: Colors.red));
      }
    }
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

  Widget _buildSummaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        Text(value, style: TextStyle(fontSize: 13, color: valueColor ?? Colors.black87)),
      ],
    );
  }

  Widget _buildPaymentInfoCard(String paymentMethod, DateTime? date, String transactionId, String invoiceId) {
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
                    Text('Metode Pembayaran', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
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
                    Text('ID Transaksi', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
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
                    Text('Tanggal Pembayaran', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    const SizedBox(height: 4),
                    Text(date != null ? DateFormat('MMMM dd, yyyy').format(date) : '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ID Invoice', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    const SizedBox(height: 4),
                    Text(invoiceId, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black)),
                  ],
                ),
              ),
            ],
          ),
          if (_order != null &&
              (_order!.status == 'Delivered' ||
                  _order!.status == 'Cancelled' ||
                  _order!.status == 'Paid')) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  PdfService.generateAndOpenInvoice(_order!);
                },
                icon: const Icon(Icons.download_outlined, size: 18),
                label: const Text('Unduh Invoice',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade100,
                  foregroundColor: Colors.black87,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ],
      ),
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
}