import 'package:flutter/foundation.dart';
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
      
      // Se já está autenticado, usar a sessão existente
      if (authService.isAuthenticated) {
        debugPrint('🔑 Já autenticado: ${authService.currentUserId}');
      } else {
        debugPrint('🔑 Criando conta anônima...');
        await authService.signInAnonymously();
        debugPrint('🔑 Conta criada: ${authService.currentUserId}');
      }
      
      // Generate invite code
      final code = _generateCode();
      debugPrint('🎫 Código de convite gerado: $code');
      
      // Create/update profile
      debugPrint('📝 Criando perfil com nome="$displayName", code="$code"');
      await authService.upsertProfile(
        displayName: displayName,
        inviteCode: code,
      );
      debugPrint('✅ Perfil criado/atualizado no Supabase');

      final profile = await authService.getProfile();
      debugPrint('👤 Perfil recuperado: $profile');
      
      state = AsyncValue.data(AuthState(
        status: AuthStatus.authenticated,
        userId: authService.currentUserId,
        profile: profile,
      ));
    } catch (e, st) {
      debugPrint('❌ Erro no signInAnonymously: $e');
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
