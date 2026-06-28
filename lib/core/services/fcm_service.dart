import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  late final FirebaseMessaging _firebaseMessaging;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    if (kIsWeb) {
      print('FCM is not fully configured for Web yet. Skipping push notification setup.');
      _isInitialized = true;
      return;
    }

    try {
      await Firebase.initializeApp();
      _firebaseMessaging = FirebaseMessaging.instance;
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Request permission
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted FCM permission');
        
        // Setup local notifications for foreground display
        const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
        const initSettings = InitializationSettings(android: androidInit);
        await _localNotifications.initialize(settings: initSettings);

        // Listen to messages in foreground
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          _showLocalNotification(message);
        });

        // Get and save token initially if already logged in
        final token = await _firebaseMessaging.getToken();
        if (token != null) {
          await _saveTokenToSupabase(token);
        }

        // Listen to Auth state changes so we save token when user logs in
        Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
          final AuthChangeEvent event = data.event;
          if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.initialSession) {
            final currentToken = await _firebaseMessaging.getToken();
            if (currentToken != null) {
              await _saveTokenToSupabase(currentToken);
            }
          }
        });

        // Listen for token refreshes
        _firebaseMessaging.onTokenRefresh.listen((newToken) {
          _saveTokenToSupabase(newToken);
        });
      }
      _isInitialized = true;
    } catch (e) {
      print('FCM Init Error: $e');
    }
  }

  Future<void> _saveTokenToSupabase(String token) async {
    try {
      final supabase = Supabase.instance.client;
      if (supabase.auth.currentUser != null) {
        await supabase.rpc('upsert_fcm_token', params: {
          'p_token': token,
          'p_device_info': Platform.operatingSystem,
        });
        print('Saved FCM Token: $token');
      }
    } catch (e) {
      print('Save FCM Token Error: $e');
    }
  }

  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && android != null) {
      _localNotifications.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'gymfit_high_importance_channel',
            'GymFit Notifications',
            channelDescription: 'Thông báo quan trọng từ GymFit',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    }
  }
}
