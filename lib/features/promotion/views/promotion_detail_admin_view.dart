import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/promotion.dart';
import 'form_promotion_admin_view.dart';
import '../controllers/promotion_admin_controller.dart';

class PromotionDetailAdminView extends StatefulWidget {
  final PromotionModel promotion;

  const PromotionDetailAdminView({super.key, required this.promotion});

  @override
  State<PromotionDetailAdminView> createState() =>
      _PromotionDetailAdminViewState();
}

class _PromotionDetailAdminViewState extends State<PromotionDetailAdminView> {
  late PromotionModel _promotion;

  List<Map<String, dynamic>> _appliedProducts = [];
  bool _loadingProducts = false;

  @override
  void initState() {
    super.initState();
    _promotion = widget.promotion;
    _fetchAppliedProducts(_promotion.productIds);
  }

  Future<void> _fetchAppliedProducts(List<String> productIds) async {
    if (productIds.isEmpty) {
      setState(() => _appliedProducts = []);
      return;
    }
    setState(() => _loadingProducts = true);
    try {
      final List<Map<String, dynamic>> results = [];
      for (int i = 0; i < productIds.length; i += 10) {
        final chunk = productIds.sublist(
            i, i + 10 > productIds.length ? productIds.length : i + 10);
        final snapshot = await FirebaseFirestore.instance
            .collection('products')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final imageUrls = data['imageUrls'] as List? ?? [];
          final imageUrl = (data['imageUrl'] as String? ?? '').isNotEmpty
              ? data['imageUrl'] as String
              : (imageUrls.isNotEmpty ? imageUrls[0].toString() : '');
          results.add({
            'id': doc.id,
            'name': data['name'] ?? '',
            'price': data['price'] ?? 0,
            'imageUrl': imageUrl,
          });
        }
      }
      setState(() {
        _appliedProducts = results;
        _loadingProducts = false;
      });
    } catch (e) {
      debugPrint('Error fetching applied products: $e');
      setState(() => _loadingProducts = false);
    }
  }

  Future<void> _refetchPromotion() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('promotions')
          .doc(_promotion.id)
          .get();
      if (doc.exists && mounted) {
        final updated = PromotionModel.fromMap(doc.id, doc.data()!);
        setState(() => _promotion = updated);
        await _fetchAppliedProducts(updated.productIds);
      }
    } catch (e) {
      debugPrint('Error refetching promotion: $e');
    }
  }

  Future<void> _navigateToEdit() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FormPromotionAdminView(promotion: _promotion),
      ),
    );
    if (mounted) await _refetchPromotion();
  }

  Future<void> _deletePromotion() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Konfirmasi',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx, false),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.close,
                          size: 16, color: Color(0xFF6B7280)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEB),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.red.shade300, width: 2),
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.red, size: 30),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Apakah Anda yakin ingin menghapus promosi ini?',
                      style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF374151),
                          height: 1.4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(
                          color: Color(0xFF2E7D32), width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Ya',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(
                          color: Color(0xFF2E7D32), width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Tidak',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937))),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true || !mounted) return;

    Navigator.pop(context, 'deleted');
    final controller = PromotionAdminController();
    await controller.deletePromotion(_promotion.id!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFF1F2937), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detail Promosi',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Color(0xFF1F2937),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: Colors.red, size: 22),
            onPressed: _deletePromotion,
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                color: Color(0xFF2563EB), size: 22),
            onPressed: _navigateToEdit,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Banner Image ──────────────────────────────────
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: _promotion.imageUrl != null &&
                      _promotion.imageUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(_promotion.imageUrl!,
                          fit: BoxFit.cover),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.camera_alt_outlined,
                              color: Color(0xFF2E7D32), size: 22),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Banner Promosi',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF9CA3AF)),
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 16),

            // ── Title & SKU ───────────────────────────────────
            Text(
              _promotion.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'SKU: ${_promotion.sku.replaceAll('#PRM-', '')}',
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF9CA3AF)),
            ),

            const SizedBox(height: 24),

            // ── Basic Information ─────────────────────────────
            const Text('Informasi Dasar',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937))),
            const SizedBox(height: 12),
            _infoTable([
              _InfoRow('ID Promosi', _promotion.sku),
              _InfoRow('Tipe Diskon',
                  _discountTypeLabel(_promotion.discountType)),
              _InfoRow('Jumlah Diskon', _promotion.discountText),
              if (_promotion.maxDiscount != null && _promotion.maxDiscount! > 0)
                _InfoRow('Diskon Maksimal', _formatPrice(_promotion.maxDiscount)),
            ]),

            const SizedBox(height: 24),

            // ── Schedule ──────────────────────────────────────
            const Text('Jadwal',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937))),
            const SizedBox(height: 12),
            _infoTable([
              _InfoRow('Tanggal Mulai', _formatDate(_promotion.startDate)),
              _InfoRow('Tanggal Berakhir', _formatDate(_promotion.endDate)),
              _InfoRow('Jam Mulai', _promotion.startTime),
              _InfoRow('Jam Berakhir', _promotion.endTime),
            ]),

            const SizedBox(height: 24),

            // ── Description ───────────────────────────────────
            const Text('Deskripsi',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937))),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Text(
                _promotion.description,
                style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    height: 1.6),
              ),
            ),

            const SizedBox(height: 24),

            // ── Applied Products ──────────────────────────────
            const Text('Produk yang Diterapkan',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937))),
            const SizedBox(height: 12),
            _loadingProducts
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(
                          color: Color(0xFF2E7D32)),
                    ),
                  )
                : _promotion.applicableTo == 'all'
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFC8E6C9)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.all_inclusive, color: Color(0xFF2E7D32), size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Berlaku untuk semua produk',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32)),
                            ),
                          ],
                        ),
                      )
                    : _appliedProducts.isEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFFE5E7EB)),
                            ),
                            child: const Text(
                              'Tidak ada produk yang diterapkan',
                              style: TextStyle(
                                  fontSize: 13, color: Color(0xFF9CA3AF)),
                            ),
                          )
                        : Column(
                            children: _appliedProducts
                                .map((p) => _productCard(p))
                                .toList(),
                          ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _productCard(Map<String, dynamic> p) {
    final imageUrl = p['imageUrl'] as String? ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.image_outlined,
                          color: Color(0xFF9CA3AF)),
                    )
                  : const Icon(Icons.image_outlined,
                      color: Color(0xFF9CA3AF)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p['name'] as String? ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatPrice(p['price']),
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTable(List<_InfoRow> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final i = entry.key;
          final row = entry.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(row.label,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF6B7280))),
                    Text(row.value,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        )),
                  ],
                ),
              ),
              if (i < rows.length - 1)
                const Divider(height: 1, color: Color(0xFFF3F4F6)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildImageThumbnail(String url) {
    return Container(); 
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _discountTypeLabel(String type) {
    switch (type) {
      case 'percentage':
        return 'Persentase';
      case 'fixed':
        return 'Potongan Harga Tetap';
      case 'bogo':
        return 'Beli 1 Gratis 1 (BOGO)';
      case 'bundle':
        return 'Paket (Bundle)';
      default:
        return type;
    }
  }

  String _formatPrice(dynamic price) {
    final num val = (price is num) ? price : 0;
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(val);
  }
}

class _InfoRow {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);
}