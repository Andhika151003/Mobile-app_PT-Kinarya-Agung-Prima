import '../models/product.dart';

class ProductUserController {

  List<ProductModel> filterAndSortProducts(
    List<ProductModel> allProducts, 
    String category, 
    String query, 
    String sortBy
  ) {
    var displayProducts = allProducts.where((p) {
      final matchesCategory = category == 'All Products' || p.category == category;
      final matchesSearch = query.isEmpty || 
          p.name.toLowerCase().contains(query.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    if (sortBy == 'Name A-Z') {
      displayProducts.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
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
