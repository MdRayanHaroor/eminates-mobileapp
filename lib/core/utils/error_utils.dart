import 'package:supabase_flutter/supabase_flutter.dart';

class ErrorUtils {
  static String getFriendlyErrorMessage(Object error) {
    if (error is AuthException) {
      if (error.message.contains('Invalid login credentials')) {
        return 'Incorrect email or password.';
      }
      if (error.message.contains('Email not confirmed')) {
        return 'Please confirm your email address.';
      }
      if (error.message.contains('User already registered')) {
        return 'This email is already registered. Please sign in.';
      }
      if (error.message.contains('Password should be at least')) {
        return 'Password is too weak. It should be at least 6 characters.';
      }
      return error.message;
    }
    if (error is PostgrestException) {
      // Handle database errors if needed, though usually less common for end users
      return 'A database error occurred. Please try again.';
    }
    return 'An unexpected error occurred. Please try again.';
  }
}
