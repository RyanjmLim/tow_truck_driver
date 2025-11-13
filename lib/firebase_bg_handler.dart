// lib/firebase_bg_handler.dart
import 'dart:developer';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '/services/FirebaseNotificationService.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase in BG isolate
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // ignore: Firebase may already be initialized in some contexts
    log('BG Firebase init: $e');
  }

  // Delegate to your service bridge
  FirebaseNotificationService.handleBackground(message);
}
