import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/purchase_service.dart';
import '../../../core/services/auth_service.dart';

class SubscriptionNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    // Vincular o ID do Supabase ao RevenueCat se logado
    final authService = AuthService();
    if (authService.isAuthenticated) {
      await PurchaseService.login(authService.currentUserId!);
    }
    
    return PurchaseService.isPremiumActive();
  }

  Future<void> purchase() async {
    state = const AsyncValue.loading();
    try {
      final success = await PurchaseService.purchasePremium();
      state = AsyncValue.data(success);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> restore() async {
    state = const AsyncValue.loading();
    try {
      final success = await PurchaseService.restorePurchases();
      state = AsyncValue.data(success);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Método para uso interno (debug/reset)
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(await PurchaseService.isPremiumActive());
  }
}

final subscriptionProvider = AsyncNotifierProvider<SubscriptionNotifier, bool>(() {
  return SubscriptionNotifier();
});
