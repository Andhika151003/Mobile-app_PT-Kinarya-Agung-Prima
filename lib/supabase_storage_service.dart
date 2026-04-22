import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseStorageService {
  final _supabase = Supabase.instance.client;

  Future<String?> uploadProductImage(File file, String fileName) async {
    try {
      final path = 'products/$fileName';

      await _supabase.storage
          .from('products')
          .upload(
            path,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      final publicUrl = _supabase.storage.from('products').getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload image to Supabase: $e');
    }
  }

  Future<void> deleteImages(List<String> fileUrls) async {
    try {
      final paths = fileUrls.map((url) {
        return 'products/${url.split('/products/').last}';
      }).toList();
      
      if (paths.isNotEmpty) {
        await _supabase.storage.from('products').remove(paths);
      }
    } catch (e) {
      debugPrint('Error deleting images from Supabase: $e');
    }
  }

  Future<String?> uploadComplaintImage(File file, String fileName) async {
    try {
      final path = 'complaints/$fileName';

      await _supabase.storage
          .from('complaints')
          .upload(
            path,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      final publicUrl = _supabase.storage.from('complaints').getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      debugPrint('Supabase Upload Error: $e');
      throw Exception('Failed to upload complaint image: $e');
    }
  }
}
