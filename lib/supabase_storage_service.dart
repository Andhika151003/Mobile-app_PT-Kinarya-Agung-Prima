import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseStorageService {
  final _supabase = Supabase.instance.client;

  Future<String?> uploadProductImage(File file, String fileName) async {
    try {
      final path = 'products/$fileName';

      // Upload the file to the 'products' bucket
      await _supabase.storage
          .from('products')
          .upload(
            path,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      // Get the public URL for the uploaded image
      final publicUrl = _supabase.storage.from('products').getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload image to Supabase: $e');
    }
  }

  Future<void> deleteImages(List<String> fileUrls) async {
    try {
      final paths = fileUrls.map((url) {
        // Asumsi URL berakhir dengan .../products/namafile.jpg
        return 'products/${url.split('/products/').last}';
      }).toList();
      
      if (paths.isNotEmpty) {
        await _supabase.storage.from('products').remove(paths);
      }
    } catch (e) {
      print('Error deleting images from Supabase: $e');
    }
  }
}
