import 'dart:io' show Platform;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 Background message: ${message.messageId}');
}

/// Service for managing push notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;

  /// Global navigator key — set from main.dart via GoRouter
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    debugPrint('🔔 Initializing NotificationService...');
    
    // Request permission
    await _requestPermission();
    
    // Initialize local notifications
    await _initLocalNotifications();
    
    // Set up foreground message handler
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    
    // Handle notification tap when app is in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    
    // Check if app was opened from a notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
    
    _isInitialized = true;
    debugPrint('🔔 NotificationService initialized');
  }

  /// Request notification permissions
  Future<bool> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    
    final isAuthorized = settings.authorizationStatus == AuthorizationStatus.authorized ||
                          settings.authorizationStatus == AuthorizationStatus.provisional;
    
    debugPrint('🔔 Notification permission: ${settings.authorizationStatus}');
    return isAuthorized;
  }

  /// Initialize local notifications for foreground display
  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
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
        debugPrint('🔔 Local notification tapped: ${response.payload}');
        _navigateFromPayload(response.payload);
      },
    );
    
    // Create notification channel for Android (skip on web)
    if (!kIsWeb && Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'wain_offers',
        'عروض وين',
        description: 'إشعارات العروض والخصومات الجديدة',
        importance: Importance.high,
      );
      
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('🔔 Foreground message: ${message.notification?.title}');
    
    final notification = message.notification;
    if (notification != null) {
      // Encode navigation data as payload
      String? payload;
      if (message.data.containsKey('offer_id')) {
        payload = 'offer:${message.data['offer_id']}';
      } else if (message.data.containsKey('venue_id')) {
        payload = 'venue:${message.data['venue_id']}';
      }

      showLocalNotification(
        title: notification.title ?? 'وين',
        body: notification.body ?? '',
        payload: payload,
      );
    }
  }

  /// Handle notification tap (from background/terminated)
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('🔔 Notification tapped: ${message.data}');
    
    final data = message.data;
    
    // Wait for app to be ready, then navigate
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = navigatorKey.currentContext;
      if (context == null) {
        debugPrint('🔔 No navigator context available yet');
        return;
      }
      
      if (data.containsKey('offer_id')) {
        final offerId = data['offer_id'];
        debugPrint('🔔 Navigating to offer: $offerId');
        GoRouter.of(context).push('/offer/$offerId');
      } else if (data.containsKey('venue_id')) {
        final venueId = data['venue_id'];
        debugPrint('🔔 Navigating to venue: $venueId');
        GoRouter.of(context).push('/venue/$venueId');
      }
    });
  }
  
  /// Navigate from local notification payload
  void _navigateFromPayload(String? payload) {
    if (payload == null) return;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = navigatorKey.currentContext;
      if (context == null) return;
      
      if (payload.startsWith('offer:')) {
        final offerId = payload.substring(6);
        GoRouter.of(context).push('/offer/$offerId');
      } else if (payload.startsWith('venue:')) {
        final venueId = payload.substring(6);
        GoRouter.of(context).push('/venue/$venueId');
      }
    });
  }

  /// Show local notification
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'wain_offers',
      'عروض وين',
      channelDescription: 'إشعارات العروض والخصومات الجديدة',
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

  /// Get FCM token
  Future<String?> getToken() async {
    final token = await _messaging.getToken();
    debugPrint('🔔 FCM Token: $token');
    return token;
  }

  /// Save FCM token to user's Firestore document
  Future<void> saveTokenToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return;
    
    final token = await getToken();
    if (token == null) return;
    
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
            'fcm_token': token,
            'fcm_token_updated_at': FieldValue.serverTimestamp(),
            'platform': kIsWeb ? 'web' : (Platform.isIOS ? 'ios' : 'android'),
          }, SetOptions(merge: true));
      
      debugPrint('🔔 FCM token saved to Firestore');
    } catch (e) {
      debugPrint('❌ Error saving FCM token: $e');
    }
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('🔔 Subscribed to topic: $topic');
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('🔔 Unsubscribed from topic: $topic');
  }
}
