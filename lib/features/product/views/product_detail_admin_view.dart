import 'package:flutter/material.dart';
import '../models/product.dart';
import '../controllers/product_admin_controller.dart';
import '../views/form_edit_product_admin_view.dart';

class ProductDetailAdminView extends StatefulWidget {
  final ProductModel product;

  const ProductDetailAdminView({super.key, required this.product});

  @override
  State<ProductDetailAdminView> createState() => _ProductDetailAdminViewState();
}

class _ProductDetailAdminViewState extends State<ProductDetailAdminView> {
  final AdminProductController _productController = AdminProductController();
  late ProductModel _currentProduct;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentProduct = widget.product; 
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSection(),
            const Divider(color: Color(0xFFF5F5F5), thickness: 8), 
            
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitleAndBadge(),
                  const SizedBox(height: 8),
                  Text(
                    'SKU: ${_currentProduct.sku ?? "N/A"}',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  

                  _buildInfoRow('Regular Price', 'Rp ${_currentProduct.price}'),
                  const SizedBox(height: 16),
                  _buildInfoRow('MOQ (Min. Order)', '${_currentProduct.moq ?? 1} units'),
                  const SizedBox(height: 16),
                  _buildInfoRow('Stock Available', '${_currentProduct.stock} units'),
                ],
              ),
            ),
            const Divider(color: Color(0xFFF5F5F5), thickness: 8),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Product Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                  const SizedBox(height: 16),
                  _buildDetailIconRow(Icons.category_outlined, 'Category:', _currentProduct.category),
                  const SizedBox(height: 12),
                  _buildDetailIconRow(Icons.domain_outlined, 'Brand:', _currentProduct.brand ?? 'No Brand'), 
                ],
              ),
            ),
            const Divider(color: Color(0xFFF5F5F5), thickness: 8),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Shipping Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                  const SizedBox(height: 16),
                  _buildDetailIconRow(Icons.monitor_weight_outlined, 'Weight:', '${_currentProduct.weight ?? 0} kg'),
                  const SizedBox(height: 12),
                  _buildDetailIconRow(
                    Icons.straighten_outlined, 
                    'Dimensions:', 
                    '${_currentProduct.length ?? 0}L x ${_currentProduct.width ?? 0}W x ${_currentProduct.height ?? 0}H cm'
                  ), 
                ],
              ),
            ),
            const Divider(color: Color(0xFFF5F5F5), thickness: 8),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                  const SizedBox(height: 12),
                  Text(
                    _currentProduct.description,
                    style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.5),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFFF5F5F5), thickness: 8),

            // --- PERFORMANCE STATS ---
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Performance Stats',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'Monthly Sales',
                          value: '${_currentProduct.monthlySales ?? 0}',
                          // Mengambil nilai tren dari model, default 0.0 jika null
                          percentage: _currentProduct.monthlySalesTrend ?? 0.0, 
                          titleColor: Colors.blue.shade600,
                          bgColor: const Color(0xFFF0F6FF),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Revenue',
                          value: _productController.formatRevenue(_currentProduct.revenue ?? 0),
                          // Mengambil nilai tren dari model, default 0.0 jika null
                          percentage: _currentProduct.revenueTrend ?? 0.0, 
                          titleColor: Colors.purple.shade400,
                          bgColor: const Color(0xFFF7F0FF),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
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
      centerTitle: false,
      titleSpacing: 0,
      leading: Center(
        child: Container(
          margin: const EdgeInsets.only(left: 16),
          decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      title: const Text('Product Details', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 22),
          onPressed: () async {
            final updatedData = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => FormEditProductAdminView(product: _currentProduct)),
            );

            if (updatedData != null && updatedData is ProductModel) {
              setState(() {
                _currentProduct = updatedData; 
              });
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
          onPressed: () => _showDeleteDialog(context),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildImageSection() {
    List<String> allImages = [];
    if (_currentProduct.imageUrl.isNotEmpty) allImages.add(_currentProduct.imageUrl);
    if (_currentProduct.imageUrls != null) allImages.addAll(_currentProduct.imageUrls!);

    if (allImages.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40.0),
        child: Center(
          child: Icon(Icons.image_outlined, size: 80, color: Colors.grey),
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
                        ? const Color(0xFF4C7D3E)
                        : Colors.grey.shade300,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTitleAndBadge() {
    bool isInStock = _currentProduct.stock > 0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(_currentProduct.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isInStock ? Colors.green.shade100 : Colors.red.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            isInStock ? 'In Stock' : 'Out of Stock',
            style: TextStyle(color: isInStock ? const Color(0xFF458833) : Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
      ],
    );
  }

  Widget _buildDetailIconRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
        const SizedBox(width: 8),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 14, color: Colors.black87))),
      ],
    );
  }

  // --- TAMBAHAN WIDGET KOTAK STATS ---
  Widget _buildStatCard({
    required String title, 
    required String value, 
    required double percentage, 
    required Color titleColor, 
    required Color bgColor
  }) {
    final bool isPositive = percentage >= 0;
    final Color trendColor = isPositive ? const Color(0xFF4C7D3E) : Colors.red;
    final IconData trendIcon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;
    final String percentageText = '${percentage.abs().toStringAsFixed(1)}%';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: titleColor, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(trendIcon, color: trendColor, size: 14),
              const SizedBox(width: 4),
              Text(
                percentageText, 
                style: TextStyle(color: trendColor, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    final Color primaryGreen = const Color(0xFF4C7D3E); 

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          elevation: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 32),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFEAEFE9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline, color: Colors.red, size: 28),
              ),
              const SizedBox(height: 20),
              
              const Text(
                'Delete Product',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 12),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'This product will be permanently\nremoved from your inventory.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500, height: 1.4),
                ),
              ),
              const SizedBox(height: 24),
              
              Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
              
              InkWell(
                onTap: () => Navigator.pop(dialogContext),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.center,
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
              
              Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
              
              InkWell(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                onTap: () async {
                  Navigator.pop(dialogContext);
                  
                  try {
                    await _productController.deleteSupplyProduct(_currentProduct);
                    
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Product deleted successfully'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.center,
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}