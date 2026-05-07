import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Sign in with email and password
  Future<AuthResponse> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Sign in with magic link (OTP)
  Future<void> signInWithMagicLink(String email) async {
    await _supabase.auth.signInWithOtp(
      email: email,
      // No emailRedirectTo - uses HTTPS redirect which works better on mobile
    );
  }

  // Check if user exists in profiles table
  Future<bool> checkUserExists(String email) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('email')
          .eq('email', email)
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  // Sign up with email and password
  Future<AuthResponse> signUpWithEmailPassword(
    String email,
    String password,
    String username,
  ) async {
    // Create the auth user
    final authResponse = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': username}, // Matches SQL trigger expectation
    );

    // If signup successful, the SQL trigger should handle profile creation.
    // We do not manually upsert here because if email confirmation is required,
    // we don't have a session yet, and RLS will block the insert.

    return authResponse;
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(
      email,
      redirectTo: 'io.supabase.seerahtimeline://login-callback/',
    );
  }

  // Log out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Sign in with Google
  Future<void> signInWithGoogle() async {
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.seerahtimeline://login-callback/',
    );
  }

  // Sign in with Facebook
  Future<void> signInWithFacebook() async {
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.facebook,
      redirectTo: 'io.supabase.seerahtimeline://login-callback/',
    );
  }

  // Get user email
  String? getCurrentUserEmail() {
    final session = _supabase.auth.currentSession;
    final user = session?.user;
    return user?.email;
  }
}
