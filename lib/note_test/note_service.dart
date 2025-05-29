import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NoteService {
  NoteService._internal();
  static final NoteService instance = NoteService._internal();

  final notificationPlugin = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  bool get isInitalized => _isInitialized;

  Future<void> initNotification() async {
    try {
      if (_isInitialized) return;

      print('Initializing notification settings...');
      const initSettingsAndroid = AndroidInitializationSettings(
        'mipmap/ic_launcher',
      );

      const initSettingsIOS = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: initSettingsAndroid,
        iOS: initSettingsIOS,
      );

      print('Calling notificationPlugin.initialize...');
      await notificationPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          print('Received notification response: ${details.payload}');
        },
      );
      _isInitialized = true;
      print('Notification initialized successfully');
    } catch (e, stackTrace) {
      print('Error initializing notification: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  NotificationDetails notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'com.example.akdsd.notifications',
        'App Notifications',
        channelDescription: 'Important app notifications',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        enableLights: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  Future<void> showNotification({
    int id = 0,
    String? title,
    String? body,
  }) async {
    try {
      print(
        'showNotification called: id=$id, title=$title, body=$body, isInitialized=$_isInitialized',
      );
      if (!_isInitialized) {
        print('Notification not initialized, calling initNotification...');
        await initNotification();
      }

      print('Creating notification details...');
      final details = notificationDetails();

      print('Showing notification...');
      await notificationPlugin.show(id, title, body, details);
      print('Notification shown successfully');
    } catch (e, stackTrace) {
      print('Error showing notification: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
}
