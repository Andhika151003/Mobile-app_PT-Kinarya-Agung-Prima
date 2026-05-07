import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/product/models/product.dart';
import '../utils/result.dart';
import '../error/failures.dart';

class ProductRepository {
  final FirebaseFirestore _firestore;

  ProductRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final String _collection = 'products';

  Stream<List<ProductModel>> getRecommendedProducts({int limit = 10}) {
    return _firestore
        .collection(_collection)
        .orderBy('monthlySales', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<ProductModel>> getSupplyProductsStream() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<ProductModel?> getProductById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (doc.exists) {
      return ProductModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  Future<List<ProductModel>> getProductsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    
    List<ProductModel> products = [];
    for (int i = 0; i < ids.length; i += 10) {
      final chunk = ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10);
      final snapshot = await _firestore
          .collection(_collection)
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
          
      products.addAll(
        snapshot.docs.map((doc) => ProductModel.fromMap(doc.data(), doc.id)),
      );
    }
    return products;
  }

  Future<Result<String>> addProduct(ProductModel product) async {
    try {
      final docRef = await _firestore.collection(_collection).add(product.toMap());
      return Result.success(docRef.id);
    } catch (e) {
      return Result.failure(ServerFailure("Gagal menambahkan produk: $e"));
    }
  }

  Future<Result<void>> updateProduct(ProductModel product) async {
    if (product.id == null) return Result.failure(ServerFailure("ID produk tidak ditemukan"));
    try {
      Map<String, dynamic> updateData = product.toMap();
      updateData.remove('createdAt');
      updateData['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection(_collection).doc(product.id).update(updateData);
      return Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure("Gagal mengupdate produk: $e"));
    }
  }

  Future<Result<void>> deleteProduct(String productId) async {
    try {
      await _firestore.collection(_collection).doc(productId).delete();
      return Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure("Gagal menghapus produk: $e"));
    }
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getAllProducts() async {
    return await _firestore.collection('products').get();
  }
}
