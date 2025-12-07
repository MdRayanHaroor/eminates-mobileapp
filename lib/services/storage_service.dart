import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final storageServiceProvider = Provider((ref) => StorageService(Supabase.instance.client));

class StorageService {
  final SupabaseClient _supabase;

  StorageService(this._supabase);

  Future<String> uploadFile(File file, String userId, String documentType) async {
    final fileExt = file.path.split('.').last;
    final fileName = '${const Uuid().v4()}.$fileExt';
    final filePath = '$userId/$documentType/$fileName';

    await _supabase.storage.from('kyc_docs').upload(
          filePath,
          file,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );

    // Return the path so we can generate signed URLs later, 
    // or if the bucket is public, we could return the public URL.
    // Given the requirement "admin must be able to view it", storing the path is safest.
    return filePath;
  }
  
  Future<String> getSignedUrl(String path) async {
    // Generate a signed URL valid for 1 hour
    return await _supabase.storage.from('kyc_docs').createSignedUrl(path, 3600);
  }

  String getPublicUrl(String path) {
    return _supabase.storage.from('kyc_docs').getPublicUrl(path);
  }
}
