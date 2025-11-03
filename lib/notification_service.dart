import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:windows_notification/windows_notification.dart';
import 'package:windows_notification/notification_message.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FlutterLocalNotificationsPlugin? _notifications;
  WindowsNotification? _winNotification;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    if (Platform.isWindows) {
      try {
        _winNotification = WindowsNotification(
          applicationId: 'TouchFish.Astra',
        );
        _initialized = true;
      } catch (e) {
        _initialized = false;
      }
      return;
    }
    
    try {
      _notifications = FlutterLocalNotificationsPlugin();
      
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const linuxSettings = LinuxInitializationSettings(
        defaultActionName: 'Open notification',
      );
      const darwinSettings = DarwinInitializationSettings();

      const settings = InitializationSettings(
        android: androidSettings,
        linux: linuxSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );

      _initialized = await _notifications!.initialize(settings) ?? false;
    } catch (e) {
      _initialized = false;
    }
  }

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('enable_notifications') ?? false;
  }

  Future<void> showMessageNotification(String sender, String message) async {
    if (!_initialized) return;
    if (!await isEnabled()) return;

    try {
      if (Platform.isWindows && _winNotification != null) {
        final notificationMessage = NotificationMessage.fromPluginTemplate(
          'TouchFish',  // group
          sender,       // title
          message,      // body
        );
        _winNotification!.showNotificationPluginTemplate(notificationMessage);
        return;
      }
      
      if (_notifications == null) return;

      const androidDetails = AndroidNotificationDetails(
        'touchfish_messages',
        'Messages',
        channelDescription: 'New chat messages',
        importance: Importance.high,
        priority: Priority.high,
      );

      const linuxDetails = LinuxNotificationDetails();

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        linux: linuxDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      await _notifications!.show(
        message.hashCode,
        sender,
        message,
        details,
      );
    } catch (e) {
      return;
    }
  }
}
