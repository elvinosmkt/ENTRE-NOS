import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PurchaseService {
  // API Key do RevenueCat (obtida do dashboard: app.revenuecat.com)
  // Nota: esta é a key de TESTE. Quando publicar, gere uma key de PRODUÇÃO no dashboard.
  static const _appleApiKey = 'test_jjnphsAEnTKjkyABBRqmEJLl0gW';
  static const _entitlementId = 'premium';

  static bool _initialized = false;

  static Future<void> init() async {
    // Só funciona em iOS/Android — ignora silenciosamente em macOS/simulador sem crash
    if (!Platform.isIOS && !Platform.isAndroid) {
      debugPrint('PurchaseService: plataforma não suportada, ignorando.');
      return;
    }

    if (kDebugMode) {
      await Purchases.setLogLevel(LogLevel.debug);
    }

    late PurchasesConfiguration configuration;
    if (Platform.isIOS) {
      configuration = PurchasesConfiguration(_appleApiKey);
    } else {
      return;
    }

    await Purchases.configure(configuration);
    _initialized = true;
    debugPrint('PurchaseService: RevenueCat inicializado.');
  }

  /// Verifica se o usuário tem a assinatura ativa
  static Future<bool> isPremiumActive() async {
    if (!_initialized) return false;
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all[_entitlementId]?.isActive ?? false;
    } catch (e) {
      debugPrint('Erro ao verificar status de assinatura: $e');
      return false;
    }
  }

  /// Realiza a compra do pacote pro (mensal/anual esperado no RevenueCat)
  static Future<bool> purchasePremium() async {
    if (!_initialized) {
      debugPrint('PurchaseService não inicializado. Configure a API Key do RevenueCat.');
      return false;
    }
    try {
      final offerings = await Purchases.getOfferings();
      if (offerings.current != null && offerings.current!.monthly != null) {
        final result = await Purchases.purchasePackage(offerings.current!.monthly!);
        // purchasePackage retorna PurchaseResult que contém customerInfo
        return result.customerInfo.entitlements.all[_entitlementId]?.isActive ?? false;
      }
      debugPrint('Nenhuma oferta disponível no RevenueCat.');
      return false;
    } catch (e) {
      debugPrint('Erro ao processar compra: $e');
      return false;
    }
  }

  /// Restaura compras anteriores
  static Future<bool> restorePurchases() async {
    if (!_initialized) return false;
    try {
      final customerInfo = await Purchases.restorePurchases();
      return customerInfo.entitlements.all[_entitlementId]?.isActive ?? false;
    } catch (e) {
      debugPrint('Erro ao restaurar compras: $e');
      return false;
    }
  }

  /// Faz o login do usuário no RevenueCat vinculando ao ID do Supabase
  static Future<void> login(String userId) async {
    if (!_initialized) return;
    await Purchases.logIn(userId);
  }

  /// Logout
  static Future<void> logout() async {
    if (!_initialized) return;
    await Purchases.logOut();
  }
}
