import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/promotion.dart';
import '../../../supabase_storage_service.dart';
import '../../notification/services/push_notification_service.dart';

class PromotionAdminController extends ChangeNotifier {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final PushNotificationService _pushNotificationService = PushNotificationService();

  PromotionAdminController({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

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

  String _selectedType = 'all';
  String get selectedType => _selectedType;

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

  void filterByType(String type) {
    _selectedType = type;
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
        if (_selectedStatus == 'upcoming') return promo.isUpcoming;
        if (_selectedStatus == 'expired') return promo.isExpired;
        if (_selectedStatus == 'ending_soon') return promo.isEndingSoon;
        return promo.status == _selectedStatus;
      }).toList();
    }

    if (_selectedType != 'all') {
      filtered = filtered.where((promo) {
        return promo.discountType == _selectedType;
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
    double? maxDiscount,
    File? imageFile,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Check for overlapping promotions
      final conflicts = await _checkConflicts(
        applicableTo: applicableTo,
        productIds: productIds,
        startDate: startDate,
        endDate: endDate,
      );

      if (conflicts.isNotEmpty) {
        _setError(conflicts.join('\n'));
        _setLoading(false);
        return false;
      }

      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      String? imageUrl;
      if (imageFile != null) {
        final storageService = SupabaseStorageService();
        final fileName = 'promo_${DateTime.now().millisecondsSinceEpoch}.jpg';
        imageUrl = await storageService.uploadPromotionImage(imageFile, fileName);
      }

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
        maxDiscount: maxDiscount,
        createdAt: DateTime.now(),
        createdBy: user.uid,
      );

      final docRef = await _firestore.collection('promotions').add(newPromo.toMap());

      // Broadcast Notification to all users
      await _pushNotificationService.broadcastNotification(
        title: 'Promo Spesial Hari Ini!',
        message: 'Jangan lewatkan: $title. Cek sekarang sebelum kehabisan!',
        type: 'promo',
        relatedId: docRef.id,
      );

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
    double? maxDiscount,
    File? imageFile,
    String? currentImageUrl,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Check for overlapping promotions (excluding current one)
      if (status == 'active') {
        final conflicts = await _checkConflicts(
          applicableTo: applicableTo,
          productIds: productIds,
          startDate: startDate,
          endDate: endDate,
          excludePromotionId: promotionId,
        );

        if (conflicts.isNotEmpty) {
          _setError(conflicts.join('\n'));
          _setLoading(false);
          return false;
        }
      }

      final promotionRef = _firestore.collection('promotions').doc(promotionId);
      
      String? imageUrl = currentImageUrl;
      if (imageFile != null) {
        final storageService = SupabaseStorageService();
        final fileName = 'promo_${DateTime.now().millisecondsSinceEpoch}.jpg';
        imageUrl = await storageService.uploadPromotionImage(imageFile, fileName);
      }

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
        'maxDiscount': maxDiscount,
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

  Future<List<String>> _checkConflicts({
    required String applicableTo,
    required List<String> productIds,
    required DateTime startDate,
    required DateTime endDate,
    String? excludePromotionId,
  }) async {
    final List<String> conflicts = [];
    
    // Normalize dates to day-level for overlap check
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    // Make sure we have the latest list
    if (_promotions.isEmpty) {
      await fetchAllPromotions();
    }

    for (var promo in _promotions) {
      if (promo.id == excludePromotionId) continue;
      
      // Only check active or upcoming promotions
      if (promo.status != 'active') continue;

      final pStart = DateTime(promo.startDate.year, promo.startDate.month, promo.startDate.day);
      final pEnd = DateTime(promo.endDate.year, promo.endDate.month, promo.endDate.day, 23, 59, 59);

      // Check if date ranges overlap
      bool overlaps = start.isBefore(pEnd) && end.isAfter(pStart);
      if (!overlaps) continue;

      // Check for product overlap
      if (applicableTo == 'all' || promo.applicableTo == 'all') {
        conflicts.add('Bentrokan promo global: "${promo.title}" (${promo.formattedDateRange})');
      } else {
        final intersectingProducts = productIds.where((id) => promo.productIds.contains(id)).toList();
        if (intersectingProducts.isNotEmpty) {
          conflicts.add('Produk sudah terdaftar di promo: "${promo.title}"');
          break;
        }
      }
    }

    return conflicts;
  }

  Future<List<Map<String, dynamic>>> getAllProducts() async {
    try {
      final snapshot = await _firestore.collection('products').get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('Error getting products: $e');
      return [];
    }
  }
}