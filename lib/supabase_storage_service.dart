import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseStorageService {
  final _supabase = Supabase.instance.client;

  // ─────────────────────────────────────────────
  // PRODUK
  // Bucket: products  |  Folder: products/
  // ─────────────────────────────────────────────
  Future<String?> uploadProductImage(File file, String fileName) async {
    try {
      final path = 'products/$fileName';
      await _supabase.storage.from('products').upload(
            path,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );
      return _supabase.storage.from('products').getPublicUrl(path);
    } catch (e) {
      throw Exception('Failed to upload product image: $e');
    }
  }

  Future<void> deleteImages(List<String> fileUrls) async {
    try {
      final paths = fileUrls
          .map((url) => 'products/${url.split('/products/').last}')
          .toList();
      if (paths.isNotEmpty) {
        await _supabase.storage.from('products').remove(paths);
      }
    } catch (e) {
      debugPrint('Error deleting product images: $e');
    }
  }

  // ─────────────────────────────────────────────
  // PROMOSI
  // Bucket: promotions  |  Folder: promotions/
  // ─────────────────────────────────────────────
  Future<String?> uploadPromotionImage(File file, String fileName) async {
    try {
      final path = 'promotions/$fileName';
      await _supabase.storage.from('promotions').upload(
            path,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );
      return _supabase.storage.from('promotions').getPublicUrl(path);
    } catch (e) {
      throw Exception('Failed to upload promotion image: $e');
    }
  }

  Future<void> deletePromotionImage(String fileUrl) async {
    try {
      final path = 'promotions/${fileUrl.split('/promotions/').last}';
      await _supabase.storage.from('promotions').remove([path]);
    } catch (e) {
      debugPrint('Error deleting promotion image: $e');
    }
  }

  // ─────────────────────────────────────────────
  // FOTO PROFIL RETAIL
  // Bucket: profiles  |  Folder: profiles/retail/
  // ─────────────────────────────────────────────
  Future<String?> uploadRetailProfileImage(File file, String fileName) async {
    try {
      final path = 'retail/$fileName';
      await _supabase.storage.from('profiles').upload(
            path,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );
      return _supabase.storage.from('profiles').getPublicUrl(path);
    } catch (e) {
      throw Exception('Failed to upload retail profile image: $e');
    }
  }

  // ─────────────────────────────────────────────
  // FOTO PROFIL ADMIN
  // Bucket: profiles  |  Folder: profiles/admin/
  // ─────────────────────────────────────────────
  Future<String?> uploadAdminProfileImage(File file, String fileName) async {
    try {
      final path = 'admin/$fileName';
      await _supabase.storage.from('profiles').upload(
            path,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );
      return _supabase.storage.from('profiles').getPublicUrl(path);
    } catch (e) {
      throw Exception('Failed to upload admin profile image: $e');
    }
  }

  // ─────────────────────────────────────────────
  // GAMBAR KOMPLAIN
  // Bucket: complaints  |  Folder: complaints/
  // ─────────────────────────────────────────────
  Future<String?> uploadComplaintImage(File file, String fileName) async {
    try {
      final path = 'complaints/$fileName';
      await _supabase.storage.from('complaints').upload(
            path,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );
      return _supabase.storage.from('complaints').getPublicUrl(path);
    } catch (e) {
      debugPrint('Supabase Upload Error: $e');
      throw Exception('Failed to upload complaint image: $e');
    }
  }
}
