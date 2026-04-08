import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  String? id; // ID dokumen di Firestore
  String retailerId; // UID pemilik toko / Admin
  
  // --- BASIC INFORMATION ---
  String name;
  String? sku; 
  String category;
  String? brand; 
  
  // --- PRICING ---
  int price; // Regular Price
  int? wholesalePrice; 
  int? moq; 
  
  // --- INVENTORY ---
  int stock;
  int? lowStockAlert; // Baru
  
  // --- SPECIFICATIONS ---
  String description;
  
  // --- SHIPPING ---
  double? weight; // Baru (kg)
  double? length; // Baru (cm)
  double? width; // Baru (cm)
  double? height; // Baru (cm)
  
  // --- MEDIA & STATUS ---
  String imageUrl; // Foto utama (Cover)
  List<String>? imageUrls;
  bool isAvailable; 

  // --- PERFORMANCE STATS ---
  int? monthlySales; // Total barang terjual bulan ini
  int? revenue; // Total pendapatan dari barang ini

  ProductModel({
    this.id,
    required this.retailerId,
    required this.name,
    this.sku,
    required this.category,
    this.brand,
    required this.price,
    this.wholesalePrice,
    this.moq,
    required this.stock,
    this.lowStockAlert,
    required this.description,
    this.weight,
    this.length,
    this.width,
    this.height,
    required this.imageUrl,
    this.imageUrls,
    this.isAvailable = true,
    this.monthlySales,
    this.revenue,
  });

  // --- MENGUBAH DATA MENJADI FORMAT FIRESTORE (Save/Update) ---
  Map<String, dynamic> toMap() {
    return {
      'retailerId': retailerId,
      'name': name,
      'sku': sku ?? '',
      'category': category,
      'brand': brand ?? '',
      'price': price,
      'wholesalePrice': wholesalePrice ?? 0,
      'moq': moq ?? 1,
      'stock': stock,
      'lowStockAlert': lowStockAlert ?? 0,
      'description': description,
      'weight': weight ?? 0.0,
      'length': length ?? 0.0,
      'width': width ?? 0.0,
      'height': height ?? 0.0,
      'imageUrl': imageUrl,
      'imageUrls': imageUrls ?? [],
      'isAvailable': isAvailable,
      'createdAt': FieldValue.serverTimestamp(),
      'monthlySales': monthlySales ?? 0,
      'revenue': revenue ?? 0,
    };
  }

  // --- MEMBACA DATA DARI FIRESTORE (Load/Read) ---
  factory ProductModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ProductModel(
      id: documentId,
      retailerId: map['retailerId'] ?? '',
      name: map['name'] ?? 'Unknown Product',
      sku: map['sku'],
      category: map['category'] ?? 'Uncategorized',
      brand: map['brand'],
      price: map['price']?.toInt() ?? 0,
      wholesalePrice: map['wholesalePrice']?.toInt(),
      moq: map['moq']?.toInt(),
      stock: map['stock']?.toInt() ?? 0,
      lowStockAlert: map['lowStockAlert']?.toInt(),
      description: map['description'] ?? '',
      weight: map['weight']?.toDouble(),
      length: map['length']?.toDouble(),
      width: map['width']?.toDouble(),
      height: map['height']?.toDouble(),
      imageUrl: map['imageUrl'] ?? '',
      // Parsing List dinamis dari Firestore dengan aman
      imageUrls: map['imageUrls'] != null ? List<String>.from(map['imageUrls']) : [],
      isAvailable: map['isAvailable'] ?? true,
      monthlySales: map['monthlySales']?.toInt(),
      revenue: map['revenue']?.toInt(),
    );
  }
}