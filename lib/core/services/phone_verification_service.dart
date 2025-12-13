import 'package:supabase_flutter/supabase_flutter.dart';

class PhoneVerificationService {
  static final Map<String, bool> _cache = {};

  static Future<bool> isVerified(SupabaseClient supabase, String userId) async {
    if (_cache.containsKey(userId) && _cache[userId] == true) {
      return true;
    }

    try {
      final response = await supabase
          .from('users')
          .select('phone')
          .eq('id', userId)
          .maybeSingle();
      
      final phone = response?['phone'] as String?;
      final hasPhone = phone != null && phone.isNotEmpty;
      
      if (hasPhone) {
        _cache[userId] = true;
      }
      return hasPhone;
    } catch (e) {
      // On error, default to false (safe) or true (permissive)?
      // Safe: false.
      return false;
    }
  }

  static void setVerified(String userId) {
    _cache[userId] = true;
  }
  
  static void clearCache(String userId) {
      _cache.remove(userId);
  }
}
