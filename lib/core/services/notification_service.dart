import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../network/supabase_service.dart';
import 'auth_service.dart';

/// Top-level handler para mensagens FCM em background (exigido pelo Firebase)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background FCM: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final SupabaseService _supabaseService = SupabaseService();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  StreamSubscription? _drawingSubscription;
  bool _isInitialized = false;

  // ---------------------------------------------------------------
  // INIT
  // ---------------------------------------------------------------

  Future<void> init() async {
    if (_isInitialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
    );

    // Assinatura correta: initialize({required InitializationSettings settings, ...})
    await _notifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Handler de background FCM
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Mensagens com app em foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        showNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: message.notification!.title ?? 'Novo carinho! 💕',
          body: message.notification!.body ?? 'Seu amor enviou algo especial.',
        );
      }
    });

    _isInitialized = true;
    debugPrint('NotificationService: inicializado.');
  }

  // ---------------------------------------------------------------
  // PERMISSIONS + FCM TOKEN
  // ---------------------------------------------------------------

  Future<bool> requestPermissions() async {
    final status = await Permission.notification.request();
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    try {
      final token = await _fcm.getToken();
      if (token != null) {
        final authService = AuthService();
        if (authService.isAuthenticated) {
          await authService.savePushToken(token);
        }
      }
    } catch (e) {
      debugPrint('Erro ao obter FCM token: $e');
    }

    _fcm.onTokenRefresh.listen((newToken) async {
      final authService = AuthService();
      if (authService.isAuthenticated) {
        await authService.savePushToken(newToken);
      }
    });

    return status.isGranted;
  }

  // ---------------------------------------------------------------
  // SHOW LOCAL NOTIFICATION
  // ---------------------------------------------------------------

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'entrenos_drawings',
      'Desenhos',
      channelDescription: 'Notificações de novos desenhos do seu amor',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFFF4DA3),
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );

    // Assinatura correta: show({required int id, String? title, String? body, NotificationDetails? notificationDetails})
    await _notifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  // ---------------------------------------------------------------
  // REALTIME — Supabase drawing listener
  // ---------------------------------------------------------------

  void startListening() {
    _drawingSubscription?.cancel();
    _drawingSubscription = _supabaseService.listenForNewDrawings().listen(
      (drawing) {
        if (drawing.isNotEmpty) _onNewDrawingReceived(drawing);
      },
      onError: (error) => debugPrint('Erro ao ouvir desenhos: $error'),
    );
    debugPrint('NotificationService: ouvindo novos desenhos.');
  }

  void stopListening() {
    _drawingSubscription?.cancel();
    _drawingSubscription = null;
  }

  void _onNewDrawingReceived(Map<String, dynamic> drawing) {
    final createdAt = DateTime.tryParse(drawing['created_at'] ?? '');
    if (createdAt != null &&
        DateTime.now().difference(createdAt).inSeconds < 30) {
      showNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: 'Novo carinho recebido! 💕',
        body: 'Seu amor enviou um desenho pra você. Toque para ver!',
      );
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notificação tocada: ${response.payload}');
  }

  void dispose() => stopListening();
}
