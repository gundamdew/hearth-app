import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background message received: ${message.messageId}');
}

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService();
});

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isLocalNotificationsInitialized = false;
  StreamSubscription<String>? _tokenRefreshSubscription;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'hearth_high_importance_channel',
    'Hearth Notifications',
    description: 'Important updates for Hearth flatmates',
    importance: Importance.high,
  );

  Future<void> initializeLocalNotifications() async {
    if (_isLocalNotificationsInitialized) {
      return;
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    try {
      await _localNotifications.initialize(settings: initSettings);

      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(_channel);
      }
      _isLocalNotificationsInitialized = true;
    } catch (e) {
      debugPrint('Local notifications init exception: $e');
    }
  }

  Future<void> initAndRegisterUser(AppUser user) async {
    try {
      await initializeLocalNotifications();

      // Request FCM permissions
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('FCM notification permission denied');
        return;
      }

      // Get device FCM token
      String? token;
      try {
        token = await _fcm.getToken();
      } catch (e) {
        debugPrint('FCM getToken error: $e');
      }

      if (token != null && token.isNotEmpty) {
        await FirebaseFirestore.instance.collection('users').doc(user.id).update({
          'fcmTokens': FieldValue.arrayUnion([token]),
        });
      }

      // Listen for token refresh
      _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = _fcm.onTokenRefresh.listen((newToken) async {
        if (newToken.isNotEmpty) {
          await FirebaseFirestore.instance.collection('users').doc(user.id).update({
            'fcmTokens': FieldValue.arrayUnion([newToken]),
          });
        }
      });

      // Foreground message listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        if (notification != null) {
          _showForegroundNotification(
            id: message.hashCode,
            title: notification.title ?? 'Hearth',
            body: notification.body ?? '',
          );
        }
      });
    } catch (e) {
      debugPrint('Error registering user for push notifications: $e');
    }
  }

  Future<void> _showForegroundNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (kIsWeb) {
      return;
    }

    try {
      await _localNotifications.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            icon: '@mipmap/ic_launcher',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }

  Future<void> unregisterUser(AppUser user) async {
    try {
      _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = null;

      String? token;
      try {
        token = await _fcm.getToken();
      } catch (_) {}

      if (token != null && token.isNotEmpty) {
        await FirebaseFirestore.instance.collection('users').doc(user.id).update({
          'fcmTokens': FieldValue.arrayRemove([token]),
        });
      }
    } catch (e) {
      debugPrint('Error unregistering user from push notifications: $e');
    }
  }

  Future<void> toggleNotificationsEnabled(String userId, bool enabled) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'notificationsEnabled': enabled,
    });
  }
}

final notificationsStreamProvider = StreamProvider<List<AppNotification>>((ref) {
  return FirebaseFirestore.instance
      .collection('notifications')
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => AppNotification.fromFirestore(doc.data(), doc.id))
        .toList();
  });
});

final notificationControllerProvider = Provider((ref) => NotificationController());

class NotificationController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> markAsRead(String notificationId, String userName) async {
    await _db.collection('notifications').doc(notificationId).update({
      'readBy': FieldValue.arrayUnion([userName]),
    });
  }

  Future<void> markAllAsRead(String userName, List<AppNotification> notifications) async {
    final unread = notifications.where((n) => !n.readBy.contains(userName)).toList();
    if (unread.isEmpty) {
      return;
    }

    final batch = _db.batch();
    for (final n in unread) {
      final docRef = _db.collection('notifications').doc(n.id);
      batch.update(docRef, {
        'readBy': FieldValue.arrayUnion([userName]),
      });
    }
    await batch.commit();
  }

  Future<void> sendTestNotification(String userName) async {
    await _db.collection('notifications').add({
      'title': 'Test from Hearth Pulse',
      'body': 'Push & in-app notifications are properly configured for $userName.',
      'category': 'cleaning',
      'actorName': userName,
      'targetUser': null,
      'createdAt': Timestamp.now(),
      'readBy': [],
    });
  }
}
