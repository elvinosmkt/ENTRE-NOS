import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final String? userId;
  final Map<String, dynamic>? profile;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.userId,
    this.profile,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? userId,
    Map<String, dynamic>? profile,
  }) {
    return AuthState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      profile: profile ?? this.profile,
    );
  }
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final authService = ref.read(authServiceProvider);
    
    // Listen to auth state changes
    authService.authStateChanges.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.tokenRefreshed) {
        _loadProfile();
      } else if (event == AuthChangeEvent.signedOut) {
        state = const AsyncValue.data(AuthState(status: AuthStatus.unauthenticated));
      }
    });

    // Check current auth state
    if (authService.isAuthenticated) {
      final profile = await authService.getProfile();
      return AuthState(
        status: AuthStatus.authenticated,
        userId: authService.currentUserId,
        profile: profile,
      );
    }
    
    return const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> signInAnonymously(String displayName) async {
    state = const AsyncValue.loading();
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInAnonymously();
      
      // Generate invite code
      final code = _generateCode();
      
      // Create profile
      await authService.upsertProfile(
        displayName: displayName,
        inviteCode: code,
      );

      final profile = await authService.getProfile();
      state = AsyncValue.data(AuthState(
        status: AuthStatus.authenticated,
        userId: authService.currentUserId,
        profile: profile,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> _loadProfile() async {
    final authService = ref.read(authServiceProvider);
    final profile = await authService.getProfile();
    state = AsyncValue.data(AuthState(
      status: AuthStatus.authenticated,
      userId: authService.currentUserId,
      profile: profile,
    ));
  }

  Future<void> signOut() async {
    final authService = ref.read(authServiceProvider);
    await authService.signOut();
    state = const AsyncValue.data(AuthState(status: AuthStatus.unauthenticated));
  }

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = DateTime.now().microsecondsSinceEpoch;
    return List.generate(6, (i) => chars[(random ~/ (i + 1)) % chars.length]).join();
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
