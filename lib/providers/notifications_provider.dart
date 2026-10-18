import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../models/notification_model.dart';
import '../models/user_model.dart';
import '../models/meal_models.dart';
import '../models/inventory_item.dart';

export '../models/notification_model.dart';

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  final service = PushNotificationService();
  ref.onDispose(() => service.dispose());
  return service;
});

class PushNotificationService {
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isLocalNotificationsInitialized = false;
  bool _isTimezonesInitialized = false;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _firestoreRelaySubscription;
  DateTime _sessionStartTime = DateTime.now();
  AppUser? _currentUser;

  void dispose() {
    _firestoreRelaySubscription?.cancel();
    _firestoreRelaySubscription = null;
    _currentUser = null;
  }

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'hearth_high_importance_channel',
    'Hearth Notifications',
    description: 'Important updates for Hearth flatmates',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'hearth_high_importance_channel',
        'Hearth Notifications',
        channelDescription: 'Important updates for Hearth flatmates',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  Future<void> initializeLocalNotifications() async {
    if (_isLocalNotificationsInitialized) {
      return;
    }

    if (!_isTimezonesInitialized) {
      tz_data.initializeTimeZones();
      try {
        tz.setLocalLocation(tz.getLocation('Europe/Warsaw'));
      } catch (_) {
        tz.setLocalLocation(tz.UTC);
      }
      _isTimezonesInitialized = true;
    }

    if (kIsWeb) {
      _isLocalNotificationsInitialized = true;
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
        await androidPlugin.requestNotificationsPermission();
        await androidPlugin.createNotificationChannel(_channel);
      }
      _isLocalNotificationsInitialized = true;
    } catch (e) {
      debugPrint('Local notifications init exception: $e');
    }
  }

  Future<void> showNativeNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (kIsWeb) {
      return;
    }

    try {
      await initializeLocalNotifications();
      await _localNotifications.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: _notificationDetails(),
      );
    } catch (e) {
      debugPrint('Error showing native notification: $e');
    }
  }

  Future<void> initAndRegisterUser(AppUser user) async {
    _currentUser = user;
    _sessionStartTime = DateTime.now();
    await initializeLocalNotifications();

    // Real-time OS Push Listener from Firestore (Client-Driven Relay)
    await _firestoreRelaySubscription?.cancel();
    _firestoreRelaySubscription = FirebaseFirestore.instance
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data == null) {
            continue;
          }
          final notification = AppNotification.fromFirestore(data, change.doc.id);
          if (notification.createdAt.isAfter(_sessionStartTime)) {
            final current = _currentUser;
            if (current != null &&
                current.notificationsEnabled &&
                notification.actorName != current.name &&
                !notification.readBy.contains(current.name)) {
              showNativeNotification(
                id: notification.id.hashCode,
                title: notification.title,
                body: notification.body,
              );
            }
          }
        }
      }
    });
  }

  Future<void> unregisterUser(AppUser user) async {
    await _firestoreRelaySubscription?.cancel();
    _firestoreRelaySubscription = null;
    _currentUser = null;

    if (!kIsWeb) {
      try {
        await _localNotifications.cancelAll();
      } catch (e) {
        debugPrint('Error canceling notifications on logout: $e');
      }
    }
  }

  Future<void> toggleNotificationsEnabled(String userId, bool enabled) async {
    if (_currentUser?.id == userId) {
      _currentUser = _currentUser?.copyWith(notificationsEnabled: enabled);
    }
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'notificationsEnabled': enabled,
    });

    if (!enabled && !kIsWeb) {
      try {
        await _localNotifications.cancelAll();
      } catch (e) {
        debugPrint('Error canceling notifications on toggle off: $e');
      }
    }
  }

  Future<void> syncScheduledDeviceNotifications({
    Recipe? todaysRecipe,
    int choresCount = 0,
    List<InventoryItem> lowStockItems = const [],
  }) async {
    if (kIsWeb || _currentUser == null || !(_currentUser!.notificationsEnabled)) {
      return;
    }

    await initializeLocalNotifications();

    try {
      final now = tz.TZDateTime.now(tz.local);

      // 1. Morning push at 09:00 (id: 1001)
      var scheduledMorning = tz.TZDateTime(tz.local, now.year, now.month, now.day, 9);
      if (scheduledMorning.isBefore(now)) {
        scheduledMorning = scheduledMorning.add(const Duration(days: 1));
      }

      final mealText = todaysRecipe != null ? todaysRecipe.name : 'Check recipes & plan dinner';
      final choresText = choresCount > 0 ? '$choresCount chores assigned' : 'no pending chores';

      await _localNotifications.zonedSchedule(
        id: 1001,
        title: 'Good morning from Hearth.',
        body: "Tonight's dinner: $mealText. You have $choresText.",
        scheduledDate: scheduledMorning,
        notificationDetails: _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      // 2. Evening shopping push at 18:00 (id: 1002)
      if (lowStockItems.isNotEmpty) {
        var scheduledEvening = tz.TZDateTime(tz.local, now.year, now.month, now.day, 18);
        if (scheduledEvening.isBefore(now)) {
          scheduledEvening = scheduledEvening.add(const Duration(days: 1));
        }

        final itemsSummary = lowStockItems.take(3).map((e) => e.name).join(', ');
        await _localNotifications.zonedSchedule(
          id: 1002,
          title: 'Shopping Reminder',
          body: 'Running low on ${lowStockItems.length} items: $itemsSummary.',
          scheduledDate: scheduledEvening,
          notificationDetails: _notificationDetails(),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } else {
        await _localNotifications.cancel(id: 1002);
      }
    } catch (e) {
      debugPrint('Error syncing scheduled device notifications: $e');
    }
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

final notificationControllerProvider = Provider((ref) {
  return NotificationController(ref.read(pushNotificationServiceProvider));
});

class NotificationController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final PushNotificationService _pushService;

  NotificationController(this._pushService);

  Future<void> dispatchNotification({
    required String title,
    required String body,
    required String category,
    required String actorName,
    bool showLocalDirectly = false,
  }) async {
    await _db.collection('notifications').add({
      'title': title,
      'body': body,
      'category': category,
      'actorName': actorName,
      'targetUser': null,
      'createdAt': Timestamp.now(),
      'readBy': [],
    });

    if (showLocalDirectly) {
      await _pushService.showNativeNotification(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: title,
        body: body,
      );
    }
  }

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
    await dispatchNotification(
      title: 'Test from Hearth Pulse',
      body: 'Push & in-app notifications are properly configured for $userName.',
      category: 'cleaning',
      actorName: userName,
      showLocalDirectly: true,
    );
  }
}
