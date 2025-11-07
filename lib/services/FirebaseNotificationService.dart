import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:roadside_ast/AppData/AppConstants.dart';
import 'package:roadside_ast/main.dart';

import '../provider/NotificationProvider.dart';
import '../view/dashboard.dart'; // 🎯 ADD THIS IMPORT to access navigatorKey

class FirebaseNotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static String? _currentToken;
  static int? _registeredUserId;

  static Future<void> initialize() async {
    print('🟡 Initializing Firebase Notifications...');

    try {
      // Initialize local notifications first
      await _initializeLocalNotifications();

      // Request permission
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      print('✅ User granted permission: ${settings.authorizationStatus}');

      // Get token
      String? token = await _firebaseMessaging.getToken();
      _currentToken = token;
      print('🔑 FCM Token: $token');

      // Token refresh listener
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        print('🔄 Token refreshed: $newToken');
        _currentToken = newToken;
        if (_registeredUserId != null) {
          registerToken(_registeredUserId!);
        }
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('📱 Foreground message received!');
        _logMessageDetails(message);
        _handleForegroundMessage(message);
      });

      // Handle when app is opened from terminated state
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        print('🚀 App opened from terminated state with message');
        _logMessageDetails(initialMessage);
        // Wait for app to be fully built before navigating
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleMessageNavigation(initialMessage);
        });
      }

      // Handle when app is in background and opened via notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('📬 App opened from background via notification');
        _logMessageDetails(message);
        _handleMessageNavigation(message);
      });
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
      print('✅ Firebase Notifications initialized successfully');

    } catch (e) {
      print('❌ Error initializing Firebase: $e');
    }
  }

  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Handle notification taps
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('👆 Notification tapped! Payload: ${response.payload}');
        _handleNotificationTap(response.payload);
      },
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications',
        importance: Importance.max,
        playSound: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    print('✅ Local notifications initialized');
  }

  static void _handleNotificationTap(String? payload) {
    print('👆 Handling notification tap with payload: $payload');

    if (payload != null && payload.isNotEmpty) {
      try {
        final data = jsonDecode(payload) as Map<String, dynamic>;
        print('📊 Parsed notification data: $data');
        _handleMessageNavigationFromData(data);
      } catch (e) {
        print('❌ Error parsing notification payload: $e');
      }
    } else {
      print('⚠️ No payload received from notification tap');
    }
  }

  static void _handleMessageNavigationFromData(Map<String, dynamic> data) {
    print('🧭 Handling navigation from data: $data');

    final caseId = data['caseId']?.toString();
    final type = data['type']?.toString();

    print('🔍 Extracted - Case ID: $caseId, Type: $type');

    if (caseId != null && caseId.isNotEmpty) {
      final parsedCaseId = int.tryParse(caseId);
      if (parsedCaseId != null) {
        _navigateToCaseDetails(parsedCaseId);
      } else {
        print('❌ Could not parse caseId: $caseId');
      }
    } else {
      print('❌ No caseId found in notification data');
    }
  }

  static void _handleMessageNavigation(RemoteMessage message) {
    print('🧭 Handling message navigation');
    _handleMessageNavigationFromData(message.data);
  }

  static void _navigateToCaseDetails(int caseId) {
    print('➡️ Attempting to navigate to case details: $caseId');

    if (navigatorKey.currentState == null) {
      print('❌ Navigator key currentState is null');
      return;
    }

    if (navigatorKey.currentContext == null) {
      print('❌ Navigator key currentContext is null');
      return;
    }

    try {
      // Import your CaseDetailsScreen and navigate to it
      navigatorKey.currentState!.push(
        MaterialPageRoute(
          builder: (context) => CaseDetailsScreen(caseId: caseId),
        ),
      );
      print('✅ Successfully navigated to case details: $caseId');
    } catch (e) {
      print('❌ Navigation error: $e');
    }
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      print('🎯 Processing foreground message...');

      String title;
      String body;

      // 🎯 PRIORITIZE DATA PAYLOAD OVER NOTIFICATION PAYLOAD
      if (message.data.containsKey('title') || message.data.containsKey('body')) {
        title = message.data['title'] ?? 'Case Update';
        body = message.data['body'] ?? 'Your case has been updated';
        print('✅ Using DATA payload (custom messages)');
      } else if (message.notification != null) {
        title = message.notification!.title ?? 'No Title';
        body = message.notification!.body ?? 'No Body';
        print('⚠️ Using NOTIFICATION payload (fallback)');
      } else {
        title = 'Case Update';
        body = 'Your case has been updated';
        print('🔶 Using default fallback');
      }

      print('📢 Final Title: "$title"');
      print('📢 Final Body: "$body"');

      // 🎯 ADD TO NOTIFICATION HISTORY
      _addToNotificationHistory(message, title, body);

      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
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

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

      await _localNotifications.show(
        notificationId,
        title,
        body,
        details,
        payload: jsonEncode(message.data),
      );

      print('✅ Foreground notification displayed! ID: $notificationId');

    } catch (e) {
      print('❌ Error in foreground message: $e');
    }
  }

// 🎯 NEW METHOD: Add notification to history
  static void _addToNotificationHistory(RemoteMessage message, String title, String body) {
    try {
      // Get the provider using navigatorKey - FIXED VERSION
      if (navigatorKey.currentContext != null) {
        final notificationProvider = Provider.of<NotificationProvider>(
            navigatorKey.currentContext!,
            listen: false
        );
        notificationProvider.addNotification(message);
        print('📝 Added notification to history: $title');
      } else {
        print('⚠️ Could not access NotificationProvider - context not available');
        // Store notification temporarily and add when context is available
        _storePendingNotification(message);
      }
    } catch (e) {
      print('❌ Error adding notification to history: $e');
      _storePendingNotification(message);
    }
  }

// Store pending notifications when context is not available
  static List<RemoteMessage> _pendingNotifications = [];

  static void _storePendingNotification(RemoteMessage message) {
    _pendingNotifications.add(message);
    print('📦 Stored pending notification: ${message.messageId}');
  }

// Process pending notifications when context becomes available
  static void processPendingNotifications() {
    if (_pendingNotifications.isNotEmpty && navigatorKey.currentContext != null) {
      print('🔄 Processing ${_pendingNotifications.length} pending notifications');
      final notificationProvider = Provider.of<NotificationProvider>(
          navigatorKey.currentContext!,
          listen: false
      );

      for (final message in _pendingNotifications) {
        notificationProvider.addNotification(message);
      }
      _pendingNotifications.clear();
      print('✅ Pending notifications processed');
    }
  }

  // Handle background messages too
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('📱 Background message received!');
    _logMessageDetails(message);

    // Add to history even for background messages
    String title = message.notification?.title ?? message.data['title'] ?? 'Notification';
    String body = message.notification?.body ?? message.data['body'] ?? '';
    _addToNotificationHistory(message, title, body);
  }

  static Future<void> registerToken(int userId) async {
    try {
      print('🟡 Registering token for user $userId...');

      if (_currentToken == null) {
        print('⏳ Token not ready, waiting...');
        await Future.delayed(Duration(seconds: 2));
        _currentToken = await _firebaseMessaging.getToken();
      }

      if (_currentToken != null && _currentToken!.isNotEmpty) {
        final response = await http.post(
          Uri.parse('${AppConstants.BASE_URI}/FirebaseToken/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'userID': userId,
            'deviceToken': _currentToken,
            'platform': Platform.isAndroid ? 'Android' : 'iOS',
            'deviceID': _getDeviceId(),
          }),
        );

        if (response.statusCode == 200) {
          _registeredUserId = userId;
          print('✅ Firebase token registered successfully for user $userId');
          print('📝 Token: ${_currentToken!.substring(0, 20)}...');
        } else {
          print('❌ Failed to register token: ${response.statusCode} - ${response.body}');
        }
      } else {
        print('❌ No token available to register');
      }
    } catch (e) {
      print('❌ Error registering Firebase token: $e');
    }
  }

  static Future<void> unregisterToken() async {
    try {
      if (_currentToken != null) {
        final response = await http.post(
          Uri.parse('${AppConstants.BASE_URI}/FirebaseToken/unregister'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'deviceToken': _currentToken,
          }),
        );

        if (response.statusCode == 200) {
          _registeredUserId = null;
          print('✅ Firebase token unregistered successfully');
        }
      }
    } catch (e) {
      print('❌ Error unregistering token: $e');
    }
  }

  static String _getDeviceId() {
    return '${Platform.operatingSystem}_${DateTime.now().millisecondsSinceEpoch}';
  }

  static void _logMessageDetails(RemoteMessage message) {
    print('''
📨 NOTIFICATION DETAILS:
   Title: ${message.notification?.title}
   Body: ${message.notification?.body}
   Data: ${message.data}
   Message ID: ${message.messageId}
''');
  }

  static void printDebugInfo() {
    print('''
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