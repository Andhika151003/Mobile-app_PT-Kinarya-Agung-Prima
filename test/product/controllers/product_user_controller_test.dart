import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerce/features/product/controllers/product_user_controller.dart';
import 'package:ecommerce/features/product/models/product.dart';

void main() {
  late ProductUserController userProductController;

  setUp(() {
    userProductController = ProductUserController();
  });

  group('ProductUserController Tests', () {
    test('filterAndSortProducts sorts and filters correctly', () {
      final p1 = ProductModel(
        id: '1', retailerId: 'r1', name: 'Banana', category: 'Food', price: 1000, stock: 10, description: 'Fruit', imageUrl: ''
      );
      final p2 = ProductModel(
        id: '2', retailerId: 'r1', name: 'Apple', category: 'Food', price: 2000, stock: 2, description: 'Fruit', imageUrl: ''
      );

      final list = [p1, p2];

      final filteredCategories = userProductController.filterAndSortProducts(list, 'Food', '', 'Name A-Z');
      expect(filteredCategories.length, 2);

      final sortedAZ = userProductController.filterAndSortProducts(list, 'All Products', '', 'Name A-Z');
      expect(sortedAZ.first.name, 'Apple');

      final sortedLowHigh = userProductController.filterAndSortProducts(list, 'All Products', '', 'Price Low-High');
      expect(sortedLowHigh.first.name, 'Banana'); 

      final sortedHighLow = userProductController.filterAndSortProducts(list, 'All Products', '', 'Price High-Low');
      expect(sortedHighLow.first.name, 'Apple');
    });
  });
}
