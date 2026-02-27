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

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // Initialize Notifications
  final notificationService = NotificationService();
  await notificationService.init();

  // Initialize RevenueCat (In-App Purchases)
  await PurchaseService.init();
  
  // Do not await permission request here to avoid blocking UI render (white screen deadlock on iOS)
  notificationService.requestPermissions();
  
  notificationService.startListening();

  runApp(
    const ProviderScope(
      child: EntreNosApp(),
    ),
  );
}
