import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/supabase_service.dart';

final supabaseServiceProvider = Provider<SupabaseService>((ref) => SupabaseService());

class ConnectionState {
  final bool isConnected;
  final bool isLoading;
  final String? partnerName;
  final String? partnerId;
  final String? error;

  const ConnectionState({
    this.isConnected = false,
    this.isLoading = false,
    this.partnerName,
    this.partnerId,
    this.error,
  });

  ConnectionState copyWith({
    bool? isConnected,
    bool? isLoading,
    String? partnerName,
    String? partnerId,
    String? error,
  }) {
    return ConnectionState(
      isConnected: isConnected ?? this.isConnected,
      isLoading: isLoading ?? this.isLoading,
      partnerName: partnerName ?? this.partnerName,
      partnerId: partnerId ?? this.partnerId,
      error: error,
    );
  }
}

class ConnectionNotifier extends AsyncNotifier<ConnectionState> {
  @override
  Future<ConnectionState> build() async {
    final service = ref.read(supabaseServiceProvider);
    final partner = await service.getPartnerProfile();
    
    if (partner != null) {
      return ConnectionState(
        isConnected: true,
        partnerName: partner['display_name'] as String?,
        partnerId: partner['id'] as String?,
      );
    }
    
    return const ConnectionState();
  }

  Future<bool> connectWithCode(String code) async {
    state = AsyncValue.data(state.value!.copyWith(isLoading: true, error: null));
    
    try {
      final service = ref.read(supabaseServiceProvider);
      final success = await service.connectPartner(code);
      
      if (success) {
        final partner = await service.getPartnerProfile();
        state = AsyncValue.data(ConnectionState(
          isConnected: true,
          isLoading: false,
          partnerName: partner?['display_name'] as String?,
          partnerId: partner?['id'] as String?,
        ));
        return true;
      } else {
        state = AsyncValue.data(state.value!.copyWith(
          isLoading: false,
          error: 'Código não encontrado. Verifique com seu amor!',
        ));
        return false;
      }
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: 'Erro ao conectar. Tente novamente.',
      ));
      return false;
    }
  }
}

final connectionProvider = AsyncNotifierProvider<ConnectionNotifier, ConnectionState>(() {
  return ConnectionNotifier();
});
