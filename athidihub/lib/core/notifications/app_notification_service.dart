import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:athidihub/core/constants/app_constants.dart';
import 'package:athidihub/core/logging/app_logger.dart';
import 'package:athidihub/core/network/dio_provider.dart';
import 'package:athidihub/core/router/app_router.dart';

final appNotificationServiceProvider = Provider<AppNotificationService>((ref) {
  return AppNotificationService(ref.read(dioProvider));
});

class AppNotificationService {
  AppNotificationService(this._dio);

  static const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
    'athidihub_notifications',
    'Athidihub notifications',
    description: 'Important alerts and reminder notifications from Athidihub',
    importance: Importance.high,
  );

  final Dio _dio;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openAppSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;
  bool _initialized = false;
  String? _activeProfileId;
  String? _activeToken;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    await _initializeLocalNotifications();
    await _requestPermissions();
    _wireFirebaseListeners();
    _initialized = true;

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      AppLogger.info('Processing initial FCM message', data: initialMessage.data);
      _handleRoute(initialMessage.data);
    }
  }

  Future<void> bindProfile(String? profileId) async {
    final previousProfileId = _activeProfileId;
    _activeProfileId = profileId;

    if (profileId == null) {
      await _unregisterActiveToken(previousProfileId);
      return;
    }

    await syncCurrentToken(profileId);
  }

  Future<void> syncCurrentToken([String? profileId]) async {
    final effectiveProfileId = profileId ?? _activeProfileId;
    if (effectiveProfileId == null) {
      return;
    }

    final token = await _resolveToken();
    if (token == null || token.isEmpty) {
      AppLogger.warning('FCM token is unavailable, skipping registration', data: {
        'profileId': effectiveProfileId,
      });
      return;
    }

    _activeToken = token;
    await _registerToken(effectiveProfileId, token);
  }

  Future<void> unregisterActiveToken() async {
    await _unregisterActiveToken(_activeProfileId);
  }

  Future<void> _unregisterActiveToken(String? profileId) async {
    final token = _activeToken;
    if (profileId == null || token == null || token.isEmpty) {
      return;
    }

    try {
      await _dio.post(
        '/notifications/fcm/unregister',
        data: {'token': token},
      );
      AppLogger.info('Unregistered active FCM token', data: {
        'profileId': profileId,
      });
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Failed to unregister active FCM token',
        data: {'profileId': profileId},
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _activeToken = null;
    }
  }

  Future<void> dispose() async {
    await _foregroundSubscription?.cancel();
    await _openAppSubscription?.cancel();
    await _tokenRefreshSubscription?.cancel();
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    final androidImplementation = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.createNotificationChannel(_androidChannel);
  }

  Future<void> _requestPermissions() async {
    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    final localNotificationsAndroid = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await localNotificationsAndroid?.requestNotificationsPermission();
  }

  void _wireFirebaseListeners() {
    _foregroundSubscription = FirebaseMessaging.onMessage.listen(_showForegroundMessage);
    _openAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleRoute(message.data);
    });
    _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      _activeToken = token;
      final profileId = _activeProfileId;
      if (profileId != null) {
        unawaited(_registerToken(profileId, token));
      }
    });
  }

  Future<void> _registerToken(String profileId, String token) async {
    try {
      await _dio.post(
        '/notifications/fcm/register',
        data: {
          'token': token,
          'platform': _platformName(),
          'deviceId': await _deviceId(),
          'deviceName': _deviceName(),
          'appVersion': await _appVersion(),
          'locale': _locale(),
          'timezone': DateTime.now().timeZoneName,
        },
      );
      AppLogger.info('Registered FCM token', data: {
        'profileId': profileId,
        'platform': _platformName(),
      });
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Failed to register FCM token',
        data: {'profileId': profileId},
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<String?> _resolveToken() async {
    if (kIsWeb) {
      const vapidKey = AppConstants.firebaseWebVapidKey;
      if (vapidKey.isEmpty) {
        return FirebaseMessaging.instance.getToken();
      }

      return FirebaseMessaging.instance.getToken(vapidKey: vapidKey);
    }

    return FirebaseMessaging.instance.getToken();
  }

  void _showForegroundMessage(RemoteMessage message) {
    AppLogger.info('Received FCM message', data: message.data);
    unawaited(_showLocalNotification(message));
  }

  void _handleNotificationResponse(NotificationResponse response) {
    if (response.payload == null || response.payload!.isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(response.payload!) as Map<String, dynamic>;
      _handleRoute(decoded);
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Failed to decode notification payload',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title']?.toString() ?? 'Athidihub';
    final body = notification?.body ?? message.data['body']?.toString() ?? '';

    if (title.isEmpty && body.isEmpty) {
      return;
    }

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _androidChannel.id,
        _androidChannel.name,
        channelDescription: _androidChannel.description,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
    );

    await _localNotifications.show(
      message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      title,
      body,
      details,
      payload: jsonEncode(message.data),
    );
  }

  void _handleRoute(Map<String, dynamic> data) {
    final route = data['route']?.toString();
    if (route == null || route.isEmpty) {
      return;
    }

    final context = rootNavigatorKey.currentContext;
    if (context == null) {
      AppLogger.warning('Could not route notification tap because root context is unavailable', data: data);
      return;
    }

    AppLogger.info('Routing notification tap', data: {'route': route});
    context.go(route);
  }

  Future<String?> _deviceId() async {
    return kIsWeb ? 'web' : null;
  }

  String _deviceName() {
    if (kIsWeb) {
      return 'web';
    }

    return defaultTargetPlatform.name;
  }

  Future<String?> _appVersion() async {
    return null;
  }

  String _locale() {
    return PlatformDispatcher.instance.locale.toLanguageTag();
  }

  String _platformName() {
    if (kIsWeb) {
      return 'web';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'web';
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return 'web';
    }
  }
}
