// lib/firebase_notification_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';

import '../firebase_bg_handler.dart'; // top-level bg handler (firebaseMessagingBackgroundHandler)
import '../AppData/AppConstants.dart';
import '../main.dart';


import '../view/dashboard.dart'; // DashboardPage
import '/model/sys_user.dart';   // SysUser model

class FirebaseNotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  static String? _currentToken;
  static int? _registeredUserId;

  // ✅ store the current logged-in SysUser for DashboardPage
  static SysUser? _currentSysUser;
  static void setCurrentUser(SysUser user) {
    _currentSysUser = user;
  }

  /// Call this once on app startup (e.g., main())
  static Future<void> initialize() async {
    debugPrint('🟡 Initializing Firebase Notifications...');

    try {
      // 0) Register BG handler (TOP-LEVEL)
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 1) Local notifications (channel, init, tap handler)
      await _initializeLocalNotifications();

      // 2) Ask permission
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      debugPrint('✅ User permission: ${settings.authorizationStatus}');

      // 3) Token
      _currentToken = await _firebaseMessaging.getToken();
      debugPrint('🔑 FCM Token: $_currentToken');

      // 4) Token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        debugPrint('🔄 Token refreshed: $newToken');
        _currentToken = newToken;
        if (_registeredUserId != null) {
          await registerToken(_registeredUserId!);
        }
      });

      // 5) Foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        debugPrint('📱 Foreground message received!');
        _logMessageDetails(message);
        await _handleForegroundMessage(message);
      });

      // 6) App opened from terminated via notification
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('🚀 App opened from terminated via notification');
        _logMessageDetails(initialMessage);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleMessageNavigation(initialMessage); // 👉 will go to Dashboard
        });
      }

      // 7) App opened from background via notification tap
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('📬 App opened from background via notification tap');
        _logMessageDetails(message);
        _handleMessageNavigation(message); // 👉 will go to Dashboard
      });

      debugPrint('✅ Firebase Notifications initialized successfully');
    } catch (e, st) {
      debugPrint('❌ Error initializing Firebase: $e\n$st');
    }
  }

  // ----------------- Local notifications -----------------

  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('👆 Notification tapped! Payload: ${response.payload}');
        _handleNotificationTap(response.payload); // 👉 will go to Dashboard
      },
    );

    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications',
        importance: Importance.max,
        playSound: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    debugPrint('✅ Local notifications initialized');
  }

  // ----------------- BG handler bridge (called by top-level) -----------------

  /// Called by the top-level background handler to reuse your logic.
  static void handleBackground(RemoteMessage message) {
    debugPrint('📱 [BG bridge] message: ${message.messageId}');
    _logMessageDetails(message);

    // Store to history even if BG
    final title =
        message.notification?.title ?? message.data['title'] ?? 'Notification';
    final body = message.notification?.body ?? message.data['body'] ?? '';

  }

  // ----------------- Navigation helpers (ALWAYS DASHBOARD) -----------------

  static void _handleNotificationTap(String? payload) {
    // Ignore payload, always route to dashboard
    _goToDashboard();
  }

  static void _handleMessageNavigation(RemoteMessage message) {
    // Ignore payload, always route to dashboard
    _goToDashboard();
  }

  static void _handleMessageNavigationFromData(Map<String, dynamic> data) {
    // Ignore payload, always route to dashboard
    _goToDashboard();
  }

  static void _goToDashboard() {
    if (navigatorKey.currentState == null) {
      debugPrint('❌ navigatorKey.currentState is null; cannot navigate.');
      return;
    }

    if (_currentSysUser == null) {
      debugPrint('⚠️ current SysUser is null; pop to root as fallback.');
      navigatorKey.currentState!.popUntil((route) => route.isFirst);
      return;
    }

    // Clear the stack and go to DashboardPage(sysUser: ...)
    navigatorKey.currentState!.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => DashboardPage(sysUser: _currentSysUser!),
      ),
          (route) => false,
    );


  }

  // ----------------- Foreground display -----------------

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      String title;
      String body;

      if (message.data.containsKey('title') || message.data.containsKey('body')) {
        title = message.data['title'] ?? 'Case Update';
        body = message.data['body'] ?? 'Your case has been updated';
      } else if (message.notification != null) {
        title = message.notification!.title ?? 'No Title';
        body = message.notification!.body ?? 'No Body';
      } else {
        title = 'Case Update';
        body = 'Your case has been updated';
      }



      const androidDetails = AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'This channel is used for important notifications',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        showWhen: true,
        colorized: true,
        color: Color(0xFFD32F2F),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);

      await _localNotifications.show(
        id,
        title,
        body,
        details,
        payload: jsonEncode(message.data), // even if ignored, it's OK to keep
      );

      debugPrint('✅ Foreground notification displayed (ID: $id)');
    } catch (e, st) {
      debugPrint('❌ Foreground error: $e\n$st');
    }
  }

  // ----------------- History helpers -----------------

  static final List<RemoteMessage> _pendingNotifications = [];



  static void _storePendingNotification(RemoteMessage message) {
    _pendingNotifications.add(message);
    debugPrint('📦 Stored pending notification: ${message.messageId}');
  }



  // ----------------- Token register/unregister -----------------

  static Future<void> registerToken(int userId) async {
    try {
      debugPrint('🟡 Registering token for user $userId...');
      _currentToken ??= await _firebaseMessaging.getToken();

      if ((_currentToken ?? '').isEmpty) {
        debugPrint('❌ No FCM token available yet.');
        return;
      }

      final url = '${AppConstants.BASE_URI}/FirebaseToken/register';
      final body = {
        'userID': userId, // ⚠️ sysUserID
        'deviceToken': _currentToken,
        'platform': Platform.isAndroid ? 'Android' : 'iOS',
        'deviceID': _getDeviceId(),
      };

      // 🧪 Extra logging starts here
      debugPrint('➡️ POST $url');
      debugPrint('   Body: $body');

      final resp = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      debugPrint('⬅️ ${resp.statusCode} ${resp.reasonPhrase}');
      debugPrint('   Body: ${resp.body}');
      // 🧪 Extra logging ends here

      if (resp.statusCode == 200) {
        _registeredUserId = userId;
        debugPrint('✅ Token registered for user $userId');
      } else {
        debugPrint('❌ Register failed: ${resp.statusCode} - ${resp.body}');
      }
    } catch (e, st) {
      debugPrint('❌ Register token error: $e\n$st');
    }
  }


  static Future<void> unregisterToken() async {
    try {
      if ((_currentToken ?? '').isEmpty) return;

      final resp = await http.post(
        Uri.parse('${AppConstants.BASE_URI}/FirebaseToken/unregister'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'deviceToken': _currentToken}),
      );

      if (resp.statusCode == 200) {
        _registeredUserId = null;
        debugPrint('✅ Token unregistered');
      } else {
        debugPrint('❌ Unregister failed: ${resp.statusCode} - ${resp.body}');
      }
    } catch (e, st) {
      debugPrint('❌ Unregister token error: $e\n$st');
    }
  }

  // ----------------- Utils -----------------

  static String _getDeviceId() =>
      '${Platform.operatingSystem}_${DateTime.now().millisecondsSinceEpoch}';

  static void _logMessageDetails(RemoteMessage message) {
    debugPrint('''
📨 NOTIFICATION DETAILS:
   Title: ${message.notification?.title}
   Body: ${message.notification?.body}
   Data: ${message.data}
   Message ID: ${message.messageId}
''');
  }

  static void printDebugInfo() {
    debugPrint('''
🔍 FIREBASE DEBUG INFO:
   Current Token: $_currentToken
   Registered User ID: $_registeredUserId
   Platform: ${Platform.operatingSystem}
   Initialized: ${_currentToken != null}
''');
  }

  static String? getCurrentToken() => _currentToken;
  static int? getRegisteredUserId() => _registeredUserId;
}
