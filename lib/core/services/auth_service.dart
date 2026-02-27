import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Current user ID or null
  String? get currentUserId => _client.auth.currentUser?.id;

  /// Whether the user is authenticated
  bool get isAuthenticated => _client.auth.currentUser != null;

  /// Auth state changes stream
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Sign in anonymously (for MVP — no email needed)
  Future<AuthResponse> signInAnonymously() async {
    try {
      final response = await _client.auth.signInAnonymously();
      debugPrint('Anonymous sign in successful: ${response.user?.id}');
      return response;
    } catch (e) {
      debugPrint('Error signing in anonymously: $e');
      rethrow;
    }
  }

  /// Sign in with Magic Link (email)
  Future<void> signInWithMagicLink(String email) async {
    try {
      await _client.auth.signInWithOtp(email: email);
    } catch (e) {
      debugPrint('Error signing in with magic link: $e');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }

  /// Create or update user profile after sign in
  Future<void> upsertProfile({
    required String displayName,
    required String inviteCode,
    String? pushToken,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    await _client.from('profiles').upsert({
      'id': userId,
      'display_name': displayName,
      'invite_code': inviteCode,
      'push_token': pushToken,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Get current user profile
  Future<Map<String, dynamic>?> getProfile() async {
    final userId = currentUserId;
    if (userId == null) return null;

    final response = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    return response;
  }

  /// Save push notification token
  Future<void> savePushToken(String token) async {
    final userId = currentUserId;
    if (userId == null) return;

    await _client.from('profiles').update({
      'push_token': token,
    }).eq('id', userId);
  }
}
