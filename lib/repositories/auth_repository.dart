import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  User? get currentUser => _supabase.auth.currentUser;

  String _sanitizePhone(String phone) {
    // Remove all characters except digits and +
    return phone.replaceAll(RegExp(r'[^\d+]'), '');
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    final sanitizedPhone = _sanitizePhone(phone);
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'phone': sanitizedPhone,
      },
      emailRedirectTo: 'io.supabase.app://login-callback',
    );
  }

  Future<AuthResponse> signIn({
    required String identifier,
    required String password,
  }) async {
    final isEmail = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(identifier);
    if (isEmail) {
      return await _supabase.auth.signInWithPassword(
        email: identifier,
        password: password,
      );
    } else {
      // Phone Login (without SMS provider)
      try {
        final sanitizedPhone = _sanitizePhone(identifier);
        
        // Use RPC to bypass RLS for unauthenticated lookup
        final String? email = await _supabase
            .rpc('get_email_by_phone', params: {'phone_number': sanitizedPhone});

        if (email == null) {
          throw AuthException('No account found with this phone number: $sanitizedPhone');
        }

        // 3. Sign in with the found email
        return await _supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
      } catch (e) {
        if (e is AuthException) rethrow;
        throw AuthException('Login failed: ${e.toString()}');
      }
    }
  }

  GoogleSignIn get _googleSignIn {
    const webClientId = '875988520374-32oqkpvb4ot15qrdqi0801lgvuqtqhpa.apps.googleusercontent.com';
    const iosClientId = 'YOUR_IOS_CLIENT_ID.apps.googleusercontent.com';

    return GoogleSignIn(
      clientId: iosClientId,
      serverClientId: webClientId,
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    if (!kIsWeb) {
      await _googleSignIn.signOut();
    }
  }

  Future<bool> signInWithGoogle() async {
    // Web Google Sign In
    if (kIsWeb) {
      return await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
      );
    }

    // Mobile Google Sign In
    final googleUser = await _googleSignIn.signIn();
    final googleAuth = await googleUser?.authentication;
    final accessToken = googleAuth?.accessToken;
    final idToken = googleAuth?.idToken;

    if (accessToken == null) {
      throw 'No Access Token found.';
    }
    if (idToken == null) {
      throw 'No ID Token found.';
    }

    final response = await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
    return response.session != null;
  }
  
  // Helper to check if user is admin
  Future<bool> isAdmin() async {
    final user = currentUser;
    if (user == null) return false;
    
    try {
      final response = await _supabase
          .from('users')
          .select('role')
          .eq('id', user.id)
          .single();
      return response['role'] == 'admin';
    } catch (e) {
      return false;
    }
  }
  Future<void> resetPasswordForEmail(String email) async {
    await _supabase.auth.resetPasswordForEmail(
      email,
      redirectTo: kIsWeb
          ? null // Web handles it differently usually, or same URL
          : 'io.supabase.investorapp://reset-callback', // Deep link scheme
    );
  }

  Future<void> updatePassword(String newPassword) async {
    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }
}
