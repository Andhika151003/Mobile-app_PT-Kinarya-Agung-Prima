import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../controllers/order_admin_controller.dart';
import '../../shared/services/pdf_service.dart';
import '../../../core/utils/status_helper.dart';

class OrderDetailAdminView extends StatefulWidget {
  final String orderId;
  final OrderAdminController? adminController;
  
  const OrderDetailAdminView({
    super.key, 
    required this.orderId, 
    this.adminController,
  });

  @override
  State<OrderDetailAdminView> createState() => _OrderDetailAdminViewState();
}

class _OrderDetailAdminViewState extends State<OrderDetailAdminView> {
  static const _primaryColor = Color(0xFF4A7D3C); 
  static const _bgColor = Color(0xFFF7F8FA);

  late final OrderAdminController _adminController;
  
  OrderModel? _order; 
  bool _isLoading = true;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _adminController = widget.adminController ?? OrderAdminController();
    _fetchOrder();
  }

  Future<void> _fetchOrder() async {
    OrderModel? initialOrder;
    try {
      final data = await _adminController.getOrderById(widget.orderId);
      if (data != null && mounted) {
        final order = OrderModel.fromMap(data);
        initialOrder = order;

        if (order.status == 'Ordered') {
          await _adminController.syncAllPendingOrders();
          
          final updatedData = await _adminController.getOrderById(widget.orderId);
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
    } catch (e) {
      if (mounted) {
        setState(() {
          // Gunakan data awal jika sync gagal, agar UI tidak stuck loading
          if (initialOrder != null) _order = initialOrder;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateStatus() async {
    if (_order == null) return;
    
    final currentStatus = _order!.status;
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
          Semantics(
            label: 'btn_confirm_cancel',
            child: TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          ),
          Semantics(
            label: 'btn_confirm_ok',
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, elevation: 0),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Konfirmasi', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isUpdating = true);
    try {
      await _adminController.updateOrderStatus(widget.orderId, newStatus);
      await _fetchOrder();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal update: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _cancelOrder() async {
    if (_order == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Batalkan Pesanan?'),
        content: const Text('Tindakan ini akan mengembalikan stok produk dan membatalkan pesanan secara permanen.'),
        actions: [
          Semantics(
            label: 'btn_cancel_dialog_close',
            child: TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Tutup', style: TextStyle(color: Colors.grey))),
          ),
          Semantics(
            label: 'btn_cancel_dialog_confirm',
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, elevation: 0),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Ya, Batalkan', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isUpdating = true);
    try {
      await _adminController.cancelOrder(widget.orderId);
      await _fetchOrder();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pesanan berhasil dibatalkan dan stok dikembalikan'), backgroundColor: Colors.orange));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal pembatalan: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _acceptCancellation() async {
    if (_order == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Terima Pembatalan?'),
        content: const Text('Tindakan ini akan mengembalikan stok produk dan membatalkan pesanan secara permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Tutup', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, elevation: 0),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Terima', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isUpdating = true);
    try {
      await _adminController.cancelOrder(widget.orderId, cancellationStatus: 'Approved');
      await _fetchOrder();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pembatalan berhasil disetujui'), backgroundColor: Colors.orange));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyetujui: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _rejectCancellation() async {
    if (_order == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Tolak Pembatalan?'),
        content: const Text('Pesanan ini akan tetap dilanjutkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, elevation: 0),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Tolak', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isUpdating = true);
    try {
      await _adminController.rejectCancellation(widget.orderId);
      await _fetchOrder();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pembatalan berhasil ditolak'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menolak: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isUpdating = false);
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



    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Semantics(
            label: 'btn_back',
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300)),
              child: const Icon(Icons.arrow_back_ios_new, size: 14, color: Colors.black87),
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Detail Pesanan', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          if (_order != null &&
              (_order!.status == 'Delivered' ||
                  _order!.status == 'Cancelled' ||
                  _order!.status == 'Paid'))
            IconButton(
              icon: Semantics(
                label: 'btn_print_invoice_header',
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300)),
                  child: const Icon(Icons.print_outlined,
                      size: 16, color: Colors.black87),
                ),
              ),
              onPressed: () {
                PdfService.generateAndOpenInvoice(_order!);
              },
            ),
          if (_isUpdating)
            const Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: _primaryColor, strokeWidth: 2))),
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
            _buildStatusStepper(order.status, order),
            
            _buildAdminActionButtons(order),
            
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
                    style: TextStyle(fontSize: 13, height: 1.4, color: order.shippingAddress.contains('tidak tersedia') ? Colors.red : Colors.black87)
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

            // 4. Order Items
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
            const Text('Informasi Pembayaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 8),
            _buildPaymentInfoCard(order.paymentMethod, order.createdAt, order.orderId, order.orderId),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildHeaderCard(String orderId, DateTime? date, double total, String status, NumberFormat currency) {
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
          Text(date != null ? _formatFullDateTime(date) : '-', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
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
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: (status == 'Cancelled' || status == 'Expired') ? Colors.red : (status == 'Ordered' ? Colors.orange : _primaryColor), shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Flexible(child: Text(status == 'Cancelled' ? 'Dibatalkan' : (status == 'Expired' ? 'Kedaluwarsa' : (status == 'Ordered' ? 'Belum bayar' : 'Lunas')), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: (status == 'Cancelled' || status == 'Expired') ? Colors.red : Colors.black), overflow: TextOverflow.ellipsis)),
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

  Widget _buildAdminActionButtons(OrderModel order) {
    List<Widget> actions = [];

    if (order.cancellationStatus == 'Requested') {
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
                const Text('Pengajuan Pembatalan dari Retailer', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Alasan: ${order.cancellationReason ?? "-"}', style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        key: const Key('btn_reject_cancellation'),
                        onPressed: _rejectCancellation,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Tolak', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        key: const Key('btn_accept_cancellation'),
                        onPressed: _acceptCancellation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: const Text('Terima', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      );
    }

    if (order.status != 'Delivered' && order.status != 'Expired' && order.status != 'Cancelled' && order.cancellationStatus != 'Requested') {
      actions.add(
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: Semantics(
                  label: 'btn_update_status',
                  child: ElevatedButton(
                    onPressed: _updateStatus,
                    style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0),
                    child: const Text('Update Status', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: Semantics(
                  label: 'btn_cancel_order',
                  child: OutlinedButton(
                    onPressed: _cancelOrder,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Batalkan Pesanan', style: TextStyle(color: Colors.red, fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (actions.isEmpty) return const SizedBox.shrink();
    return Column(children: actions);
  }

  Widget _buildStatusStepper(String currentStatus, OrderModel order) {
    final steps = ['Ordered', 'Paid', 'Shipped', 'Delivered'];
    int currentIndex = steps.indexOf(currentStatus);
    bool isCancelledOrExpired = currentStatus == 'Cancelled' || currentStatus == 'Expired';
    if (currentIndex == -1) {
      if (order.deliveredAt != null) {
        currentIndex = 3;
      } else if (order.shippedAt != null) {
        currentIndex = 2;
      } else if (order.paidAt != null) {
        currentIndex = 1;
      } else {
        currentIndex = 0;
      }
    }

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
                      border: Border.all(color: isCompleted ? (isCancelledOrExpired && index == currentIndex ? Colors.red : _primaryColor) : Colors.grey.shade300)
                    ),
                    child: Icon(
                      isCancelledOrExpired && index == currentIndex ? Icons.close : Icons.check, 
                      size: 14, 
                      color: isCompleted ? Colors.white : Colors.grey.shade300
                    ),
                  ),
                  Expanded(child: Container(height: 3, color: index == steps.length - 1 ? Colors.transparent : (isCompleted && index < currentIndex ? _primaryColor : Colors.grey.shade300))),
                ],
              ),
              const SizedBox(height: 8),
              Text(steps[index].displayStatus, style: TextStyle(fontSize: 12, fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal, color: isCompleted ? Colors.black : Colors.grey.shade500), textAlign: TextAlign.center),
              if (stepDate != null) Text(_formatStepDate(stepDate), style: TextStyle(fontSize: 10, color: Colors.grey.shade500), textAlign: TextAlign.center),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildItemRow(OrderItemModel item, NumberFormat currency) {
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
                Text('${currency.format(item.price)} per unit', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
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

  Widget _buildPaymentInfoCard(String paymentMethod, DateTime? date, String transactionId, String orderId) {
    final invoiceId = orderId;
    
    final digits = transactionId.replaceAll(RegExp(r'[^0-9]'), '');
    final shortTxn = digits.length >= 4 ? digits.substring(digits.length - 4) : digits;

    return Column(
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
                      Text(paymentMethod, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black)),
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
                  Text('TXN-$shortTxn', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black), maxLines: 1, overflow: TextOverflow.ellipsis),
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
                  Text(date != null ? _formatDate(date) : '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black)),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ID Invoice', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  const SizedBox(height: 4),
                  Text(invoiceId, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black), maxLines: 1, overflow: TextOverflow.ellipsis),
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
            child: Semantics(
              label: 'btn_download_invoice',
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
          ),
        ],
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

  String _formatStepDate(DateTime date) {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '${months[date.month]} ${date.day}, $h:$m';
  }
}