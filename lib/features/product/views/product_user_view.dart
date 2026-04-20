import 'package:flutter/material.dart';
import '../models/product.dart';
import '../controllers/product_admin_controller.dart';
import '../controllers/product_user_controller.dart';
import 'product_detail_user_view.dart';
import '../../cart/controllers/cart_controller.dart';
import '../../cart/views/cart_view.dart';

class ProductUserView extends StatefulWidget {
  const ProductUserView({super.key});

  @override
  State<ProductUserView> createState() => _ProductUserViewState();
}

class _ProductUserViewState extends State<ProductUserView> {
  final AdminProductController _productController = AdminProductController();
  final CartController _cartController = CartController();
  
  final Color primaryGreen = const Color(0xFF00903D);
  String _selectedCategory = 'All Products';
  String _sortBy = 'Name A-Z';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'All Products',
    'Beauty Care',
    'Pet Care',
    'Health',
    'Foods',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 20),
              
              const Text(
                'Product Catalog',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 16),
              
              _buildSearchBar(),
              const SizedBox(height: 16),
              
              _buildCategoryTabs(),
              const SizedBox(height: 20),
              
              _buildSortDropdown(),
              const SizedBox(height: 8),

              _buildProductGridStream(),
              
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Image.asset(
          'assets/images/logo.png',   
          height: 35,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.eco, color: Colors.green, size: 35),
        ),
        IconButton(
          icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black87, size: 26),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CartView()),
            );
          },
        )
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
              onChanged: (value) {
                setState(() {});
              },
              decoration: const InputDecoration(
                hintText: 'Search Catalog',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(6),
            ),
            child: IconButton(
              icon: const Icon(Icons.search, color: Colors.white, size: 20),
              onPressed: () {
                setState(() {});
              },
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((category) {
          bool isSelected = _selectedCategory == category;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 20),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? Colors.black : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                category,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.black : Colors.grey.shade600,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProductGridStream() {
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
              padding: const EdgeInsets.all(40.0),
              child: Text(
                'Catalog is currently empty.', 
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ),
          );
        }

        final allProducts = snapshot.data!;
        final displayProducts = ProductUserController().filterAndSortProducts(
          allProducts, 
          _selectedCategory, 
          _searchController.text, 
          _sortBy
        );

        if (displayProducts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Text('No products match your search/filter.', style: TextStyle(color: Colors.grey.shade500)),
            ),
          );
        }

        // --- GRID VIEW ---
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.65,
          ),
          itemCount: displayProducts.length,
          itemBuilder: (context, index) {
            return _buildProductCard(context, displayProducts[index]);
          },
        );
      },
    );
  }

  Widget _buildProductCard(BuildContext context, ProductModel product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProductDetailUserView(product: product)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Gambar Produk
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  color: Colors.white,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: product.imageUrl.isNotEmpty
                      ? Image.network(product.imageUrl, fit: BoxFit.contain)
                      : Icon(Icons.image_outlined, size: 50, color: Colors.grey.shade300),
                ),
              ),
            ),
            
            // 2. Teks Info Produk
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, height: 1.2),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Min. Order: ${product.moq ?? 1} pcs',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Sisa stok: ${product.stock}',
                          style: TextStyle(color: product.stock < 10 ? Colors.red : Colors.grey.shade600, fontSize: 11),
                        ),
                      ],
                    ),
                    
                    // Harga & Tombol Keranjang
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rp ${product.price}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            int currentStock = product.stock; 
                            int moq = product.moq ?? 1;

                            int qtyInCart = 0;
                            try {
                              final existingItem = _cartController.items.firstWhere((item) => item.id == product.id!);
                              qtyInCart = existingItem.quantity;
                            } catch (e) {
                              qtyInCart = 0;
                            }

                            if (currentStock < moq) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Maaf, stok ${product.name} tidak mencukupi. Sisa stok: $currentStock'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            if ((qtyInCart + moq) > currentStock) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Stok terbatas! Anda sudah memiliki $qtyInCart di keranjang (Sisa stok di gudang: $currentStock)'),
                                  backgroundColor: Colors.orange.shade700,
                                ),
                              );
                              return;
                            }

                            double finalPrice = product.price.toDouble();

                            _cartController.addToCart(
                              id: product.id!,
                              title: product.name,
                              variant: product.category,
                              price: finalPrice,
                              imageUrl: product.imageUrl,
                              quantity: moq,
                              minOrder: moq,
                              stockLimit: currentStock,
                            );

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${product.name} dimasukkan ke keranjang!'),
                                backgroundColor: primaryGreen, 
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: const Icon(Icons.add_shopping_cart, size: 20, color: Colors.black54),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortDropdown() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Sort by:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _sortBy,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
              isDense: true,
              style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500),
              items: ['Name A-Z', 'Price Low-High', 'Price High-Low']
                  .map((String value) {
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
        ),
      ],
    );
  }
}