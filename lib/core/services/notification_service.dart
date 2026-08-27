import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
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
  LocalStorageService? _storage;

  Future<void> initialize(GlobalKey<NavigatorState> navigatorKey, {LocalStorageService? storage}) async {
    if (_isInitialized) return;
    _navigatorKey = navigatorKey;
    _storage = storage;

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
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/launcher_icon');
    const initializationSettingsIOS = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        final payload = details.payload;
        if (payload != null && payload.isNotEmpty) {
          debugPrint('[Notifications] onDidReceiveNotificationResponse: $payload');
          _handleDeepLink(payload);
        }
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Check if app was launched via local notification when killed
    try {
      final launchDetails = await _localNotifications.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp ?? false) {
        final payload = launchDetails?.notificationResponse?.payload;
        if (payload != null && payload.isNotEmpty) {
          debugPrint('[Notifications] App launched via local notification with payload: $payload');
          _handleDeepLink(payload);
        }
      }
    } catch (e) {
      debugPrint('[Notifications] Error reading notification launch details: $e');
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      final extractedLink = _extractDeepLink(message);

      if (notification != null) {
        // Show System Heads-Up Notification Channel
        _localNotifications.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: extractedLink,
        );

        // Show our premium in-app custom notification banner
        _showInAppNotification(
          notification.title ?? 'New Alert',
          notification.body ?? '',
          extractedLink,
        );
      }
    });

    // 5. Handle Background Click (when app in background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[Notifications] onMessageOpenedApp: ${message.data}');
      final link = _extractDeepLink(message);
      if (link != null) {
        _handleDeepLink(link);
      }
    });

    // 6. Handle Terminated Click (when app was killed)
    try {
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('[Notifications] getInitialMessage (killed state): ${initialMessage.data}');
        final link = _extractDeepLink(initialMessage);
        if (link != null) {
          _handleDeepLink(link);
        }
      }
    } catch (e) {
      debugPrint('[Notifications] Error getting initial message: $e');
    }

    _isInitialized = true;

    // 7. Reactive Sync: Listen for token changes
    _storage?.addListener(_onStorageChanged);
    
    // Initial sync attempt
    _onStorageChanged();
    } catch (e) {
      debugPrint('[Notifications] Setup failed ❌: $e');
    }
  }

  String? _extractDeepLink(RemoteMessage message) {
    final data = message.data;
    if (data.containsKey('deepLink') && data['deepLink'] != null && data['deepLink'].toString().isNotEmpty) {
      return data['deepLink'].toString();
    }
    if (data.containsKey('link') && data['link'] != null && data['link'].toString().isNotEmpty) {
      return data['link'].toString();
    }
    if (data.containsKey('route') && data['route'] != null && data['route'].toString().isNotEmpty) {
      return data['route'].toString();
    }
    if (data.containsKey('url') && data['url'] != null && data['url'].toString().isNotEmpty) {
      return data['url'].toString();
    }
    if (data.containsKey('path') && data['path'] != null && data['path'].toString().isNotEmpty) {
      return data['path'].toString();
    }
    
    final notificationType = data['notificationType'] ?? data['type'];
    if (notificationType == 'linkRequest' || notificationType == 'linkAcceptance' || notificationType == 'parent_link') {
      return '/account/family';
    }
    if (notificationType == 'safetyAlert' || notificationType == 'sos') {
      return '/safety/sos';
    }
    if (notificationType == 'peerlineChat') {
      final sessionId = data['sessionId'];
      if (sessionId != null) return '/peerline/chat/$sessionId';
    }
    return null;
  }

  void _onStorageChanged() {
    final token = _storage?.authToken;
    if (token != null) {
      syncToken();
    }
  }

  Future<void> syncToken() async {
    final authToken = _storage?.authToken;
    if (authToken == null) return;

    try {
      final fcmToken = await _fcm.getToken();
      if (fcmToken != null) {
        debugPrint("[Notifications] Syncing FCM token...");
        await ApiService.instance.dio.post('/user/register-fcm-token', data: {
          'fcmToken': fcmToken,
        });
        debugPrint("[Notifications] FCM token registered ✅");
      }
    } catch (e) {
      // If it's a 401, we just ignore it here because ApiService interceptor will handle it
      debugPrint("[Notifications] FCM sync failed: $e");
    }
  }

  Future<void> unregisterToken() async {
    try {
      debugPrint("[Notifications] Unregistering FCM token on server...");
      await ApiService.instance.dio.post('/user/register-fcm-token', data: {
        'fcmToken': null,
      });
      debugPrint("[Notifications] FCM token unregistered successfully ✅");
    } catch (e) {
      debugPrint("[Notifications] FCM unregistration failed: $e");
    }
  }

  String? _pendingDeepLink;

  void _handleDeepLink(String? link) {
    if (link == null || link.trim().isEmpty) return;
    
    String path = link.trim();
    if (path.startsWith('infano://')) {
      path = path.replaceFirst('infano://', '/');
    } else if (path.startsWith('app://infano.care')) {
      path = path.replaceFirst('app://infano.care', '');
    }
    
    if (!path.startsWith('/')) {
      path = '/$path';
    }

    debugPrint('[Notifications] Deep link target: $path');

    final context = _navigatorKey.currentState?.context;
    if (context != null && context.mounted) {
      try {
        GoRouter.of(context).push(path);
        _pendingDeepLink = null;
      } catch (e) {
        debugPrint('[Notifications] Failed immediate push: $e, queuing retry');
        _pendingDeepLink = path;
        _retryPendingDeepLink();
      }
    } else {
      debugPrint('[Notifications] Navigator not mounted yet, storing pending link: $path');
      _pendingDeepLink = path;
      _retryPendingDeepLink();
    }
  }

  void _retryPendingDeepLink([int attempts = 0]) {
    if (_pendingDeepLink == null || attempts > 25) return;
    
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_pendingDeepLink == null) return;
      final context = _navigatorKey.currentState?.context;
      if (context != null && context.mounted) {
        final path = _pendingDeepLink!;
        _pendingDeepLink = null;
        debugPrint('[Notifications] Executing pending deep link navigation: $path');
        try {
          GoRouter.of(context).push(path);
        } catch (e) {
          debugPrint('[Notifications] Error navigating to $path: $e');
        }
      } else {
        _retryPendingDeepLink(attempts + 1);
      }
    });
  }

  void _showInAppNotification(String title, String body, String? deepLink) {
    final context = _navigatorKey.currentState?.context;
    if (context == null || !context.mounted) return;

    // Check if the user is already on the chat screen corresponding to this notification
    try {
      final GoRouter router = GoRouter.of(context);
      final String location = router.routerDelegate.currentConfiguration.last.matchedLocation;
      
      // If the incoming notification is for the chat they are currently viewing, don't show the toast
      if (deepLink != null) {
        final path = deepLink.replaceFirst('infano://', '/');
        final uri = Uri.parse(path);
        final segments = uri.pathSegments;
        if (segments.length >= 3 && segments[0] == 'friends' && segments[1] == 'chat' && location.contains('/friends/chat/')) {
          if (location.contains(segments[2])) return;
        }
        if (segments.length >= 3 && segments[0] == 'peerline' && segments[1] == 'chat' && location.contains('/peerline/chat/')) {
          if (location.contains(segments[2])) return;
        }
        if (segments.length >= 3 && segments[0] == 'expert' && segments[1] == 'chat' && location.contains('/expert/chat/')) {
          if (location.contains(segments[2])) return;
        }
      }
    } catch (_) {}

    late OverlayEntry overlayEntry;
    
    // We will build a beautiful Top-Sliding glassmorphic banner
    overlayEntry = OverlayEntry(
      builder: (context) {
        return _InAppNotificationBanner(
          title: title,
          body: body,
          onTap: () {
            overlayEntry.remove();
            if (deepLink != null) {
              _handleDeepLink(deepLink);
            }
          },
          onDismiss: () {
            overlayEntry.remove();
          },
        );
      },
    );

    Overlay.of(context).insert(overlayEntry);
  }

  late final GlobalKey<NavigatorState> _navigatorKey;
}

// Global background message handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling background message: ${message.messageId}");
}

class _InAppNotificationBanner extends StatefulWidget {
  final String title;
  final String body;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _InAppNotificationBanner({
    required this.title,
    required this.body,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_InAppNotificationBanner> createState() => _InAppNotificationBannerState();
}

class _InAppNotificationBannerState extends State<_InAppNotificationBanner> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _controller.forward();

    _dismissTimer = Timer(const Duration(seconds: 4), () {
      _dismiss();
    });
  }

  void _dismiss() {
    if (mounted) {
      _controller.reverse().then((_) {
        widget.onDismiss();
      });
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;

    return Positioned(
      top: topPadding + 12,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _offsetAnimation,
        child: GestureDetector(
          onTap: widget.onTap,
          onVerticalDragUpdate: (details) {
            if (details.primaryDelta! < -10) {
              _dismiss();
            }
          },
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6D28D9).withValues(alpha: 0.95),
                    const Color(0xFF4C1D95).withValues(alpha: 0.95),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chat_bubble_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.body,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                    onPressed: _dismiss,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
