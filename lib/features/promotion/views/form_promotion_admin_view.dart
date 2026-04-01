import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/promotion_admin_controller.dart';
import '../models/promotion.dart';

class FormPromotionAdminView extends StatefulWidget {
  final PromotionModel? promotion;
  const FormPromotionAdminView({super.key, this.promotion});

  @override
  State<FormPromotionAdminView> createState() =>
      _FormPromotionAdminViewState();
}

class _FormPromotionAdminViewState extends State<FormPromotionAdminView> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _discountValueController;
  late TextEditingController _skuController;
  late String _discountType;
  late DateTime _startDate;
  late DateTime _endDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late String _status;
  bool _isLoading = false;

  // ── Validation state ─────────────────────────────────────
  bool _showTopWarning = false;
  bool _titleError = false;
  bool _discountTypeError = false;
  bool _discountAmountError = false;
  bool _dateError = false;
  bool _timeError = false;
  bool _productError = false;

  // ── Products ──────────────────────────────────────────────
  List<Map<String, dynamic>> _allProducts = [];
  bool _loadingProducts = false;
  List<String> _selectedProductIds = [];
  String _productSearchQuery = '';
  String _selectedCategory = 'All';
  List<String> _categories = ['All'];

  final PromotionAdminController _controller = PromotionAdminController();

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.promotion?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.promotion?.description ?? '');
    _discountValueController = TextEditingController(
      text: widget.promotion?.discountValue != null &&
              widget.promotion!.discountValue > 0
          ? widget.promotion!.discountValue.toString()
          : '',
    );
    _skuController = TextEditingController(
      text: widget.promotion?.sku ??
          '#PRM-${DateTime.now().millisecondsSinceEpoch % 9000 + 1000}',
    );
    _discountType = widget.promotion?.discountType ?? '';
    _startDate = widget.promotion?.startDate ?? DateTime.now();
    _endDate = widget.promotion?.endDate ??
        DateTime.now().add(const Duration(days: 7));
    _startTime = _parseTime(widget.promotion?.startTime ?? '00:00');
    _endTime = _parseTime(widget.promotion?.endTime ?? '23:59');
    _status = widget.promotion?.status ?? 'active';
    _selectedProductIds =
        List<String>.from(widget.promotion?.productIds ?? []);
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() => _loadingProducts = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('isAvailable', isEqualTo: true)
          .get();

      final products = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
          'price': data['price'] ?? 0,
          'category': data['category'] ?? 'Other',
          'imageUrl': data['imageUrl'] ?? '',
          'imageUrls': data['imageUrls'] ?? [],
          'sku': data['sku'] ?? '',
          'stock': data['stock'] ?? 0,
        };
      }).toList();

      final cats = <String>{'All'};
      for (final p in products) {
        if ((p['category'] as String).isNotEmpty) {
          cats.add(p['category'] as String);
        }
      }

      setState(() {
        _allProducts = products;
        _categories = cats.toList();
        _loadingProducts = false;
      });
    } catch (e) {
      debugPrint('Error fetching products: $e');
      setState(() => _loadingProducts = false);
    }
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(
        hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _discountValueController.dispose();
    _skuController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
              const ColorScheme.light(primary: Color(0xFF2E7D32)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
        _dateError = false;
      });
    }
  }

  Future<void> _selectTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
              const ColorScheme.light(primary: Color(0xFF2E7D32)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
        _timeError = false;
      });
    }
  }

  // ── Validasi manual ───────────────────────────────────────
  bool _validateAll() {
    bool valid = true;

    final titleEmpty = _titleController.text.trim().isEmpty;
    final discountTypeEmpty = _discountType.isEmpty;
    final needsAmount =
        _discountType != 'bogo' && _discountType != 'bundle';
    final discountAmtEmpty = needsAmount &&
        (_discountValueController.text.trim().isEmpty ||
            double.tryParse(_discountValueController.text.trim()) ==
                null);
    final dateInvalid = _startDate.isAfter(_endDate);
    final timeInvalid = (_startTime.hour > _endTime.hour) ||
        (_startTime.hour == _endTime.hour &&
            _startTime.minute >= _endTime.minute);
    final isAddMode = widget.promotion == null;
    final productEmpty = isAddMode && _selectedProductIds.isEmpty;

    setState(() {
      _titleError = titleEmpty;
      _discountTypeError = discountTypeEmpty;
      _discountAmountError = discountAmtEmpty;
      _dateError = dateInvalid;
      _timeError = timeInvalid;
      _productError = productEmpty;
      _showTopWarning = titleEmpty ||
          discountTypeEmpty ||
          discountAmtEmpty ||
          dateInvalid ||
          timeInvalid ||
          productEmpty;
    });

    if (_showTopWarning) {
      // Scroll ke atas supaya warning banner terlihat
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      valid = false;
    }

    return valid;
  }

  // ── Dialog sukses ─────────────────────────────────────────
  Future<void> _showSuccessDialog(String message) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: const Color(0xFF2E7D32), width: 4),
                ),
                child: const Icon(Icons.check_rounded,
                    color: Color(0xFF2E7D32), size: 40),
              ),
              const SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: const Text('OK',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Dialog konfirmasi delete ──────────────────────────────
  Future<bool?> _showDeleteConfirmDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Confirm',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
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
                      border: Border.all(
                          color: Colors.red.shade300, width: 2),
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.red, size: 30),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Are you sure you want to delete this promotion?',
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
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(
                            color: Color(0xFF2E7D32), width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Yes',
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
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(
                            color: Color(0xFF2E7D32), width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('No',
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
  }

  Future<void> _savePromotion() async {
    // Jalankan validasi manual
    if (!_validateAll()) return;

    setState(() => _isLoading = true);

    final startDateTime = DateTime(_startDate.year, _startDate.month,
        _startDate.day, _startTime.hour, _startTime.minute);
    final endDateTime = DateTime(_endDate.year, _endDate.month,
        _endDate.day, _endTime.hour, _endTime.minute);

    bool success;
    if (widget.promotion == null) {
      success = await _controller.createPromotion(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        discountType: _discountType,
        discountValue:
            double.tryParse(_discountValueController.text) ?? 0,
        productIds: _selectedProductIds,
        applicableTo: 'all',
        startDate: startDateTime,
        endDate: endDateTime,
        startTime: _formatTime(_startTime),
        endTime: _formatTime(_endTime),
        sku: _skuController.text,
      );
    } else {
      success = await _controller.updatePromotion(
        promotionId: widget.promotion!.id!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        discountType: _discountType,
        discountValue:
            double.tryParse(_discountValueController.text) ?? 0,
        productIds: _selectedProductIds,
        applicableTo: 'all',
        startDate: startDateTime,
        endDate: endDateTime,
        startTime: _formatTime(_startTime),
        endTime: _formatTime(_endTime),
        status: _status,
        sku: _skuController.text,
      );
    }

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (success) {
      await _showSuccessDialog(widget.promotion == null
          ? 'Successfully Created'
          : 'Successfully Saved');
      if (!mounted) return;
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Failed to save promotion'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _deletePromotion() async {
    final confirm = await _showDeleteConfirmDialog();
    if (confirm != true) return;
    setState(() => _isLoading = true);
    final ok = await _controller.deletePromotion(widget.promotion!.id!);
    setState(() => _isLoading = false);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context); // pop form
      Navigator.pop(context); // pop detail
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Promotion deleted'),
        backgroundColor: Colors.red,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Failed to delete promotion'),
        backgroundColor: Colors.red,
      ));
    }
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year.toString().substring(2)}';

  String _formatTimeDisplay(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}.${t.minute.toString().padLeft(2, '0')}';

  List<Map<String, dynamic>> get _filteredProducts {
    return _allProducts.where((p) {
      final matchSearch = (p['name'] as String)
          .toLowerCase()
          .contains(_productSearchQuery.toLowerCase());
      final matchCat = _selectedCategory == 'All' ||
          p['category'] == _selectedCategory;
      return matchSearch && matchCat;
    }).toList();
  }

  String _formatPrice(dynamic price) {
    final val = (price is num) ? price.toInt() : 0;
    if (val >= 1000) {
      return 'Rp ${val.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
    }
    return 'Rp $val';
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.promotion != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFF1F2937), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? 'Edit Promotion' : 'Add Promotion',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Color(0xFF1F2937),
          ),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Banner Warning (muncul saat ada error) ────────
            if (_showTopWarning) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFFFCD34D), width: 1),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFF59E0B), size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Lengkapi semua field wajib sebelum diproses!',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── Product Image ─────────────────────────────────
            _label('Product Image'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {},
              child: Container(
                height: 110,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD1D5DB)),
                ),
                child: Column(
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
                    Text(
                      isEditing
                          ? 'Replace Promotion Banner'
                          : 'Upload Promotion Banner',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF9CA3AF)),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Promotion Title ───────────────────────────────
            _label('Promotion Title'),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              onChanged: (v) {
                if (_titleError && v.trim().isNotEmpty) {
                  setState(() {
                    _titleError = false;
                    _showTopWarning = false;
                  });
                }
              },
              decoration: _inputDeco(
                isEditing
                    ? 'Change Promotion Title'
                    : 'Enter Promotion Title',
                hasError: _titleError,
              ),
            ),
            if (_titleError)
              _errorText('Nama promo wajib diisi'),

            const SizedBox(height: 20),

            // ── Description ───────────────────────────────────
            _label('Description'),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: _inputDeco(
                isEditing
                    ? 'Change Promotion Description'
                    : 'Enter Promotion Description',
              ),
            ),

            const SizedBox(height: 20),

            // ── Discount Type ─────────────────────────────────
            _label('Discount Type'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _discountTypeError
                      ? Colors.red
                      : const Color(0xFFE5E7EB),
                  width: _discountTypeError ? 1.5 : 1,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _discountType.isEmpty ? null : _discountType,
                  hint: const Text(''),
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF6B7280)),
                  items: const [
                    DropdownMenuItem(
                        value: 'percentage',
                        child: Text('Percentage')),
                    DropdownMenuItem(
                        value: 'fixed', child: Text('Fixed Amount')),
                    DropdownMenuItem(
                        value: 'bogo', child: Text('BOGO')),
                    DropdownMenuItem(
                        value: 'bundle', child: Text('Bundle Deal')),
                  ],
                  onChanged: (v) => setState(() {
                    _discountType = v!;
                    _discountTypeError = false;
                    _showTopWarning = false;
                  }),
                ),
              ),
            ),
            if (_discountTypeError)
              _errorText('Silakan pilih jenis diskon untuk promo ini.'),

            // ── Discount Amount ───────────────────────────────
            if (_discountType != 'bogo' &&
                _discountType != 'bundle') ...[
              const SizedBox(height: 20),
              _label('Discount Amount'),
              const SizedBox(height: 8),
              TextField(
                controller: _discountValueController,
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  if (_discountAmountError && v.trim().isNotEmpty) {
                    setState(() {
                      _discountAmountError = false;
                      _showTopWarning = false;
                    });
                  }
                },
                decoration: _inputDeco(
                  isEditing
                      ? 'Change Discount Percentage'
                      : (_discountType == 'percentage'
                          ? 'Enter Discount Percentage'
                          : 'Enter Discount Amount'),
                  hasError: _discountAmountError,
                ).copyWith(
                  suffixIcon: _discountType == 'percentage'
                      ? const Padding(
                          padding:
                              EdgeInsets.only(right: 14, top: 14),
                          child: Text('%',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF9CA3AF))),
                        )
                      : null,
                  suffixIconConstraints: const BoxConstraints(
                      minHeight: 0, minWidth: 0),
                ),
              ),
              if (_discountAmountError)
                _errorText(
                    'Jumlah diskon harus diisi dengan angka yang valid.'),
            ],

            const SizedBox(height: 20),

            // ── Promotion Period ──────────────────────────────
            _label('Promotion Period'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _datePicker(
                    'Start Date',
                    _startDate,
                    () => _selectDate(true),
                    hasError: _dateError,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _datePicker(
                    'End Date',
                    _endDate,
                    () => _selectDate(false),
                    hasError: _dateError,
                  ),
                ),
              ],
            ),
            if (_dateError)
              _errorText(
                  'Tanggal mulai dan tanggal berakhir promo wajib diisi.'),

            const SizedBox(height: 20),

            // ── Promotion Time ────────────────────────────────
            _label('Promotion Time'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _timePicker(
                    'Start Time',
                    _startTime,
                    () => _selectTime(true),
                    hasError: _timeError,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _timePicker(
                    'End Time',
                    _endTime,
                    () => _selectTime(false),
                    hasError: _timeError,
                  ),
                ),
              ],
            ),
            if (_timeError)
              _errorText(
                  'Waktu mulai dan waktu berakhir promo wajib diisi.'),

            const SizedBox(height: 24),

            // ── Product Selection (hanya Add mode) ────────────
            if (!isEditing) ...[
              _label('Product Selection'),
              const SizedBox(height: 6),
              if (_selectedProductIds.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${_selectedProductIds.length} product(s) selected',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              const SizedBox(height: 4),

              // Search produk
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search Product',
                  hintStyle: TextStyle(
                      fontSize: 14, color: Colors.grey[400]),
                  suffixIcon: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2937),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.search,
                        color: Colors.white, size: 18),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: Color(0xFF2E7D32), width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
                onChanged: (v) =>
                    setState(() => _productSearchQuery = v),
              ),

              const SizedBox(height: 12),

              // Kategori chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((cat) {
                    final isSel = _selectedCategory == cat;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedCategory = cat),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSel
                              ? const Color(0xFF2E7D32)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isSel
                                ? Colors.white
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Error produk
              if (_productError)
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: Text(
                    'Pilih produk yang akan diberi promo.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),

              const SizedBox(height: 8),

              // Grid produk
              _loadingProducts
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(
                            color: Color(0xFF2E7D32)),
                      ),
                    )
                  : _filteredProducts.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text('No products found',
                                style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 13)),
                          ),
                        )
                      : GridView.builder(
                          shrinkWrap: true,
                          physics:
                              const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.82,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (ctx, i) {
                            final p = _filteredProducts[i];
                            final isSel = _selectedProductIds
                                .contains(p['id']);
                            final imageUrl =
                                (p['imageUrl'] as String?) ?? '';
                            final imageUrls =
                                (p['imageUrls'] as List?) ?? [];
                            final displayImage = imageUrl.isNotEmpty
                                ? imageUrl
                                : (imageUrls.isNotEmpty
                                    ? imageUrls[0].toString()
                                    : '');

                            return GestureDetector(
                              onTap: () => setState(() {
                                if (isSel) {
                                  _selectedProductIds
                                      .remove(p['id']);
                                } else {
                                  _selectedProductIds.add(p['id']);
                                }
                                if (_productError &&
                                    _selectedProductIds.isNotEmpty) {
                                  _productError = false;
                                  _showTopWarning = false;
                                }
                              }),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _productError
                                        ? Colors.red.shade300
                                        : (isSel
                                            ? const Color(0xFF2E7D32)
                                            : const Color(
                                                0xFFE5E7EB)),
                                    width:
                                        (_productError || isSel)
                                            ? 1.5
                                            : 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Stack(
                                        children: [
                                          Container(
                                            width: double.infinity,
                                            decoration:
                                                const BoxDecoration(
                                              color: Color(0xFFF3F4F6),
                                              borderRadius:
                                                  BorderRadius.vertical(
                                                      top: Radius
                                                          .circular(
                                                              12)),
                                            ),
                                            child: displayImage
                                                    .isNotEmpty
                                                ? ClipRRect(
                                                    borderRadius:
                                                        const BorderRadius
                                                            .vertical(
                                                            top: Radius
                                                                .circular(
                                                                    12)),
                                                    child:
                                                        Image.network(
                                                      displayImage,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (_,
                                                              __,
                                                              ___) =>
                                                          const Center(
                                                        child: Icon(
                                                            Icons
                                                                .image_outlined,
                                                            color: Color(
                                                                0xFF9CA3AF),
                                                            size: 36),
                                                      ),
                                                    ),
                                                  )
                                                : const Center(
                                                    child: Icon(
                                                        Icons
                                                            .image_outlined,
                                                        color: Color(
                                                            0xFF9CA3AF),
                                                        size: 36),
                                                  ),
                                          ),
                                          Positioned(
                                            top: 8,
                                            left: 8,
                                            child: Container(
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                color: isSel
                                                    ? const Color(
                                                        0xFF2E7D32)
                                                    : Colors.white,
                                                borderRadius:
                                                    BorderRadius
                                                        .circular(4),
                                                border: Border.all(
                                                  color: _productError
                                                      ? Colors.red
                                                      : (isSel
                                                          ? const Color(
                                                              0xFF2E7D32)
                                                          : const Color(
                                                              0xFFD1D5DB)),
                                                ),
                                              ),
                                              child: isSel
                                                  ? const Icon(
                                                      Icons.check,
                                                      size: 14,
                                                      color:
                                                          Colors.white)
                                                  : null,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p['name'] ?? '',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight:
                                                  FontWeight.w600,
                                              color: Color(0xFF1F2937),
                                            ),
                                            maxLines: 1,
                                            overflow:
                                                TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _formatPrice(p['price']),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF6B7280),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ],

            const SizedBox(height: 28),

            // ── Tombol Aksi ───────────────────────────────────
            if (!isEditing)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _savePromotion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Create Promotion',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed:
                            _isLoading ? null : _savePromotion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2))
                            : const Text('Update Promotion',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed:
                            _isLoading ? null : _deletePromotion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFFF3F4F6),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('Delete Promotion',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF374151))),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ── Helper Widgets ────────────────────────────────────────
  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F2937),
        ),
      );

  Widget _errorText(String msg) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          msg,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.red,
            fontWeight: FontWeight.w400,
          ),
        ),
      );

  Widget _datePicker(
    String label,
    DateTime date,
    VoidCallback onTap, {
    bool hasError = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: Color(0xFF6B7280))),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasError ? Colors.red : const Color(0xFFE5E7EB),
                width: hasError ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                    child: Text(_formatDate(date),
                        style: const TextStyle(fontSize: 14))),
                Icon(Icons.calendar_today_outlined,
                    size: 16,
                    color: hasError
                        ? Colors.red
                        : const Color(0xFF9CA3AF)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _timePicker(
    String label,
    TimeOfDay time,
    VoidCallback onTap, {
    bool hasError = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: Color(0xFF6B7280))),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasError ? Colors.red : const Color(0xFFE5E7EB),
                width: hasError ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                    child: Text(_formatTimeDisplay(time),
                        style: const TextStyle(fontSize: 14))),
                Icon(Icons.access_time_rounded,
                    size: 16,
                    color: hasError
                        ? Colors.red
                        : const Color(0xFF9CA3AF)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDeco(String hint,
          {bool hasError = false}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
            fontSize: 14, color: Color(0xFFD1D5DB)),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
              color: hasError ? Colors.red : const Color(0xFFE5E7EB),
              width: hasError ? 1.5 : 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
              color: hasError ? Colors.red : const Color(0xFFE5E7EB),
              width: hasError ? 1.5 : 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
              color: hasError ? Colors.red : const Color(0xFF2E7D32),
              width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );
}