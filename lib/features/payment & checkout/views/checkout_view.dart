import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../cart/controllers/cart_controller.dart';
import '../controllers/checkout_controller.dart';
import '../views/payment_webview.dart';
import '../views/payment_status_view.dart';
import '../../authentication/controllers/profile_user_controller.dart';
import '../../promotion/controllers/promotion_user_controller.dart';
import '../../promotion/models/promotion.dart';
import '../../address/views/address_list_view.dart';
import '../../address/controllers/address_controller.dart';
import '../../address/models/address_model.dart';

class CheckoutView extends StatefulWidget {
  const CheckoutView({super.key});

  @override
  State<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {
  final CartController _cartController = CartController();
  final CheckoutController _checkoutController = CheckoutController();
  final PromotionUserController _promoController = PromotionUserController();
  final AddressController _addressController = AddressController();

  bool _isLoadingProfile = true;
  bool _isProcessing = false;

  String shippingAddress = 'Memuat alamat...';
  String? shippingPhone;
  String fullname = 'Customer';

  String paymentMethod = 'Pilih Metode Pembayaran';
  String _paymentMethodCode = 'VA';
  String promoCode = 'Apply promo code';
  PromotionModel? _appliedPromo;

  static const List<Map<String, String>> _paymentMethods = [
    {
      'code': 'BC',
      'name': 'BCA Virtual Account',
      'icon': 'bank',
      'desc': 'Cek otomatis',
    },
    {
      'code': 'I1',
      'name': 'BNI Virtual Account',
      'icon': 'bank',
      'desc': 'Cek otomatis',
    },
    {
      'code': 'M2',
      'name': 'Mandiri Virtual Account',
      'icon': 'bank',
      'desc': 'Cek otomatis',
    },
    {'code': 'BR', 'name': 'BRIVA', 'icon': 'bank', 'desc': 'Cek otomatis'},
  ];

  @override
  void initState() {
    super.initState();
    _loadRetailerAddress();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadRetailerAddress() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final String fallbackName =
          user?.displayName ?? user?.email?.split('@').first ?? 'Customer Baru';

      // 1. Get user profile for fullname
      final profile = await RetailProfileController().getRetailProfile();
      if (profile != null && mounted) {
        setState(() {
          fullname =
              profile['storeName']?.toString() ??
              profile['fullName']?.toString() ??
              fallbackName;
        });
      }

      // 2. Get default address from new system
      final defaultAddress = await _addressController.getDefaultAddress();

      if (mounted) {
        setState(() {
          if (defaultAddress != null) {
            shippingAddress = defaultAddress.fullAddress;
            fullname = defaultAddress.recipientName;
            shippingPhone = defaultAddress.phoneNumber;
          } else {
            shippingAddress = 'Alamat belum diatur (Klik untuk menambah)';
          }
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          shippingAddress = 'Gagal memuat alamat';
          _isLoadingProfile = false;
        });
      }
    }
  }

  Future<void> _selectAddress() async {
    final result = await Navigator.push<AddressModel>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddressListView(isSelecting: true),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        shippingAddress = result.fullAddress;
        fullname = result.recipientName;
        shippingPhone = result.phoneNumber;
      });
    }
  }

  void _showPaymentMethodSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pilih Metode Pembayaran',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...(_paymentMethods.map((m) {
                final isSelected = _paymentMethodCode == m['code'];
                return InkWell(
                  onTap: () {
                    setState(() {
                      paymentMethod = m['name']!;
                      _paymentMethodCode = m['code']!;
                    });
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFE8F5E9)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF458833)
                            : Colors.grey.shade200,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Icon(
                            m['icon'] == 'qr'
                                ? Icons.qr_code
                                : m['icon'] == 'wallet'
                                ? Icons.account_balance_wallet_outlined
                                : Icons.account_balance_outlined,
                            color: const Color(0xFF458833),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m['name']!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                m['desc']!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF458833),
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                );
              })),
            ],
          ),
        );
      },
    );
  }

  void _showPromoSelectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Voucher & Promo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<Map<String, dynamic>>(
                  future: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    final results = await Future.wait([
                      _promoController.getActivePromotions(),
                      if (user != null)
                        _promoController.getUsedPromoIds(user.uid)
                      else
                        Future.value(<String>{}),
                    ]);
                    return {
                      'promos': results[0] as List<PromotionModel>,
                      'usedIds': results[1] as Set<String>,
                    };
                  }(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final data = snapshot.data ?? {};
                    final allPromos =
                        (data['promos'] as List<PromotionModel>?) ?? [];
                    final usedIds = (data['usedIds'] as Set<String>?) ?? {};
                    final promos = allPromos.where((p) => p.isActive).toList();

                    if (promos.isEmpty) {
                      return const Center(
                        child: Text('Tidak ada promo aktif saat ini.'),
                      );
                    }
                    return ListView.builder(
                      itemCount: promos.length,
                      itemBuilder: (ctx, i) {
                        final p = promos[i];
                        final isSelected = _appliedPromo?.id == p.id;
                        final isUsed = usedIds.contains(p.id);

                        bool isEligible = true;
                        if (p.productIds.isNotEmpty) {
                          final cartProductIds = _cartController.items
                              .map((item) => item.id)
                              .toSet();
                          if (p.discountType == 'bundle') {
                            isEligible = p.productIds.every(
                              (id) => cartProductIds.contains(id),
                            );
                          } else {
                            isEligible = p.productIds.any(
                              (id) => cartProductIds.contains(id),
                            );
                          }
                        }

                        return InkWell(
                          onTap: () async {
                            if (isUsed) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Anda sudah pernah menggunakan promo ini.',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            if (!isEligible) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Promo tidak berlaku untuk produk di keranjang Anda.',
                                  ),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }

                            final user = FirebaseAuth.instance.currentUser;
                            if (user == null) return;

                            final navigator = Navigator.of(context);

                            setState(() {
                              _appliedPromo = p;
                              promoCode = p.title;
                            });
                            if (mounted) navigator.pop();
                          },
                          child: Opacity(
                            opacity: (isEligible && !isUsed) ? 1.0 : 0.5,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF458833)
                                      : Colors.grey.shade200,
                                  width: isSelected ? 1.5 : 1,
                                ),
                                color: isSelected
                                    ? const Color(0xFFE8F5E9)
                                    : Colors.white,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: p.imageUrl != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.network(
                                              p.imageUrl!,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.local_offer,
                                            color: Color(0xFF458833),
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          p.discountText,
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (isUsed)
                                          const Text(
                                            'Sudah digunakan',
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle,
                                      color: Color(0xFF458833),
                                    )
                                  else
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 14,
                                      color: Colors.grey,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              if (_appliedPromo != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _appliedPromo = null;
                        promoCode = 'Apply promo code';
                      });
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Remove Promo',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double discountAmount = 0;
    if (_appliedPromo != null) {
      final bool hasSpecificProducts = _appliedPromo!.productIds.isNotEmpty;

      if (_appliedPromo!.discountType == 'percentage') {
        if (hasSpecificProducts) {
          for (var item in _cartController.items) {
            if (_appliedPromo!.productIds.contains(item.id)) {
              discountAmount +=
                  (item.price * item.quantity) *
                  (_appliedPromo!.discountValue / 100);
            }
          }
        } else {
          discountAmount =
              _cartController.subtotal * (_appliedPromo!.discountValue / 100);
        }
      } else if (_appliedPromo!.discountType == 'fixed') {
        if (hasSpecificProducts) {
          double eligibleSubtotal = 0;
          for (var item in _cartController.items) {
            if (_appliedPromo!.productIds.contains(item.id)) {
              eligibleSubtotal += (item.price * item.quantity);
            }
          }
          if (eligibleSubtotal > 0) {
            discountAmount = _appliedPromo!.discountValue;
            if (discountAmount > eligibleSubtotal) {
              discountAmount = eligibleSubtotal;
            }
          }
        } else {
          discountAmount = _appliedPromo!.discountValue;
        }
      } else if (_appliedPromo!.discountType == 'bundle') {
        if (hasSpecificProducts) {
          int minSets = -1;
          for (var pid in _appliedPromo!.productIds) {
            int qty = 0;
            for (var item in _cartController.items) {
              if (item.id == pid) {
                qty = item.quantity;
                break;
              }
            }

            if (qty == 0) {
              minSets = 0;
              break;
            }

            if (minSets == -1 || qty < minSets) {
              minSets = qty;
            }
          }

          if (minSets > 0) {
            discountAmount = _appliedPromo!.discountValue * minSets;
          }
        }
      } else if (_appliedPromo!.discountType == 'bogo') {
        for (var item in _cartController.items) {
          if (hasSpecificProducts) {
            if (_appliedPromo!.productIds.contains(item.id) &&
                item.quantity >= 2) {
              int sets = item.quantity ~/ 2;
              discountAmount += sets * item.price;
            }
          } else {
            if (item.quantity >= 2) {
              int sets = item.quantity ~/ 2;
              discountAmount += sets * item.price;
            }
          }
        }
      }

      if (_appliedPromo!.maxDiscount != null &&
          discountAmount > _appliedPromo!.maxDiscount!) {
        discountAmount = _appliedPromo!.maxDiscount!;
      }

      if (discountAmount > _cartController.subtotal) {
        discountAmount = _cartController.subtotal;
      }
    }

    double taxableAmount = _cartController.subtotal - discountAmount;
    double tax = taxableAmount * 0.11;
    double finalTotal = taxableAmount + _cartController.shippingCost + tax;
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoadingProfile
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF458833)),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    color: Colors.white,
                    margin: const EdgeInsets.only(top: 8),
                    child: Column(
                      children: [
                        _buildActionRow(
                          'SHIPPING',
                          shippingAddress,
                          true,
                          onTap: _selectAddress,
                        ),
                        const Divider(height: 1, color: Colors.black12),
                        _buildActionRow(
                          'PAYMENT',
                          paymentMethod,
                          true,
                          onTap: _showPaymentMethodSheet,
                        ),
                        const Divider(height: 1, color: Colors.black12),
                        _buildActionRow(
                          'PROMOS',
                          promoCode,
                          true,
                          onTap: _showPromoSelectionSheet,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 80,
                                child: Text(
                                  'ITEMS',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Expanded(
                                child: Text(
                                  'DESCRIPTION',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                'PRICE',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _cartController.items.length,
                          itemBuilder: (context, index) {
                            final item = _cartController.items[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: item.imageUrl.isNotEmpty
                                          ? Image.network(
                                              item.imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => const Icon(
                                                    Icons.image_outlined,
                                                    color: Colors.grey,
                                                  ),
                                            )
                                          : const Icon(
                                              Icons.image_outlined,
                                              color: Colors.grey,
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.variant,
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Quantity: ${item.quantity} pcs',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    currencyFormatter.format(
                                      item.price * item.quantity,
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildSummaryRow(
                          'Subtotal (${_cartController.items.length})',
                          currencyFormatter.format(_cartController.subtotal),
                        ),
                        if (discountAmount > 0) ...[
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Promotion Discount',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '- ${currencyFormatter.format(discountAmount)}',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        _buildSummaryRow(
                          'Shipping total',
                          _cartController.shippingCost == 0
                              ? 'Free'
                              : currencyFormatter.format(
                                  _cartController.shippingCost,
                                ),
                        ),
                        const SizedBox(height: 12),
                        _buildSummaryRow(
                          'Taxes (11%)',
                          currencyFormatter.format(tax),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(height: 1, color: Colors.black12),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              currencyFormatter.format(finalTotal),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.black12, width: 1)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Batas waktu pembayaran adalah 1 menit setelah pesanan dibuat.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing
                      ? null
                      : () async {
                          if (_cartController.items.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Keranjang Anda kosong!'),
                              ),
                            );
                            return;
                          }

                          if (paymentMethod == 'Pilih Metode Pembayaran') {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Pilih metode pembayaran terlebih dahulu',
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }

                          if (shippingAddress.contains('belum diatur') ||
                              shippingAddress.contains('Gagal memuat')) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Harap atur alamat pengiriman Anda terlebih dahulu.',
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }

                          setState(() => _isProcessing = true);

                          List<Map<String, dynamic>> orderItems =
                              _cartController.items.map((item) {
                                return {
                                  'productId': item.id,
                                  'title': item.title,
                                  'variant': item.variant,
                                  'category': item.category,
                                  'quantity': item.quantity,
                                  'price': item.price,
                                  'imageUrl': item.imageUrl,
                                };
                              }).toList();

                          final messenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(context);
                          final result = await _checkoutController
                              .processCheckout(
                                fullName: fullname,
                                shippingAddress: shippingAddress,
                                phoneNumber: shippingPhone,
                                paymentMethod: paymentMethod,
                                paymentMethodCode: _paymentMethodCode,
                                promoId: _appliedPromo?.id,
                                promoCode: _appliedPromo != null
                                    ? _appliedPromo!.title
                                    : '-',
                                subtotal: _cartController.subtotal,
                                shippingCost: _cartController.shippingCost,
                                tax: tax,
                                total: finalTotal,
                                items: orderItems,
                                discountAmount: discountAmount,
                              );

                          if (!mounted) return;
                          setState(() => _isProcessing = false);

                          if (result.containsKey('error')) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(result['error']!),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } else {
                            _cartController.clearCart();
                            await navigator.push<bool>(
                              MaterialPageRoute(
                                builder: (_) => PaymentWebView(
                                  paymentUrl: result['paymentUrl']!,
                                  orderId: result['orderId']!,
                                ),
                              ),
                            );

                            if (!context.mounted) return;
                            _cartController.clearCart();
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => PaymentStatusView(
                                  orderId: result['orderId']!,
                                ),
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF458833),
                    disabledBackgroundColor: Colors.grey.shade400,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Place order',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionRow(
    String label,
    String value,
    bool showChevron, {
    VoidCallback? onTap,
  }) {
    final bool isPlaceholder =
        value.contains('Add') ||
        value.contains('Apply') ||
        value.contains('Pilih');
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: isPlaceholder ? Colors.grey : Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (showChevron)
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20)
            else
              const SizedBox(width: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.black87, fontSize: 14),
        ),
        Text(
          value,
          style: const TextStyle(color: Colors.black87, fontSize: 14),
        ),
      ],
    );
  }
}
