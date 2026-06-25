import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/product_admin_controller.dart';

class FormAddProductAdminView extends StatefulWidget {
  const FormAddProductAdminView({super.key});

  @override
  State<FormAddProductAdminView> createState() =>
      _FormAddProductAdminViewState();
}

class _FormAddProductAdminViewState extends State<FormAddProductAdminView> {
  final _formKey = GlobalKey<FormState>();
  final Color primaryGreen = const Color(0xFF00903D);



  // --- CONTROLLERS ---
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _skuController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _regularPriceController = TextEditingController();

  final TextEditingController _moqController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _lowStockController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _lengthController = TextEditingController();
  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  // --- DROPDOWN VARIABLE ---
  String? _selectedCategory;
  final List<String> _categories = [
    'Beauty Care',
    'Pet Care',
    'Health',
    'Foods',
  ];

  // --- IMAGE VARIABLE ---
  final List<File> _selectedImages = [];

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        for (var img in images) {
          if (_selectedImages.length < 8) {
            _selectedImages.add(File(img.path));
          }
        }
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _brandController.dispose();
    _regularPriceController.dispose();

    _moqController.dispose();
    _stockController.dispose();
    _lowStockController.dispose();
    _descriptionController.dispose();
    _weightController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  final AdminProductController _productController = AdminProductController();



  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap pilih kategori!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validasi gambar opsional: uncomment jika gambar wajib diisi
    // if (_uploadedImageUrl == null) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('Please upload a product image!'), backgroundColor: Colors.red),
    //   );
    //   return;
    // }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF00903D)),
      ),
    );

    try {
      await _productController.createProductFromUI(
        name: _nameController.text,
        sku: _skuController.text,
        category: _selectedCategory!,
        brand: _brandController.text,
        regularPrice: _regularPriceController.text,

        moq: _moqController.text,
        stock: _stockController.text,
        lowStock: _lowStockController.text,
        description: _descriptionController.text,
        weight: _weightController.text,
        length: _lengthController.text,
        width: _widthController.text,
        height: _heightController.text,
        imageFiles: _selectedImages,
      );

      if (mounted) {
        Navigator.pop(context);
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_nameController.text} berhasil ditambahkan!'),
            backgroundColor: primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menambahkan produk: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. PRODUCT IMAGE SECTION
              _buildSectionTitle('Gambar Produk'),
              const SizedBox(height: 12),
              _buildImageUploadSection(),
              const SizedBox(height: 8),
              Text(
                'Tambahkan hingga 8 foto. Foto pertama akan menjadi gambar sampul.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
              const SizedBox(height: 24),
              Divider(color: Colors.grey.shade200),
              const SizedBox(height: 24),

              // 2. BASIC INFORMATION
              _buildSectionTitle('Informasi Dasar'),
              const SizedBox(height: 16),
              _buildTextFieldLabel('Nama Produk'),
              _buildTextField(
                keyField: const Key('add_product_name_field'),
                controller: _nameController,
                hint: 'e.g. Vaseline Hand Body Lotion Healthy White 400ml',
              ),
              _buildTextFieldLabel('SKU'),
              _buildTextField(
                keyField: const Key('add_product_sku_field'),
                controller: _skuController,
                hint: 'e.g. PRD-1003',
                isRequired: true,
                maxLength: 50,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\-]'))],
              ),
              _buildTextFieldLabel('Kategori'),
              _buildCategoryDropdown(),
              _buildTextFieldLabel('Merek'),
              _buildTextField(
                keyField: const Key('add_product_brand_field'),
                controller: _brandController,
                hint: 'misal. Vaseline',
                isRequired: false,
              ),
              const SizedBox(height: 24),

              // 3. PRICING
              _buildSectionTitle('Harga'),
              const SizedBox(height: 16),
              _buildTextFieldLabel('Harga Reguler'),
              _buildTextField(
                keyField: const Key('add_product_price_field'),
                controller: _regularPriceController,
                prefixText: 'Rp ',
                isNumber: true,
                isDecimal: false,
                maxLength: 11,
                hint: '85000',
              ),

              _buildTextFieldLabel('Jumlah Pesanan Minimum'),
              _buildTextField(
                keyField: const Key('add_product_moq_field'),
                controller: _moqController,
                isNumber: true,
                isDecimal: false,
                maxLength: 6,
                hint: '10',
                isRequired: true,
                customValidator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '* Wajib diisi';
                  }
                  final intValue = int.tryParse(value);
                  if (intValue == null || intValue < 1) {
                    return 'Min. Pesanan minimal 1';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // 4. INVENTORY
              _buildSectionTitle('Inventaris'),
              const SizedBox(height: 16),
              _buildTextFieldLabel('Jumlah Stok'),
              _buildTextField(
                keyField: const Key('add_product_stock_field'),
                controller: _stockController,
                isNumber: true,
                isDecimal: false,
                maxLength: 6,
                hint: '1000',
              ),
              _buildTextFieldLabel('Peringatan Stok Menipis'),
              _buildTextField(
                keyField: const Key('add_product_low_stock_field'),
                controller: _lowStockController,
                isNumber: true,
                isDecimal: false,
                maxLength: 6,
                hint: '100',
                isRequired: false,
              ),
              const SizedBox(height: 24),

              // 5. SPECIFICATIONS
              _buildSectionTitle('Spesifikasi'),
              const SizedBox(height: 16),
              _buildTextFieldLabel('Deskripsi'),
              _buildTextField(
                keyField: const Key('add_product_desc_field'),
                controller: _descriptionController,
                maxLines: 4,
                maxLength: 2000,
                hint: 'Masukkan deskripsi produk...',
              ),
              const SizedBox(height: 24),

              // 6. SHIPPING
              _buildSectionTitle('Pengiriman'),
              const SizedBox(height: 16),
              _buildTextFieldLabel('Berat (kg)'),
              _buildTextField(
                keyField: const Key('add_product_weight_field'),
                controller: _weightController,
                isNumber: true,
                isDecimal: true,
                maxLength: 6,
                hint: '4.00',
                isRequired: false,
              ),
              _buildTextFieldLabel('Dimensi (cm)'),
              _buildDimensionsRow(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: Center(
        child: Container(
          margin: const EdgeInsets.only(left: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 16,
              color: Colors.black87,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      title: const Text(
        'Tambah Produk Baru',
        style: TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0, top: 12, bottom: 12),
          child: ElevatedButton(
            key: const Key('add_product_save_btn'),
            onPressed: _saveProduct,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: const Text(
              'Simpan',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }

  Widget _buildTextFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    Key? keyField,
    String? hint,
    String? prefixText,
    String? suffixText,
    bool isNumber = false,
    bool isDecimal = false, 
    int maxLines = 1,
    bool isRequired = true,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? customValidator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
    child: TextFormField(
      key: keyField,
      controller: controller,
      maxLength: maxLength,
      keyboardType: isNumber
          ? TextInputType.numberWithOptions(decimal: isDecimal)
          : TextInputType.text,
      inputFormatters: inputFormatters ?? (isNumber 
          ? (isDecimal 
              ? [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))] 
              : [FilteringTextInputFormatter.digitsOnly]) 
          : null),
      maxLines: maxLines,
        validator: customValidator ?? (value) {
          if (isRequired && (value == null || value.trim().isEmpty)) {
            return '* Wajib diisi';
          }
          return null;
        },
        style: const TextStyle(fontSize: 14, color: Colors.black87),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixText: prefixText,
          prefixStyle: const TextStyle(color: Colors.black54, fontSize: 14),
          suffixText: suffixText,
          suffixStyle: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: primaryGreen),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        key: const Key('add_product_category_dropdown'),
        initialValue: _selectedCategory,
        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: primaryGreen),
          ),
        ),
        hint: Text(
          'Pilih Kategori',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        ),
        items: _categories.map((String category) {
          return DropdownMenuItem<String>(
            value: category,
            child: Text(
              category,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _selectedCategory = newValue;
          });
        },
        validator: (value) => value == null ? '* Kategori wajib diisi' : null,
      ),
    );
  }

  Widget _buildDimensionsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildTextField(
            keyField: const Key('add_product_length_field'),
            controller: _lengthController,
            isNumber: true,
            hint: '100',
            suffixText: 'L',
            isRequired: false,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTextField(
            keyField: const Key('add_product_width_field'),
            controller: _widthController,
            isNumber: true,
            hint: '92',
            suffixText: 'W',
            isRequired: false,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTextField(
            keyField: const Key('add_product_height_field'),
            controller: _heightController,
            isNumber: true,
            hint: '85',
            suffixText: 'H',
            isRequired: false,
          ),
        ),
      ],
    );
  }

  Widget _buildImageUploadSection() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        if (_selectedImages.length < 8)
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300, width: 2), 
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: Colors.grey.shade400, size: 28),
                  const SizedBox(height: 4),
                  Text('Tambah Foto', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                ],
              ),
            ),
          ),
        ...List.generate(_selectedImages.length, (index) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: FileImage(_selectedImages[index]),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: -8,
                right: -8,
                child: GestureDetector(
                  onTap: () => _removeImage(index),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline, size: 14, color: Colors.black54),
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }
}
