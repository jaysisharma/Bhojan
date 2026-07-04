import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';

// Top-level background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // ignore: avoid_print
  print("Handling a background message: ${message.messageId}");
}

class NotificationService {
  final Ref _ref;

  NotificationService(this._ref);

  Future<void> initialize() async {
    try {
      final messaging = FirebaseMessaging.instance;

      // 1. Request notification permissions
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      // ignore: avoid_print
      print('User granted notification authorization permission status: ${settings.authorizationStatus}');

      // 2. Setup background messaging handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 3. Setup foreground messaging stream listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        // ignore: avoid_print
        print('Received a foreground notification message: ${message.notification?.title} - ${message.notification?.body}');
        
        // Under production, triggers order/table notification sync broadcasts
      });
    } catch (e) {
      // ignore: avoid_print
      print('Error initializing Firebase Cloud Messaging: $e');
    }
  }

  Future<void> registerDeviceToken() async {
    try {
      final messaging = FirebaseMessaging.instance;
      
      // Fetch the actual FCM device token
      final token = await messaging.getToken();
      
      if (token != null) {
        // ignore: avoid_print
        print('Retrieved Firebase FCM token: $token');

        final response = await _ref.read(dioProvider).post(
          '/auth/device-token',
          data: {'token': token},
        );

        if (response.statusCode == 200) {
          // ignore: avoid_print
          print('FCM registration successfully updated on Express server.');
        }
      } else {
        // ignore: avoid_print
        print('FCM token is null.');
      }
    } catch (e) {
      // ignore: avoid_print
      print('Failed to register device notification token: $e');
    }
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref);
});
