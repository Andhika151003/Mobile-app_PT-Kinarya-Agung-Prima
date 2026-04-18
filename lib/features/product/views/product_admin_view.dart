import 'package:flutter/material.dart';
import '../models/product.dart';
import '../controllers/product_admin_controller.dart';
import 'product_detail_admin_view.dart';
import '../../authentication/views/profile_admin_view.dart';
import 'form_add_product_admin_view.dart';

class ProductAdminView extends StatefulWidget {
  const ProductAdminView({super.key});

  @override
  State<ProductAdminView> createState() => _ProductAdminViewState();
}

class _ProductAdminViewState extends State<ProductAdminView> {
  final AdminProductController _productController = AdminProductController();
  final Color primaryGreen = const Color(0xFF00903D);

  String _selectedCategory = 'All';
  String _sortBy = 'Best Selling';
  bool _filterInStock = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryGreen,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FormAddProductAdminView()),
          );
        },
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 25),
              
              const Text('Products', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 16),
              
              _buildSearchBar(),
              const SizedBox(height: 16),
              
              _buildFilterRow(),
              const SizedBox(height: 24),
              
              _buildSectionHeader('Popular Products', 'See All'),
              const SizedBox(height: 16),
              
              _buildProductStream(),
              
              const SizedBox(height: 30),
              
              const Text('Categories', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 16),
              
              _buildCategoriesRow(),
              const SizedBox(height: 80), 
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET SECTIONS ---

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Image.asset('assets/images/logo.png', height: 35),
        IconButton(
              icon: const Icon(Icons.person_outline, color: Colors.black87),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileAdminView(), 
                  ),
                );
              },
            ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search Products',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(6)),
            child: IconButton(
              icon: const Icon(Icons.search, color: Colors.white, size: 20),
              onPressed: () => setState(() {}),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = 'All'; 
              });
            },
            child: Text(
              'All Categories', 
              style: TextStyle(
                fontSize: 13, 
                color: _selectedCategory == 'All' ? primaryGreen : Colors.black87, 
                fontWeight: _selectedCategory == 'All' ? FontWeight.bold : FontWeight.normal
              ),
            ),
          ),
          
          GestureDetector(
            onTap: () => setState(() => _filterInStock = !_filterInStock),
            child: Text('In Stock', style: TextStyle(
              fontSize: 13, 
              color: _filterInStock ? primaryGreen : Colors.black87,
              fontWeight: _filterInStock ? FontWeight.bold : FontWeight.normal
            )),
          ),
          
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _sortBy,
              icon: const Icon(Icons.arrow_drop_down, size: 20),
              isDense: true,
              style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.bold),
              items: ['Best Selling', 'Name A-Z', 'Stock Low-High'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  setState(() {
                    _sortBy = newValue;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String actionText) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
        Text(actionText, style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _buildProductStream() {
    return StreamBuilder<List<ProductModel>>(
      stream: _productController.getSupplyProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: primaryGreen));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text('No products available.\nTap + to add.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500)),
            ),
          );
        }

        final allProducts = snapshot.data!;
        
        // DIDELEGASIKAN KE CONTROLLER!
        final products = _productController.filterAndSortProducts(
          allProducts, 
          _selectedCategory, 
          _searchController.text, 
          _filterInStock, 
          _sortBy
        );

        // Jika hasil filter kosong
        if (products.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0),
              child: Text(
                'No products match your filters.', 
                style: TextStyle(color: Colors.grey.shade500)
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true, 
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          itemBuilder: (context, index) {
            return _buildProductCard(context, products[index]);
          },
        );
      },
    );
  }

  Widget _buildProductCard(BuildContext context, ProductModel product) {
    int alertLevel = (product.lowStockAlert != null && product.lowStockAlert! > 0) ? product.lowStockAlert! : 5;
    bool isInStock = product.stock > alertLevel;
    
    String displaySku = (product.sku != null && product.sku!.isNotEmpty) ? product.sku! : 'No SKU';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProductDetailAdminView(product: product)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // GAMBAR PRODUK
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                image: product.imageUrl.isNotEmpty
                    ? DecorationImage(image: NetworkImage(product.imageUrl), fit: BoxFit.contain)
                    : null,
              ),
              child: product.imageUrl.isEmpty ? const Icon(Icons.image_not_supported, color: Colors.grey) : null,
            ),
            const SizedBox(width: 16),
            
            // DETAIL TEKS
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black),
                  ),
                  const SizedBox(height: 4),
                  Text('SKU: $displaySku', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text('Stock: ${product.stock}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  const SizedBox(height: 12),
                  
                  // BADGE STATUS 
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isInStock ? Colors.green.shade100 : Colors.yellow.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isInStock ? 'In Stock' : 'Low Stock',
                      style: TextStyle(
                        color: isInStock ? primaryGreen : Colors.orange.shade700,
                        fontSize: 11, fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // HARGA & TOMBOL KANAN
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Rp ${product.price}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                    ),
                    Text('Per item', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 25), 
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AddStockDialog(product: product),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: primaryGreen, borderRadius: BorderRadius.circular(6)),
                    child: const Row(
                      children: [
                        Icon(Icons.add, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text('Add', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
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

  Widget _buildCategoriesRow() {
    final categories = [
      {'icon': Icons.face_retouching_natural, 'label': 'Beauty Care'},
      {'icon': Icons.pets, 'label': 'Pet Care'},
      {'icon': Icons.health_and_safety_outlined, 'label': 'Health'},
      {'icon': Icons.fastfood_outlined, 'label': 'Foods'},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: categories.map((cat) {
        bool isSelected = _selectedCategory == cat['label'];

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedCategory = isSelected ? 'All' : cat['label'] as String;
            });
          },
          child: Container(
            width: 75,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: isSelected ? primaryGreen : Colors.grey.shade200),
              borderRadius: BorderRadius.circular(12),
              color: isSelected ? primaryGreen.withValues(alpha: 0.05) : Colors.white,
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryGreen.withValues(alpha: 0.2) : Colors.grey.shade200, 
                    shape: BoxShape.circle
                  ),
                  child: Icon(
                    cat['icon'] as IconData, 
                    color: isSelected ? primaryGreen : Colors.grey.shade600, 
                    size: 20
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  cat['label'] as String, 
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11, 
                    color: isSelected ? primaryGreen : Colors.grey.shade600,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  )
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ==============================================================
// POPUP ADD STOCK
// ==============================================================

class AddStockDialog extends StatefulWidget {
  final ProductModel product;

  const AddStockDialog({super.key, required this.product});

  @override
  State<AddStockDialog> createState() => _AddStockDialogState();
}

class _AddStockDialogState extends State<AddStockDialog> {
  int _quantity = 1;
  bool _isLoading = false;
  final Color primaryGreen = const Color(0xFF4C7D3E);

  void _increment() => setState(() => _quantity++);
  void _decrement() {
    if (_quantity > 1) setState(() => _quantity--);
  }

  Future<void> _saveStock() async {
    setState(() => _isLoading = true);
    try {
      ProductModel updatedProduct = widget.product;
      updatedProduct.stock = updatedProduct.stock + _quantity;

      await AdminProductController().updateSupplyProduct(updatedProduct);

      if (mounted) {
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Berhasil menambah $_quantity stok untuk ${widget.product.name}'), backgroundColor: primaryGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menambah stok: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 3. TAMPILKAN SKU ASLI DI DALAM POP-UP
    String displaySku = (widget.product.sku != null && widget.product.sku!.isNotEmpty) ? widget.product.sku! : 'No SKU';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Add Stock', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                    child: const Icon(Icons.close, size: 16, color: Colors.black54),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
            const SizedBox(height: 16),

            Row(
              children: [
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200),
                    image: widget.product.imageUrl.isNotEmpty ? DecorationImage(image: NetworkImage(widget.product.imageUrl), fit: BoxFit.contain) : null,
                  ),
                  child: widget.product.imageUrl.isEmpty ? const Icon(Icons.image_not_supported, color: Colors.grey) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('SKU: $displaySku', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                      Text('Stok saat ini: ${widget.product.stock} pcs', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
            const SizedBox(height: 16),

            Text('Jumlah yang ingin ditambahkan:', style: TextStyle(fontSize: 13, color: Colors.grey.shade800)),
            const SizedBox(height: 12),
            Container(
              height: 36,
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(6)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(onTap: _decrement, child: Container(width: 36, alignment: Alignment.center, child: const Text('-', style: TextStyle(fontSize: 18)))),
                  VerticalDivider(width: 1, thickness: 1, color: Colors.grey.shade300),
                  Container(width: 50, alignment: Alignment.center, child: Text('$_quantity', style: const TextStyle(fontWeight: FontWeight.bold))),
                  VerticalDivider(width: 1, thickness: 1, color: Colors.grey.shade300),
                  InkWell(onTap: _increment, child: Container(width: 36, alignment: Alignment.center, child: const Text('+', style: TextStyle(fontSize: 16)))),
                ],
              ),
            ),
            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    side: BorderSide(color: Colors.grey.shade400),
                  ),
                  child: const Text('Cancel', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveStock,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}