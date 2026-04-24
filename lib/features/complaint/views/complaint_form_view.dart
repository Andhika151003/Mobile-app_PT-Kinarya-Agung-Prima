import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../order/controllers/order_user_controller.dart';
import '../../order/models/order.dart';
import '../controllers/complaint_retail_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../views/complaint_history_view.dart';

class ComplaintFormView extends StatefulWidget {
  final String orderId;
  final String orderDate;

  const ComplaintFormView({
    super.key,
    required this.orderId,
    required this.orderDate,
  });

  @override
  State<ComplaintFormView> createState() => _ComplaintFormViewState();
}

class _ComplaintFormViewState extends State<ComplaintFormView> {
  final ComplaintUserController _controller = ComplaintUserController();
  final OrderUserController _orderController = OrderUserController();

  bool _isLoading = false;
  bool _isLoadingOrders = false;

  String? _currentOrderId;
  String? _currentOrderDate;
  String? _currentProductName;
  final List<Map<String, dynamic>> _purchasedProducts = [];
  static const _primaryColor = Color(0xFF4A7D3C);
  static const _bgColor = Color(0xFFF8F9FA);

  String? _selectedIssueType;
  final TextEditingController _descriptionController = TextEditingController();
  final List<File> _attachedImages = [];

  final List<String> _issueTypes = [
    'Salah Produk',
    'Produk Rusak',
    'Jumlah Tidak Sesuai',
    'Pertanyaan Produk',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _currentOrderId = widget.orderId == 'Bantuan Umum' ? null : widget.orderId;
    _currentOrderDate = widget.orderDate == 'Bantuan Umum'
        ? null
        : widget.orderDate;
    _fetchUserOrders();
  }

  Future<void> _fetchUserOrders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isLoadingOrders = true;
      _purchasedProducts.clear();
    });
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .get();

      setState(() {
        final List<OrderModel> orders = snapshot.docs
            .map((doc) {
              final data = doc.data();
              data['orderId'] = doc.id;
              return OrderModel.fromMap(data);
            })
            .where((order) => order.status == 'Delivered')
            .toList();

        orders.sort((a, b) {
          final dateA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final dateB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return dateB.compareTo(dateA);
        });

        for (var order in orders) {
          for (var item in order.items) {
            _purchasedProducts.add({
              'key': '${order.orderId}_${item.title}',
              'orderId': order.orderId,
              'productName': item.title,
              'orderDate': order.createdAt != null
                  ? DateFormat('dd MMM yyyy, HH:mm').format(order.createdAt!)
                  : '-',
            });
          }
        }
      });
    } catch (e) {
      debugPrint('Error fetching orders: $e');
    } finally {
      if (mounted) setState(() => _isLoadingOrders = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles.isNotEmpty) {
      setState(() {
        for (var file in pickedFiles) {
          _attachedImages.add(File(file.path));
        }
      });
    }
  }

  Future<void> _submitComplaint() async {
    if (_selectedIssueType == null ||
        _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap pilih jenis kendala dan isi deskripsi.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await _controller.submitComplaint(
      orderId: _currentOrderId ?? 'Bantuan Umum',
      productName: _currentProductName,
      issueType: _selectedIssueType!,
      description: _descriptionController.text.trim(),
      images: _attachedImages,
    );

    setState(() => _isLoading = false);

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Komplain berhasil dikirim! Tim kami akan segera menindaklanjuti.',
          ),
          backgroundColor: _primaryColor,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ComplaintHistoryView()),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengirim komplain. Silakan coba lagi.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              size: 14,
              color: Colors.black87,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Bantuan',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black87, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.support_agent_rounded,
                          size: 36,
                          color: _primaryColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tim Support',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tersedia 24/7',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Online',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // --- FORM FIELDS ---
                  _buildFormCard(
                    title: 'Pilih Jenis Kendala',
                    child: DropdownButtonFormField<String>(
                      value: _selectedIssueType,
                      decoration: InputDecoration(
                        hintText: 'Pilih jenis kendala...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade400,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: _primaryColor),
                        ),
                      ),
                      items: _issueTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(
                            type,
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setState(() => _selectedIssueType = val),
                    ),
                  ),

                  _buildFormCard(
                    title: 'Deskripsikan Kendala Anda',
                    child: TextField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText:
                            'Barang yang diterima tidak sesuai pesanan, spesifikasi berbeda, dan kemasan rusak...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade400,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: _primaryColor),
                        ),
                      ),
                    ),
                  ),

                  _buildFormCard(
                    title: 'Tambahkan Lampiran',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.upload_file, size: 16),
                          label: const Text('Upload Gambar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey.shade700,
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                        if (_attachedImages.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _attachedImages.map((file) {
                              return Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      file,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: -8,
                                    right: -8,
                                    child: IconButton(
                                      icon: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                      onPressed: () {
                                        setState(
                                          () => _attachedImages.remove(file),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),

                  _buildFormCard(
                    title: 'Informasi Pesanan',
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          value:
                              _purchasedProducts.any(
                                (p) =>
                                    p['key'] ==
                                    '${_currentOrderId}_$_currentProductName',
                              )
                              ? '${_currentOrderId}_$_currentProductName'
                              : null,
                          isExpanded: true,
                          decoration: InputDecoration(
                            hintText: 'Pilih Produk yang Bermasalah...',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade400,
                            ),
                            prefixIcon: const Icon(
                              Icons.inventory_2_outlined,
                              size: 20,
                              color: _primaryColor,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                          ),
                          items: _purchasedProducts.map((product) {
                            return DropdownMenuItem(
                              value: product['key'] as String,
                              child: Text(
                                '${product['productName']} (Order: ${product['orderId']})',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              final selectedProduct = _purchasedProducts
                                  .firstWhere((p) => p['key'] == val);
                              setState(() {
                                _currentOrderId = selectedProduct['orderId'];
                                _currentProductName =
                                    selectedProduct['productName'];
                                _currentOrderDate =
                                    selectedProduct['orderDate'];
                              });
                            }
                          },
                        ),
                        if (_isLoadingOrders)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: LinearProgressIndicator(minHeight: 2),
                          ),
                        const SizedBox(height: 12),
                        if (_purchasedProducts.isEmpty && !_isLoadingOrders)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              'Hanya pesanan yang sudah diterima (Delivered) yang dapat diajukan komplain.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange.shade800,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        Row(
                          children: [
                            Expanded(
                              child: _buildOrderInfoChip(
                                'ID: ${_currentOrderId ?? '-'}',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildOrderInfoChip(
                                _currentOrderDate ?? '-',
                              ),
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

          // --- BOTTOM BUTTON ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitComplaint,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Kirim',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildOrderInfoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
