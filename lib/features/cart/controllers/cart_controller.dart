import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart.dart';
import '../../../core/repositories/product_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartController extends ChangeNotifier {
  static final CartController _instance = CartController._internal();
  factory CartController() => _instance;
  
  final ProductRepository _productRepository = ProductRepository();
  final List<CartItem> _items = [];
  
  // Cache UID saat ini untuk memastikan kita menyimpan ke kunci yang benar
  String? _currentUid;
  
  CartController._internal() {
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _currentUid = user?.uid;
      debugPrint('CartController: Auth change detected. Current UID: ${_currentUid ?? "Guest"}');
      _loadFromPrefs();
    });
  }

  String get _prefKey {
    return _currentUid != null ? 'cart_items_$_currentUid' : 'cart_items_guest';
  }

  List<CartItem> get items => _items;

  double get subtotal =>
      _items.fold(0, (acc, item) => acc + (item.price * item.quantity));

  final double shippingCost = 0.0;
  double get total => subtotal + shippingCost;

  // ── Persistensi ───────────────────────────────────────────

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _prefKey;
      final raw = prefs.getString(key);
      
      debugPrint('CartController: Loading from key: $key');
      
      _items.clear(); 
      
      if (raw != null) {
        final List<dynamic> decoded = jsonDecode(raw);
        _items.addAll(decoded
            .map((e) => CartItem.fromMap(Map<String, dynamic>.from(e)))
            .toList());
        debugPrint('CartController: Loaded ${_items.length} items for $key');
      } else {
        debugPrint('CartController: No items found for $key');
      }
      notifyListeners();
    } catch (e) {
      debugPrint('CartController: gagal load cart dari prefs: $e');
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _prefKey;
      final encoded = jsonEncode(_items.map((e) => e.toMap()).toList());
      
      await prefs.setString(key, encoded);
      debugPrint('CartController: Saved ${_items.length} items to key: $key');
    } catch (e) {
      debugPrint('CartController: gagal save cart ke prefs: $e');
    }
  }

  // ── Sync stok dari Firestore ──────────────────────────────
  Future<void> syncStockFromFirestore() async {
    if (_items.isEmpty) return;
    try {
      final ids = _items.map((e) => e.id).toList();
      final products = await _productRepository.getProductsByIds(ids);

      bool changed = false;
      for (final product in products) {
        final stock = product.stock;
        final moq = product.moq ?? 1;
        
        final index = _items.indexWhere((item) => item.id == product.id);
        if (index == -1) continue;

        final item = _items[index];
        item.stockLimit = stock;
        item.minOrder = moq;

        if (item.quantity > stock) {
          item.quantity = stock > 0 ? stock : moq;
          changed = true;
        }
        changed = true;
      }

      final beforeLen = _items.length;
      _items.removeWhere((item) => item.stockLimit <= 0);
      if (_items.length != beforeLen) changed = true;

      if (changed) {
        await _saveToPrefs();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('CartController: gagal sync stok: $e');
    }
  }

  // ── Operasi Cart ─────────────────────────────────────────

  void addToCart({
    required String id,
    required String title,
    required String variant,
    required double price,
    required String imageUrl,
    required String category,
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
          category: category,
          quantity: quantity,
          minOrder: minOrder,
          stockLimit: stockLimit,
        ),
      );
    }

    _saveToPrefs();
    notifyListeners();
  }

  void incrementQty(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      final item = _items[index];
      if (item.quantity < item.stockLimit) {
        item.quantity++;
        _saveToPrefs();
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
        _saveToPrefs();
        notifyListeners();
      }
    }
  }

  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    _saveToPrefs();
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _saveToPrefs();
    notifyListeners();
  }
}
