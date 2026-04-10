import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:infano_care_mobile/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FirebaseMessaging get _fcm => FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_priority_channel', // id
    'High Priority Notifications', // title
    description: 'This channel is used for important cycle alerts.', // description
    importance: Importance.max,
  );

  bool _isInitialized = false;

  Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    if (_isInitialized) return;
    _navigatorKey = navigatorKey;

    try {
      // 1. Check if Firebase is available
      if (Firebase.apps.isEmpty) {
        debugPrint('[Notifications] Firebase not initialized. Skipping FCM setup.');
        return;
      }

      // 2. Request Permissions
      await _fcm.requestPermission(
      alert: true,
      badge: true,
      provisional: false,
      sound: true,
    );

    // 3. Setup Local Notifications for Foreground
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        final payload = details.payload;
        if (payload != null) {
          _handleDeepLink(payload);
        }
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 4. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        _localNotifications.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              icon: android.smallIcon,
            ),
          ),
          payload: message.data['deepLink'],
        );
      }
    });

    // 5. Handle Background/Terminated Click
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleDeepLink(message.data['deepLink']);
    });

    _isInitialized = true;
    _syncToken();
    } catch (e) {
      debugPrint('[Notifications] Setup failed ❌: $e');
    }
  }

  Future<void> _syncToken() async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        debugPrint("FCM Token: $token");
        await ApiService.instance.dio.post('/user/register-fcm-token', data: {
          'fcmToken': token,
        });
      }
    } catch (e) {
      debugPrint("Failed to sync FCM token: $e");
    }
  }

  void _handleDeepLink(String? link) {
    if (link != null && link.startsWith('infano://')) {
      final path = link.replaceFirst('infano://', '/');
      final context = _navigatorKey.currentState?.context;
      if (context != null) {
        GoRouter.of(context).push(path);
      }
    }
  }

  late final GlobalKey<NavigatorState> _navigatorKey;
}

// Global background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling background message: ${message.messageId}");
}
