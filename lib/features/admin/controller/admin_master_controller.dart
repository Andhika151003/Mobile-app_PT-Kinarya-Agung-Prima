import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminMasterController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<Map<String, dynamic>> _retailers = [];
  List<Map<String, dynamic>> get retailers => _retailers;

  List<Map<String, dynamic>> _filteredRetailers = [];
  List<Map<String, dynamic>> get filteredRetailers => _filteredRetailers;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;


  Future<void> fetchAllRetailers() async {
    _setLoading(true);
    _clearError();

    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'retailer')
          .get();  

      print('Jumlah retailer dari Firestore: ${snapshot.docs.length}'); 

      _retailers = snapshot.docs.map((doc) {
        final data = doc.data();
        print('Retailer: ${data['fullName']} - ${data['email']}'); 
        return {
          'id': doc.id,
          ...data,
          'isActive': data['isActive'] ?? true,
        };
      }).toList();

      _filteredRetailers = List.from(_retailers);
      _setLoading(false);
    } catch (e) {
      print('Error fetching retailers: $e');
      _setError('Gagal mengambil data: ${e.toString()}');
      _setLoading(false);
    }
  }

  // ==================== SEARCH RETAILERS ====================

  void searchRetailers(String query) {
    _searchQuery = query;
    if (query.isEmpty) {
      _filteredRetailers = List.from(_retailers);
    } else {
      _filteredRetailers = _retailers.where((retailer) {
        final fullName = retailer['fullName']?.toLowerCase() ?? '';
        final email = retailer['email']?.toLowerCase() ?? '';
        final search = query.toLowerCase();
        return fullName.contains(search) || email.contains(search);
      }).toList();
    }
    notifyListeners();
  }

  // ==================== GET RETAILER BY ID ====================

  Map<String, dynamic>? getRetailerById(String id) {
    try {
      return _retailers.firstWhere((retailer) => retailer['id'] == id);
    } catch (e) {
      return null;
    }
  }

  // ==================== DISABLE RETAILER ====================

  Future<bool> disableRetailer(String retailerId) async {
    _setLoading(true);
    try {
      await _firestore.collection('users').doc(retailerId).update({
        'isActive': false,
        'disabledAt': FieldValue.serverTimestamp(),
        'disabledBy': _auth.currentUser?.uid,
      });

      final index = _retailers.indexWhere((r) => r['id'] == retailerId);
      if (index != -1) {
        _retailers[index]['isActive'] = false;
      }
      searchRetailers(_searchQuery);

      _setLoading(false);
      return true;
    } catch (e) {
      print('Error disabling retailer: $e');
      _setError('Gagal menonaktifkan: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // ==================== ENABLE RETAILER ====================

  Future<bool> enableRetailer(String retailerId) async {
    _setLoading(true);
    try {
      await _firestore.collection('users').doc(retailerId).update({
        'isActive': true,
        'activatedAt': FieldValue.serverTimestamp(),
        'activatedBy': _auth.currentUser?.uid,
      });

      final index = _retailers.indexWhere((r) => r['id'] == retailerId);
      if (index != -1) {
        _retailers[index]['isActive'] = true;
      }
      searchRetailers(_searchQuery);

      _setLoading(false);
      return true;
    } catch (e) {
      print('Error enabling retailer: $e');
      _setError('Gagal mengaktifkan: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // ==================== DELETE RETAILER ====================

  Future<bool> deleteRetailer(String retailerId) async {
    _setLoading(true);
    try {
      await _firestore.collection('users').doc(retailerId).delete();

      _retailers.removeWhere((r) => r['id'] == retailerId);
      searchRetailers(_searchQuery);

      _setLoading(false);
      return true;
    } catch (e) {
      print('Error deleting retailer: $e');
      _setError('Gagal menghapus: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // ==================== GET STATISTICS ====================

  int getActiveRetailersCount() {
    return _retailers.where((r) => r['isActive'] == true).length;
  }

  int getInactiveRetailersCount() {
    return _retailers.where((r) => r['isActive'] == false).length;
  }

  int getTotalRetailersCount() {
    return _retailers.length;
  }

  // ==================== PRIVATE HELPERS ====================

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