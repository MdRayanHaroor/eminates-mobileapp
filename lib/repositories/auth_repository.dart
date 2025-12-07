import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  User? get currentUser => _supabase.auth.currentUser;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
      emailRedirectTo: 'io.supabase.app://login-callback',
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
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
