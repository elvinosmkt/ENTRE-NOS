import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app.dart';
import 'core/config/supabase_config.dart';
import 'core/services/notification_service.dart';
import 'core/services/purchase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (protegido contra crash)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase init error (non-fatal): $e');
  }

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // Initialize Notifications (protegido)
  final notificationService = NotificationService();
  try {
    await notificationService.init();
  } catch (e) {
    debugPrint('NotificationService init error: $e');
  }

  // Initialize RevenueCat (In-App Purchases) — protegido
  try {
    await PurchaseService.init();
  } catch (e) {
    debugPrint('PurchaseService init error: $e');
  }
  
  // Do not await permission request here to avoid blocking UI render
  notificationService.requestPermissions();
  
  notificationService.startListening();

  runApp(
    const ProviderScope(
      child: EntreNosApp(),
    ),
  );
}
