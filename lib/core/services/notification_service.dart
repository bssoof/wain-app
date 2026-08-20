import 'dart:async';
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import 'platform_logger.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  PlatformLogger.info(
    'notifications',
    'Background message received: ${message.messageId}',
  );
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  bool get _isWindows => !kIsWeb && Platform.isWindows;
  bool get _supportsFirebaseMessaging => !_isWindows;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    if (!_supportsFirebaseMessaging) {
      PlatformLogger.warn(
        'notifications',
        'Skipping Firebase Messaging initialization on Windows.',
        platform: 'windows',
      );
      _isInitialized = true;
      return;
    }

    PlatformLogger.info('notifications', 'Initializing NotificationService...');

    await _requestPermission();
    await _initLocalNotifications();

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    _listenForTokenUpdates();

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    _isInitialized = true;
    PlatformLogger.info('notifications', 'NotificationService initialized.');
  }

  void _listenForTokenUpdates() {
    _authSubscription ??= FirebaseAuth.instance.authStateChanges().listen((
      user,
    ) {
      if (user != null && !user.isAnonymous) {
        unawaited(saveTokenToFirestore());
      }
    });

    _tokenRefreshSubscription ??= _messaging.onTokenRefresh.listen((_) {
      unawaited(saveTokenToFirestore());
    });
  }

  Future<bool> _requestPermission() async {
    if (!_supportsFirebaseMessaging) {
      return false;
    }

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    final isAuthorized =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    PlatformLogger.info(
      'notifications',
      'Permission status: ${settings.authorizationStatus}',
    );
    return isAuthorized;
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        PlatformLogger.info(
          'notifications',
          'Local notification tapped: ${response.payload}',
        );
        _navigateFromPayload(response.payload);
      },
    );

    if (!kIsWeb && Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'wain_offers',
        'Wain Offers',
        description: 'Notifications for offers and discounts',
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    PlatformLogger.info(
      'notifications',
      'Foreground message: ${message.notification?.title}',
    );

    final notification = message.notification;
    if (notification == null) {
      return;
    }

    String? payload;
    if (message.data.containsKey('offer_id')) {
      payload = 'offer:${message.data['offer_id']}';
    } else if (message.data.containsKey('venue_id')) {
      payload = 'venue:${message.data['venue_id']}';
    }

    showLocalNotification(
      title: notification.title ?? 'Wain',
      body: notification.body ?? '',
      payload: payload,
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    PlatformLogger.info(
      'notifications',
      'Notification tapped: ${message.data}',
    );

    final data = message.data;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = navigatorKey.currentContext;
      if (context == null) {
        PlatformLogger.warn(
          'notifications',
          'Navigator context is not ready yet.',
        );
        return;
      }

      if (data.containsKey('offer_id')) {
        final offerId = data['offer_id'];
        GoRouter.of(context).push('/offer/$offerId');
      } else if (data.containsKey('venue_id')) {
        final venueId = data['venue_id'];
        GoRouter.of(context).push('/venue/$venueId');
      }
    });
  }

  void _navigateFromPayload(String? payload) {
    if (payload == null || payload.isEmpty) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = navigatorKey.currentContext;
      if (context == null) {
        return;
      }

      if (payload.startsWith('offer:')) {
        final offerId = payload.substring(6);
        GoRouter.of(context).push('/offer/$offerId');
      } else if (payload.startsWith('venue:')) {
        final venueId = payload.substring(6);
        GoRouter.of(context).push('/venue/$venueId');
      }
    });
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_supportsFirebaseMessaging) {
      PlatformLogger.info(
        'notifications',
        'Skipping local notification display on Windows.',
        platform: 'windows',
      );
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'wain_offers',
      'Wain Offers',
      channelDescription: 'Notifications for offers and discounts',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  Future<String?> getToken() async {
    if (!_supportsFirebaseMessaging) {
      PlatformLogger.info(
        'notifications',
        'Skipping FCM token fetch on Windows.',
        platform: 'windows',
      );
      return null;
    }

    final token = await _messaging.getToken();
    PlatformLogger.info('notifications', 'FCM token fetched.');
    return token;
  }

  Future<void> saveTokenToFirestore() async {
    if (!_supportsFirebaseMessaging) {
      PlatformLogger.info(
        'notifications',
        'Skipping token save on Windows.',
        platform: 'windows',
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      return;
    }

    try {
      final token = await getToken();
      if (token == null) {
        return;
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fcm_token': token,
        'fcm_token_updated_at': FieldValue.serverTimestamp(),
        'platform': kIsWeb
            ? 'web'
            : (Platform.isIOS
                  ? 'ios'
                  : (Platform.isAndroid ? 'android' : 'desktop')),
      }, SetOptions(merge: true));

      PlatformLogger.info('notifications', 'FCM token saved to Firestore.');
    } catch (e, st) {
      PlatformLogger.error(
        'notifications',
        'Failed to save FCM token to Firestore.',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    if (!_supportsFirebaseMessaging) {
      PlatformLogger.info(
        'notifications',
        'Skipping topic subscribe ($topic) on Windows.',
        platform: 'windows',
      );
      return;
    }
    await _messaging.subscribeToTopic(topic);
    PlatformLogger.info('notifications', 'Subscribed to topic: $topic');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    if (!_supportsFirebaseMessaging) {
      PlatformLogger.info(
        'notifications',
        'Skipping topic unsubscribe ($topic) on Windows.',
        platform: 'windows',
      );
      return;
    }
    await _messaging.unsubscribeFromTopic(topic);
    PlatformLogger.info('notifications', 'Unsubscribed from topic: $topic');
  }
}
