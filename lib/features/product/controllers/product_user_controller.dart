import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../../promotion/models/promotion.dart';

class ProductUserController {
  final FirebaseFirestore _firestore;

  ProductUserController({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<PromotionModel>> getActivePromotionsStream() {
    return _firestore
        .collection('promotions')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PromotionModel.fromMap(doc.id, doc.data()))
          .where((promo) => promo.isActive)
          .toList();
    });
  }

  PromotionModel? getBestPromotionForProduct(
      ProductModel product, List<PromotionModel> activePromotions) {
    final matchingPromos = activePromotions.where((promo) {
      return promo.applicableTo == 'all' || promo.productIds.contains(product.id);
    }).toList();

    if (matchingPromos.isEmpty) return null;

    matchingPromos.sort((a, b) {
      int typePriority(String type) {
        if (type == 'fixed') return 3;
        if (type == 'percentage') return 2;
        if (type == 'bogo') return 1;
        return 0;
      }

      int pA = typePriority(a.discountType);
      int pB = typePriority(b.discountType);

      if (pA != pB) return pB.compareTo(pA);
      return b.discountValue.compareTo(a.discountValue);
    });

    return matchingPromos.first;
  }

  double calculateDiscountedPrice(ProductModel product, PromotionModel? promo) {
    if (promo == null) return product.price.toDouble();

    if (promo.discountType == 'fixed') {
      return (product.price - promo.discountValue).clamp(0, double.infinity);
    } else if (promo.discountType == 'percentage') {
      return product.price * (1 - (promo.discountValue / 100));
    }

    return product.price.toDouble();
  }

  List<ProductModel> filterAndSortProducts(
      List<ProductModel> allProducts,
      String category,
      String query,
      String sortBy) {
    var displayProducts = allProducts.where((p) {
      final matchesCategory =
          category == 'All Products' || p.category == category;
      final matchesSearch =
          query.isEmpty || p.name.toLowerCase().contains(query.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    if (sortBy == 'Name A-Z') {
      displayProducts
          .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else if (sortBy == 'Price Low-High') {
      displayProducts.sort((a, b) => a.price.compareTo(b.price));
    } else if (sortBy == 'Price High-Low') {
      displayProducts.sort((a, b) => b.price.compareTo(a.price));
    }

    return displayProducts;
  }

  Future<void> addToCart(ProductModel product, int quantity) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
