import 'package:flutter/material.dart';
import '../models/cart.dart';

class CartController extends ChangeNotifier {
  static final CartController _instance = CartController._internal();
  factory CartController() => _instance;
  CartController._internal();

  final List<CartItem> _items = [];

  final double shippingCost = 9.99;

  List<CartItem> get items => _items;

  double get subtotal {
    return _items.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

  double get total => subtotal + shippingCost;

  void addToCart({
    required String id,
    required String title,
    required String variant,
    required double price,
    required String imageUrl,
    int quantity = 1,
    required int minOrder,  
    required int stockLimit,
  }) {
    final existingIndex = _items.indexWhere((item) => item.id == id);

    if (existingIndex >= 0) {
      final existingItem = _items[existingIndex];
      if (existingItem.quantity + quantity <= stockLimit) {
        existingItem.quantity += quantity;
      } else {
        existingItem.quantity = stockLimit;
      }
      
      existingItem.minOrder = minOrder;
      existingItem.stockLimit = stockLimit;
    } else {
      _items.add(
        CartItem(
          id: id,
          title: title,
          variant: variant,
          price: price,
          imageUrl: imageUrl,
          quantity: quantity, 
          minOrder: minOrder,
          stockLimit: stockLimit,
        ),
      );
    }
    
    notifyListeners();
  }

  void incrementQty(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      final item = _items[index];
      if (item.quantity < item.stockLimit) {
        item.quantity++;
        notifyListeners();
      }
    }
  }

  void decrementQty(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      final item = _items[index];
      if (item.quantity > item.minOrder) {
        item.quantity--;
        notifyListeners();
      }
    }
  }

  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
