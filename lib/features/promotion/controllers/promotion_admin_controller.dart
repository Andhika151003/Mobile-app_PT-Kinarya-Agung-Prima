import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/promotion.dart';

class PromotionAdminController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<PromotionModel> _promotions = [];
  List<PromotionModel> get promotions => _promotions;

  List<PromotionModel> _filteredPromotions = [];
  List<PromotionModel> get filteredPromotions => _filteredPromotions;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String _selectedStatus = 'all';
  String get selectedStatus => _selectedStatus;

  Future<void> fetchAllPromotions() async {
    _setLoading(true);
    _clearError();

    try {
      final snapshot = await _firestore
          .collection('promotions')
          .orderBy('createdAt', descending: true)
          .get();

      _promotions = snapshot.docs.map((doc) {
        return PromotionModel.fromMap(doc.id, doc.data());
      }).toList();

      _applyFilters();
      _setLoading(false);
    } catch (e) {
      debugPrint('Error fetching promotions: $e');
      _setError('Gagal mengambil data promo');
      _setLoading(false);
    }
  }

  void searchPromotions(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void filterByStatus(String status) {
    _selectedStatus = status;
    _applyFilters();
  }

  void _applyFilters() {
    var filtered = List<PromotionModel>.from(_promotions);

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((promo) {
        final title = promo.title.toLowerCase();
        final description = promo.description.toLowerCase();
        final search = _searchQuery.toLowerCase();
        return title.contains(search) || description.contains(search);
      }).toList();
    }

    if (_selectedStatus != 'all') {
      filtered = filtered.where((promo) {
        if (_selectedStatus == 'active') return promo.isActive;
        if (_selectedStatus == 'expired') return promo.status == 'expired';
        if (_selectedStatus == 'ending_soon') return promo.isEndingSoon;
        return promo.status == _selectedStatus;
      }).toList();
    }

    _filteredPromotions = filtered;
    notifyListeners();
  }

  Future<bool> createPromotion({
    required String title,
    required String description,
    required String discountType,
    required double discountValue,
    required List<String> productIds,
    required String applicableTo,
    required DateTime startDate,
    required DateTime endDate,
    required String startTime,
    required String endTime,
    required String sku,
    String? imageUrl,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final newPromo = PromotionModel(
        title: title,
        description: description,
        discountType: discountType,
        discountValue: discountValue,
        productIds: productIds,
        applicableTo: applicableTo,
        startDate: startDate,
        endDate: endDate,
        startTime: startTime,
        endTime: endTime,
        status: 'active',
        imageUrl: imageUrl,
        sku: sku,
        createdAt: DateTime.now(),
        createdBy: user.uid,
      );

      await _firestore.collection('promotions').add(newPromo.toMap());

      await fetchAllPromotions();
      _setLoading(false);
      return true;
    } catch (e) {
      debugPrint('Error creating promotion: $e');
      _setError('Gagal membuat promo: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updatePromotion({
    required String promotionId,
    required String title,
    required String description,
    required String discountType,
    required double discountValue,
    required List<String> productIds,
    required String applicableTo,
    required DateTime startDate,
    required DateTime endDate,
    required String startTime,
    required String endTime,
    required String status,
    required String sku,
    String? imageUrl,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final promotionRef = _firestore.collection('promotions').doc(promotionId);
      
      await promotionRef.update({
        'title': title,
        'description': description,
        'discountType': discountType,
        'discountValue': discountValue,
        'productIds': productIds,
        'applicableTo': applicableTo,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'startTime': startTime,
        'endTime': endTime,
        'status': status,
        'imageUrl': imageUrl,
        'sku': sku,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await fetchAllPromotions();
      _setLoading(false);
      return true;
    } catch (e) {
      debugPrint('Error updating promotion: $e');
      _setError('Gagal update promo: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deletePromotion(String promotionId) async {
  debugPrint('DELETE CALLED with ID: $promotionId'); 
  _setLoading(true);
  _clearError();

  try {
    final docRef = _firestore.collection('promotions').doc(promotionId);
    debugPrint('Document reference: ${docRef.path}'); 
    
    // Cek apakah dokumen ada
    final doc = await docRef.get();
    debugPrint('Document exists: ${doc.exists}'); 
    
    if (!doc.exists) {
      debugPrint('Document not found!');
      _setError('Promotion not found');
      _setLoading(false);
      return false;
    }
    
    await docRef.delete();
    debugPrint('Delete successful');
    
    await fetchAllPromotions();
    _setLoading(false);
    return true;
  } catch (e) {
    debugPrint('Delete error: $e');
    _setError('Gagal menghapus promo: ${e.toString()}');
    _setLoading(false);
    return false;
  }
}

  List<PromotionModel> getActivePromotions() {
    final now = DateTime.now();
    return _promotions.where((promo) {
      return promo.status == 'active' &&
          promo.startDate.isBefore(now) &&
          promo.endDate.isAfter(now);
    }).toList();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}