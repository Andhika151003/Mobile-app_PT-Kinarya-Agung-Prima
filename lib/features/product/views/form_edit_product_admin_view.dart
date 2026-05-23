import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product.dart';
import '../controllers/product_admin_controller.dart';

class FormEditProductAdminView extends StatefulWidget {
  final ProductModel product;

  const FormEditProductAdminView({super.key, required this.product});

  @override
  State<FormEditProductAdminView> createState() => _FormEditProductAdminViewState();
}

class _FormEditProductAdminViewState extends State<FormEditProductAdminView> {
  final _formKey = GlobalKey<FormState>();
  final Color primaryGreen = const Color(0xFF00903D);
  final AdminProductController _productController = AdminProductController();

  // --- CONTROLLERS ---
  late TextEditingController _nameController;
  late TextEditingController _skuController;
  late TextEditingController _brandController;
  late TextEditingController _regularPriceController;
  late TextEditingController _moqController;
  late TextEditingController _stockController;
  late TextEditingController _lowStockController;
  late TextEditingController _descriptionController;
  late TextEditingController _weightController;
  late TextEditingController _lengthController;
  late TextEditingController _widthController;
  late TextEditingController _heightController;

  String? _selectedCategory;
  final List<String> _categories = [
    'Beauty Care',
    'Pet Care',
    'Health',
    'Foods',
  ];

  // --- IMAGE VARIABLES ---
  List<String> _existingImages = [];
  final List<File> _newImages = [];

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        for (var img in images) {
          if ((_existingImages.length + _newImages.length) < 8) {
            _newImages.add(File(img.path));
          }
        }
      });
    }
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImages.removeAt(index);
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _skuController = TextEditingController(text: widget.product.sku ?? '');
    _brandController = TextEditingController(text: widget.product.brand ?? '');
    _regularPriceController = TextEditingController(text: widget.product.price.toString());
    _moqController = TextEditingController(text: widget.product.moq?.toString() ?? '1');
    _stockController = TextEditingController(text: widget.product.stock.toString());
    _lowStockController = TextEditingController(text: widget.product.lowStockAlert?.toString() ?? '');
    _descriptionController = TextEditingController(text: widget.product.description);
    _weightController = TextEditingController(text: widget.product.weight?.toString() ?? '');
    _lengthController = TextEditingController(text: widget.product.length?.toString() ?? '');
    _widthController = TextEditingController(text: widget.product.width?.toString() ?? '');
    _heightController = TextEditingController(text: widget.product.height?.toString() ?? '');

    if (_categories.contains(widget.product.category)) {
      _selectedCategory = widget.product.category;
    } else {
      _categories.add(widget.product.category);
      _selectedCategory = widget.product.category;
    }

    _existingImages = [];
    if (widget.product.imageUrl.isNotEmpty) _existingImages.add(widget.product.imageUrl);
    if (widget.product.imageUrls != null) _existingImages.addAll(widget.product.imageUrls!);
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

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category!'), backgroundColor: Colors.red),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF00903D))),
    );

    try {
      ProductModel updatedProduct = await _productController.updateProductFromUI(
        oldProduct: widget.product,
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
        keptImageUrls: _existingImages,
        newImageFiles: _newImages,
      );

      if (mounted) {
        Navigator.pop(context);
        Navigator.pop(context, updatedProduct);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_nameController.text} updated successfully!'), 
            backgroundColor: primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update product: $e'), backgroundColor: Colors.red),
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
              _buildSectionTitle('Product Image'),
              const SizedBox(height: 12),
              _buildImageUploadSection(),
              const SizedBox(height: 8),
              Text(
                'Update your photos (up to 8). First photo will be the cover image.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
              const SizedBox(height: 24),
              Divider(color: Colors.grey.shade200),
              const SizedBox(height: 24),

              // 2. BASIC INFORMATION
              _buildSectionTitle('Basic Information'),
              const SizedBox(height: 16),
              _buildTextFieldLabel('Product Name'),
              _buildTextField(
                controller: _nameController,
                hint: 'e.g. Vaseline Hand Body Lotion Healthy White 400ml',
              ),
              _buildTextFieldLabel('SKU'),
              _buildTextField(
                controller: _skuController,
                hint: 'e.g. PRD-1003',
                isRequired: false,
              ),
              _buildTextFieldLabel('Category'),
              _buildCategoryDropdown(),
              _buildTextFieldLabel('Brand'),
              _buildTextField(
                controller: _brandController,
                hint: 'e.g. Vaseline',
                isRequired: false,
              ),
              const SizedBox(height: 24),

              // 3. PRICING
              _buildSectionTitle('Pricing'),
              const SizedBox(height: 16),
              _buildTextFieldLabel('Regular Price'),
              _buildTextField(
                controller: _regularPriceController,
                prefixText: 'Rp ',
                isNumber: true,
                hint: '85000',
              ),
              _buildTextFieldLabel('Minimum Order Quantity'),
              _buildTextField(
                controller: _moqController,
                isNumber: true,
                hint: '10',
                isRequired: false,
              ),
              const SizedBox(height: 24),

              // 4. INVENTORY
              _buildSectionTitle('Inventory'),
              const SizedBox(height: 16),
              _buildTextFieldLabel('Stock Quantity'),
              _buildTextField(
                controller: _stockController,
                isNumber: true,
                hint: '1000',
              ),
              _buildTextFieldLabel('Low Stock Alert'),
              _buildTextField(
                controller: _lowStockController,
                isNumber: true,
                hint: '100',
                isRequired: false,
              ),
              const SizedBox(height: 24),

              // 5. SPECIFICATIONS
              _buildSectionTitle('Specifications'),
              const SizedBox(height: 16),
              _buildTextFieldLabel('Description'),
              _buildTextField(
                controller: _descriptionController,
                maxLines: 4,
                hint: 'Enter product description...',
              ),
              const SizedBox(height: 24),

              // 6. SHIPPING
              _buildSectionTitle('Shipping'),
              const SizedBox(height: 16),
              _buildTextFieldLabel('Weight (kg)'),
              _buildTextField(
                controller: _weightController,
                isNumber: true,
                hint: '4.00',
                isRequired: false,
              ),
              _buildTextFieldLabel('Dimensions (cm)'),
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
        'Edit Product',
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
            onPressed: _updateProduct,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: const Text(
              'Update',
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
    String? hint,
    String? prefixText,
    String? suffixText,
    bool isNumber = false,
    int maxLines = 1,
    bool isRequired = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        maxLines: maxLines,
        validator: (value) {
          if (isRequired && (value == null || value.trim().isEmpty)) {
            return '* Required';
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
          'Select Category',
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
        validator: (value) => value == null ? '* Category is required' : null,
      ),
    );
  }

  Widget _buildDimensionsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildTextField(
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
    int totalImages = _existingImages.length + _newImages.length;
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        if (totalImages < 8)
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
                  Text('Add Photo', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                ],
              ),
            ),
          ),
        ...List.generate(_existingImages.length, (index) {
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
                    image: NetworkImage(_existingImages[index]),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: -8,
                right: -8,
                child: GestureDetector(
                  onTap: () => _removeExistingImage(index),
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
        ...List.generate(_newImages.length, (index) {
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
                    image: FileImage(_newImages[index]),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: -8,
                right: -8,
                child: GestureDetector(
                  onTap: () => _removeNewImage(index),
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