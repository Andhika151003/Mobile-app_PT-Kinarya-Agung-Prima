import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../../cart/controllers/cart_controller.dart';

class ProductDetailUserView extends StatefulWidget {
  final ProductModel product;

  const ProductDetailUserView({super.key, required this.product});

  @override
  State<ProductDetailUserView> createState() => _ProductDetailUserViewState();
}

class _ProductDetailUserViewState extends State<ProductDetailUserView> {
  late int _quantity;
  int _currentImageIndex = 0;
  final Color primaryGreen = const Color(0xFF4C7D3E);
  final Color priceGreen = const Color(0xFF1E8F29);

  final CartController _cartController = CartController();

  @override
  void initState() {
    super.initState();
    int moq = widget.product.moq ?? 1;
    int stock = widget.product.stock;

    _quantity = moq > stock ? stock : moq;
    if (_quantity < 0) _quantity = 0;
  }

  void _increment() {
    int stock = widget.product.stock;

    if (_quantity < stock) {
      setState(() => _quantity++);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maksimal stok yang tersedia adalah $stock pcs'),
          backgroundColor: Colors.orange.shade700,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _decrement() {
    int minOrder = widget.product.moq ?? 1;
    if (_quantity > minOrder) {
      setState(() => _quantity--);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Minimum order is $minOrder pcs'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    String displaySku =
        (widget.product.sku != null && widget.product.sku!.isNotEmpty)
        ? widget.product.sku!
        : 'N/A';
    int displayPrice =
        widget.product.wholesalePrice != null &&
            widget.product.wholesalePrice! > 0
        ? widget.product.wholesalePrice!
        : widget.product.price;

    int currentStock = widget.product.stock;
    int moq = widget.product.moq ?? 1;

    bool isOutOfStock = currentStock < moq;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: ElevatedButton(
            onPressed: isOutOfStock
                ? null
                : () {
                    int qtyInCart = 0;
                    try {
                      final existingItem = _cartController.items.firstWhere(
                        (item) => item.id == widget.product.id,
                      );
                      qtyInCart = existingItem.quantity;
                    } catch (e) {
                      qtyInCart = 0;
                    }

                    if ((qtyInCart + _quantity) > currentStock) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Stok terbatas! Anda sudah memiliki $qtyInCart di keranjang (Sisa stok gudang: $currentStock)',
                          ),
                          backgroundColor: Colors.orange.shade700,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                      return;
                    }

                    double finalPrice =
                        (widget.product.wholesalePrice != null &&
                            widget.product.wholesalePrice! > 0)
                        ? widget.product.wholesalePrice!.toDouble()
                        : widget.product.price.toDouble();

                    _cartController.addToCart(
                      id: widget.product.id!,
                      title: widget.product.name,
                      variant: 'Default',
                      price: finalPrice,
                      imageUrl: widget.product.imageUrl,
                      quantity: _quantity,
                      minOrder: widget.product.moq ?? 1,
                      stockLimit: currentStock,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '$_quantity ${widget.product.name} added to cart!',
                        ),
                        backgroundColor: primaryGreen,
                      ),
                    );
                    Navigator.pop(context);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              disabledBackgroundColor: Colors.grey.shade300,
              elevation: 0,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              isOutOfStock ? 'Out of Stock' : 'Add to Cart',
              style: TextStyle(
                color: isOutOfStock ? Colors.grey.shade600 : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. GAMBAR PRODUK
            _buildImageSection(),
            const SizedBox(height: 16),

            // 2. NAMA & SKU
            Text(
              widget.product.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'SKU: $displaySku',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
            const SizedBox(height: 20),

            // 3. HARGA & COUNTER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.product.wholesalePrice != null &&
                        widget.product.wholesalePrice! > 0) ...[
                      Text(
                        'Retail: ${currencyFormatter.format(widget.product.price)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          currencyFormatter.format(displayPrice),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: priceGreen,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.product.wholesalePrice != null &&
                                  widget.product.wholesalePrice! > 0
                              ? 'Wholesale'
                              : 'per item',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                isOutOfStock ? const SizedBox.shrink() : _buildCounter(),
              ],
            ),
            const SizedBox(height: 24),

            // 4. DESKRIPSI
            _buildSectionTitle('Description'),
            const SizedBox(height: 8),
            Text(
              widget.product.description.isEmpty
                  ? 'No description available for this product.'
                  : widget.product.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // 5. PRODUCT INFORMATION
            _buildSectionTitle('Product Information'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard('Category', widget.product.category),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoCard(
                    'Brand',
                    widget.product.brand?.isNotEmpty == true
                        ? widget.product.brand!
                        : '-',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildInfoCard('Stock', '$currentStock pcs')),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoCard(
                    'Weight',
                    '${widget.product.weight ?? 0} kg',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    'Dimensions (LxWxH)',
                    '${widget.product.length ?? 0} x ${widget.product.width ?? 0} x ${widget.product.height ?? 0} cm',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 24,
      title: const Text(
        'Product Details',
        style: TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 20.0),
          child: Center(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.close, size: 20, color: Colors.black54),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    List<String> allImages = [];
    if (widget.product.imageUrl.isNotEmpty) {
      allImages.add(widget.product.imageUrl);
    }
    if (widget.product.imageUrls != null) {
      allImages.addAll(widget.product.imageUrls!);
    }

    if (allImages.isEmpty) {
      return Center(
        child: Container(
          height: 200,
          margin: const EdgeInsets.symmetric(vertical: 20),
          child: Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 250,
          width: double.infinity,
          child: PageView.builder(
            itemCount: allImages.length,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  image: DecorationImage(
                    image: NetworkImage(allImages[index]),
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),
        ),
        if (allImages.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                allImages.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  width: _currentImageIndex == index ? 10.0 : 8.0,
                  height: _currentImageIndex == index ? 10.0 : 8.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentImageIndex == index
                        ? primaryGreen
                        : Colors.grey.shade300,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCounter() {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: _decrement,
            child: Container(
              width: 32,
              alignment: Alignment.center,
              child: const Text(
                '-',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          VerticalDivider(width: 1, thickness: 1, color: Colors.grey.shade400),
          Container(
            width: 40,
            alignment: Alignment.center,
            child: Text(
              '$_quantity',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          VerticalDivider(width: 1, thickness: 1, color: Colors.grey.shade400),
          InkWell(
            onTap: _increment,
            child: Container(
              width: 32,
              alignment: Alignment.center,
              child: const Text(
                '+',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
