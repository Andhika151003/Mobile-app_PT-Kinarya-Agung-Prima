import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product.dart';

class AdminProductController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final String supplyCollection = 'products'; 

  // =========================================================
  // MANAJEMEN BARANG DISTRIBUTOR (SUPPLY)
  // =========================================================

  Future<void> addSupplyProduct(ProductModel product) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Admin not logged in");

    product.retailerId = user.uid; 
    await _firestore.collection(supplyCollection).add(product.toMap());
  }

  Stream<List<ProductModel>> getSupplyProducts() {
    // Menampilkan semua barang distributor pusat
    return _firestore
        .collection(supplyCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> updateSupplyProduct(ProductModel product) async {
    if (product.id == null) return;
    Map<String, dynamic> updateData = product.toMap();
    updateData.remove('createdAt');
    updateData['updatedAt'] = FieldValue.serverTimestamp();

    await _firestore.collection(supplyCollection).doc(product.id).update(updateData);
  }

  Future<void> deleteSupplyProduct(String productId) async {
    await _firestore.collection(supplyCollection).doc(productId).delete();
  }

  // =========================================================
  // LOGIC & FILTERING UNTUK UI (MEMISAHKAN MVC)
  // =========================================================

  Future<void> createProductFromUI({
    required String name,
    required String sku,
    required String category,
    required String brand,
    required String regularPrice,
    required String wholesalePrice,
    required String moq,
    required String stock,
    required String lowStock,
    required String description,
    required String weight,
    required String length,
    required String width,
    required String height,
  }) async {
    final newProduct = ProductModel(
      retailerId: '', 
      name: name.trim(),
      sku: sku.trim(),
      category: category,
      brand: brand.trim(),
      price: int.tryParse(regularPrice.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
      wholesalePrice: int.tryParse(wholesalePrice.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
      moq: int.tryParse(moq) ?? 1,
      stock: int.tryParse(stock.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
      lowStockAlert: int.tryParse(lowStock) ?? 0,
      description: description.trim(),
      weight: double.tryParse(weight) ?? 0.0,
      length: double.tryParse(length) ?? 0.0,
      width: double.tryParse(width) ?? 0.0,
      height: double.tryParse(height) ?? 0.0,
      imageUrl: '', 
      imageUrls: [], 
      isAvailable: true,
    );
    await addSupplyProduct(newProduct);
  }

  Future<ProductModel> updateProductFromUI({
    required ProductModel oldProduct,
    required String name,
    required String sku,
    required String category,
    required String brand,
    required String regularPrice,
    required String wholesalePrice,
    required String moq,
    required String stock,
    required String lowStock,
    required String description,
    required String weight,
    required String length,
    required String width,
    required String height,
  }) async {
    ProductModel updatedProduct = ProductModel(
      id: oldProduct.id, 
      retailerId: oldProduct.retailerId, 
      name: name.trim(),
      sku: sku.trim(),
      category: category,
      brand: brand.trim(),
      price: int.tryParse(regularPrice.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
      wholesalePrice: int.tryParse(wholesalePrice.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
      moq: int.tryParse(moq) ?? 1,
      stock: int.tryParse(stock.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
      lowStockAlert: int.tryParse(lowStock) ?? 0,
      description: description.trim(),
      weight: double.tryParse(weight) ?? 0.0,
      length: double.tryParse(length) ?? 0.0,
      width: double.tryParse(width) ?? 0.0,
      height: double.tryParse(height) ?? 0.0,
      imageUrl: oldProduct.imageUrl, 
      imageUrls: oldProduct.imageUrls, 
      isAvailable: oldProduct.isAvailable,
    );
    await updateSupplyProduct(updatedProduct);
    return updatedProduct;
  }

  List<ProductModel> filterAndSortProducts(
    List<ProductModel> allProducts, 
    String category, 
    String query, 
    bool inStock, 
    String sortBy
  ) {
    var products = allProducts.where((p) {
      bool matchCategory = category == 'All' || p.category == category;
      bool matchSearch = query.isEmpty || 
          p.name.toLowerCase().contains(query.toLowerCase());
      
      bool matchStock = true;
      if (inStock) {
        int alertLevel = (p.lowStockAlert != null && p.lowStockAlert! > 0) ? p.lowStockAlert! : 5;
        matchStock = p.stock > alertLevel;
      }
      
      return matchCategory && matchSearch && matchStock;
    }).toList();

    if (sortBy == 'Name A-Z') {
      products.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else if (sortBy == 'Stock Low-High') {
      products.sort((a, b) => a.stock.compareTo(b.stock));
    } else if (sortBy == 'Best Selling') {
      products.sort((a, b) => (b.monthlySales ?? 0).compareTo(a.monthlySales ?? 0));
    }

    return products;
  }
}