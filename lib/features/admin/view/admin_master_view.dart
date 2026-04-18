import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/admin_master_controller.dart';

class AdminMasterView extends StatefulWidget {
  const AdminMasterView({super.key});

  @override
  State<AdminMasterView> createState() => _AdminMasterViewState();
}

class _AdminMasterViewState extends State<AdminMasterView> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'active';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminMasterController()..fetchAllRetailers(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Color(0xFF1F2937), size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Consumer<AdminMasterController>(
          builder: (context, controller, child) {
            if (controller.isLoading && controller.retailers.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
              );
            }

            List<Map<String, dynamic>> filteredRetailers =
                controller.filteredRetailers;
            if (_selectedFilter == 'active') {
              filteredRetailers = filteredRetailers
                  .where((r) => r['isActive'] == true)
                  .toList();
            } else if (_selectedFilter == 'inactive') {
              filteredRetailers = filteredRetailers
                  .where((r) => r['isActive'] == false)
                  .toList();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Search Bar ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search retailer',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Inter',
                        color: Colors.grey[400],
                      ),
                      prefixIcon: const Icon(Icons.search,
                          color: Color(0xFF9CA3AF), size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF3F4F6),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: controller.searchRetailers,
                  ),
                ),

                // ── Total Retailers + Toggle Active/Inactive ────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      // Kotak Total Retailers
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Retailers',
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w400,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${controller.retailers.length}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Inter',
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Tombol Active & Inactive (horizontal)
                      Row(
                        children: [
                          _filterButton('Active', 'active'),
                          const SizedBox(width: 8),
                          _filterButton('Inactive', 'inactive'),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── List Retailer ───────────────────────────────────────
                Expanded(
                  child: filteredRetailers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.store_outlined,
                                  size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'Tidak ada data retailer',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Inter',
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: filteredRetailers.length,
                          itemBuilder: (context, index) {
                            final retailer = filteredRetailers[index];
                            final isActive = retailer['isActive'] == true;
                            return _retailerCard(
                                context, retailer, isActive, controller);
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Widget: Tombol Filter Active / Inactive ───────────────────────────
  Widget _filterButton(String label, String filter) {
    final isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF8FAF8F)
              : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter',
            color: isSelected ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  // ── Widget: Card Retailer ─────────────────────────────────────────────
  Widget _retailerCard(
    BuildContext context,
    Map<String, dynamic> retailer,
    bool isActive,
    AdminMasterController controller,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ikon toko bulat hijau
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFECF3E8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: Color(0xFF2E7D32),
                  size: 24,
                ),
              ),

              const SizedBox(width: 12),

              // Nama, Alamat, ID
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      retailer['fullName'] ?? 'Tanpa Nama',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      retailer['address'] ?? '-',
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'Inter',
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: #KNY${(retailer['id']?.toString() ?? '').length >= 6 ? retailer['id'].toString().substring(0, 6).toUpperCase() : (retailer['id']?.toString() ?? '').toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'Inter',
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Dropdown Status Button
              _StatusDropdownButton(
                isActive: isActive,
                onStatusChange: (newStatus) async {
                  if (!newStatus) {
                    final ok = await controller
                        .disableRetailer(retailer['id']);
                    if (ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Retailer dinonaktifkan'),
                          backgroundColor: Colors.orange,
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                    return ok;
                  } else {
                    final ok = await controller
                        .enableRetailer(retailer['id']);
                    if (ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Retailer diaktifkan'),
                          backgroundColor: Color(0xFF2E7D32),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                    return ok;
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Ikon chat di bawah kiri
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 19,
            color: Colors.grey[400],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Widget: Status Dropdown Button
// ═══════════════════════════════════════════════════════════════
class _StatusDropdownButton extends StatefulWidget {
  final bool isActive;
  final Future<bool> Function(bool newStatus) onStatusChange;

  const _StatusDropdownButton({
    required this.isActive,
    required this.onStatusChange,
  });

  @override
  State<_StatusDropdownButton> createState() => _StatusDropdownButtonState();
}

class _StatusDropdownButtonState extends State<_StatusDropdownButton>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _animController;
  late Animation<double> _rotateAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _rotateAnim = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    });
  }

  Future<void> _selectStatus(bool newStatus) async {
    // Tutup dropdown
    setState(() => _isOpen = false);
    _animController.reverse();

    // Jika status sama, tidak perlu konfirmasi
    if (newStatus == widget.isActive) return;

    // Tampilkan dialog konfirmasi
    final confirmed = await _showConfirmDialog(context);
    if (confirmed == true) {
      await widget.onStatusChange(newStatus);
    }
  }

  // ── Dialog Konfirmasi ──────────────────────────────────────
  Future<bool?> _showConfirmDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Konten atas ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                children: [
                  // Ikon toko
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFECF3E8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: Color(0xFF2E7D32),
                      size: 42,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Judul
                  const Text(
                    'Apakah Anda yakin ingin\nmengubah status retailer?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Inter',
                      color: Color(0xFF1F2937),
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Pesan warning
                  RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: 'Inter',
                        color: Color(0xFF9CA3AF),
                        height: 1.5,
                      ),
                      children: [
                        TextSpan(
                          text: 'Warning! ',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        TextSpan(
                          text:
                              '"Mengubah status akan mempengaruhi akses retailer ke platform dan visibilitas produk mereka."',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Divider ──────────────────────────────────────
            Container(height: 1, color: const Color(0xFFF3F4F6)),

            // ── Tombol Yes & Cancel ───────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  // Tombol Yes
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(true),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3A6B1F),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Yes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Inter',
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Tombol Cancel
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(false),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Inter',
                              color: Color(0xFF374151),
                            ),
                          ),
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

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isActive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Tombol Select ──────────────────────────────────────
        GestureDetector(
          onTap: _toggleDropdown,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _isOpen
                  ? (isActive
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFFE4E4))
                  : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: _isOpen
                    ? (isActive
                        ? const Color(0xFF86EFAC)
                        : const Color(0xFFFCA5A5))
                    : const Color(0xFFD1D5DB),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                RotationTransition(
                  turns: _rotateAnim,
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: _isOpen
                        ? (isActive
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFDC2626))
                        : const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Select',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Inter',
                    color: _isOpen
                        ? (isActive
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFDC2626))
                        : const Color(0xFF374151),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Dropdown Menu ──────────────────────────────────────
        if (_isOpen) ...[
          const SizedBox(height: 6),
          Container(
            width: 130,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: const Color(0xFFD1D5DB), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pilihan Active
                GestureDetector(
                  onTap: () => _selectStatus(true),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFFDCFCE7)
                          : Colors.transparent,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12)),
                    ),
                    child: Text(
                      'Active',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Inter',
                        color: isActive
                            ? const Color(0xFF16A34A)
                            : const Color(0xFF374151),
                      ),
                    ),
                  ),
                ),
                // Divider
                Container(height: 1, color: const Color(0xFFF3F4F6)),
                // Pilihan Inactive
                GestureDetector(
                  onTap: () => _selectStatus(false),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: !isActive
                          ? const Color(0xFFFFE4E4)
                          : Colors.transparent,
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(12)),
                    ),
                    child: Text(
                      'Inactive',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Inter',
                        color: !isActive
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF374151),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}