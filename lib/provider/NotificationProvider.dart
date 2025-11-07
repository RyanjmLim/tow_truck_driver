import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/NotificationModel.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationProvider with ChangeNotifier {
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  static const String _storageKey = 'notifications';

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  int get totalCount => _notifications.length;

  NotificationProvider() {
    _loadFromStorage();
  }

  // Add new notification
  void addNotification(RemoteMessage message) {
    final notification = AppNotification.fromRemoteMessage(message);
    _notifications.insert(0, notification); // Add to beginning
    _unreadCount++;
    _saveToStorage();
    notifyListeners();
  }

  // Mark as read
  void markAsRead(int id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _unreadCount--;
      _saveToStorage();
      notifyListeners();
    }
  }

  // Mark all as read
  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
    _unreadCount = 0;
    _saveToStorage();
    notifyListeners();
  }

  // Delete notification
  void deleteNotification(int id) {
    try {
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        final notification = _notifications[index];
        if (!notification.isRead) {
          _unreadCount--;
        }
        _notifications.removeAt(index);
        _saveToStorage(); // Save immediately after deletion
        notifyListeners();
      }
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  // Clear all notifications
  void clearAll() {
    _notifications.clear();
    _unreadCount = 0;
    _saveToStorage();
    notifyListeners();
  }

  // Load from storage
  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedData = prefs.getString(_storageKey);

      if (storedData != null) {
        final List<dynamic> jsonList = json.decode(storedData);
        _notifications = jsonList.map((json) => AppNotification.fromJson(json)).toList();

        // Calculate unread count
        _unreadCount = _notifications.where((n) => !n.isRead).length;

        notifyListeners();
      }
    } catch (e) {
      print('Error loading notifications from storage: $e');
      _notifications = [];
      _unreadCount = 0;
    }
  }

  // Save to storage
  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _notifications.map((notification) => notification.toJson()).toList();
      await prefs.setString(_storageKey, json.encode(jsonList));
    } catch (e) {
      print('Error saving notifications to storage: $e');
    }
  }

  // Load from storage (public method for manual refresh)
  Future<void> loadFromStorage() async {
    await _loadFromStorage();
  }

  // Get notifications by type
  List<AppNotification> getNotificationsByType(String type) {
    return _notifications.where((n) => n.data['type'] == type).toList();
  }

  // Get case notifications
  List<AppNotification> getCaseNotifications() {
    return _notifications.where((n) =>
    n.data['type']?.contains('CASE') == true ||
        n.data['caseId'] != null
    ).toList();
  }
}