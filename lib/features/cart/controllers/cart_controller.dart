import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart.dart';

class CartController extends ChangeNotifier {
  static final CartController _instance = CartController._internal();
  factory CartController() => _instance;
  CartController._internal() {
    _loadFromPrefs();
  }

  final List<CartItem> _items = [];
  static const _prefKey = 'cart_items';

  List<CartItem> get items => _items;

  double get subtotal =>
      _items.fold(0, (acc, item) => acc + (item.price * item.quantity));

  final double shippingCost = 0.0;
  double get total => subtotal + shippingCost;

  // ── Persistensi ───────────────────────────────────────────

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      if (raw != null) {
        final List<dynamic> decoded = jsonDecode(raw);
        _items.clear();
        _items.addAll(decoded
            .map((e) => CartItem.fromMap(Map<String, dynamic>.from(e)))
            .toList());
        notifyListeners();
      }
    } catch (e) {
      debugPrint('CartController: gagal load cart dari prefs: $e');
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_items.map((e) => e.toMap()).toList());
      await prefs.setString(_prefKey, encoded);
    } catch (e) {
      debugPrint('CartController: gagal save cart ke prefs: $e');
    }
  }

  // ── Sync stok dari Firestore ──────────────────────────────
  /// Dipanggil saat pull-to-refresh di CartView.
  /// Mengambil stok terbaru tiap produk dari Firestore dan
  /// menyesuaikan quantity jika melebihi stok yang baru.
  Future<void> syncStockFromFirestore() async {
    if (_items.isEmpty) return;
    try {
      final ids = _items.map((e) => e.id).toList();

      // Firestore whereIn max 10, chunk kalau perlu
      final List<DocumentSnapshot> docs = [];
      for (int i = 0; i < ids.length; i += 10) {
        final chunk = ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10);
        final snap = await FirebaseFirestore.instance
            .collection('products')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        docs.addAll(snap.docs);
      }

      bool changed = false;
      for (final doc in docs) {
        final data = doc.data() as Map<String, dynamic>;
        final stock = (data['stock'] as num?)?.toInt() ?? 0;
        final moq = (data['moq'] as num?)?.toInt() ?? 1;
        final index = _items.indexWhere((item) => item.id == doc.id);
        if (index == -1) continue;

        final item = _items[index];
        // Update stockLimit & minOrder ke nilai terbaru
        item.stockLimit = stock;
        item.minOrder = moq;

        // Sesuaikan quantity jika melebihi stok terkini
        if (item.quantity > stock) {
          item.quantity = stock > 0 ? stock : moq;
          changed = true;
        }
        changed = true;
      }

      // Hapus item yang produknya sudah tidak tersedia (stock 0)
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
