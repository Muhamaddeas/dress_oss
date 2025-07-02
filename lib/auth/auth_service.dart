import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Sign in with email and password
  Future<AuthResponse> signInWithEmailPassword(
    String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password.trim(),
      );
      
      if (response.user == null) {
        throw AuthException('User not found after sign in');
      }
      
      return response;
    } on AuthException catch (e) {
      throw AuthException('Login failed: ${e.message}');
    } catch (e) {
      throw Exception('An error occurred during login: $e');
    }
  }

  // Sign up with email and password
  Future<AuthResponse> signUpWithEmailPassword(
    String email, String password) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password.trim(),
        data: {
          'email': email.trim(),
          'role': 'user', 
        },
      );

      if (response.user == null) {
        throw AuthException('User not created during sign up');
      }

      return response;
    } on AuthException catch (e) {
      throw AuthException('Registration failed: ${e.message}');
    } catch (e) {
      throw Exception('An error occurred during registration: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Logout failed: $e');
    }
  }

  // Get user email
  String? getCurrentUserEmail() {
    try {
      return _supabase.auth.currentUser?.email;
    } catch (e) {
      throw Exception('Failed to get user email: $e');
    }
  }

  // Get user ID
  String? getCurrentUserId() {
    try {
      return _supabase.auth.currentUser?.id;
    } catch (e) {
      throw Exception('Failed to get user ID: $e');
    }
  }
}