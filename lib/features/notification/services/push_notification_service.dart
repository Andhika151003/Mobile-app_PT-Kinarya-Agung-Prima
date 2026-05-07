import 'dart:ui';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/repositories/notification_repository.dart';

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  
  final AuthRepository _authRepository = AuthRepository();
  final NotificationRepository _notificationRepository = NotificationRepository();

  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  Future<void> initialize() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permission');
    } else {
      debugPrint('User declined notification permission');
      return;
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );
    
    await _localNotifications.initialize(settings: initSettings);

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.createNotificationChannel(
      const AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.max,
      ),
    );

    await saveTokenToFirestore();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Received foreground message: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('App opened from notification: ${message.data}');
    });

    listenToUserNotifications();

    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        listenToUserNotifications();
        saveTokenToFirestore();
      }
    });
  }

  Future<void> saveTokenToFirestore() async {
    final user = _authRepository.currentUser;
    if (user == null) return;

    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        await _authRepository.saveFCMToken(user.uid, token);
        debugPrint('FCM Token saved to Firestore');
      }
    } catch (e) {
      debugPrint('Error saving FCM Token: $e');
    }
  }

  Future<void> clearToken() async {
    final user = _authRepository.currentUser;
    if (user == null) return;

    try {
      _authRepository.clearFCMToken(user.uid).catchError((e) => debugPrint('Background clear token failed: $e'));
      debugPrint('FCM Token clearing initiated in background');
    } catch (e) {
      debugPrint('Error starting background clear token: $e');
    }
  }

  Future<void> sendNotificationToAdmin({
    required String title,
    required String message,
    String type = 'order',
    String? relatedId,
  }) async {
    try {
      await _notificationRepository.addAdminNotification({
        'title': title,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': type,
        'relatedId': relatedId,
      });
      debugPrint('Notification sent to Admin collection');
    } catch (e) {
      debugPrint('Error sending notification to admin: $e');
    }
  }

  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String message,
    String type = 'order',
    String? relatedId,
  }) async {
    try {
      await _notificationRepository.addUserNotification(userId, {
        'title': title,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': type,
        'relatedId': relatedId,
      });
      debugPrint('Notification sent to user $userId');
    } catch (e) {
      debugPrint('Error sending notification to user: $e');
    }
  }

  Future<void> broadcastNotification({
    required String title,
    required String message,
    String type = 'promo',
    String? relatedId,
  }) async {
    try {
      await _notificationRepository.broadcastNotificationToAllUsers({
        'title': title,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': type,
        'relatedId': relatedId,
      });
      debugPrint('Broadcast notification sent to users');
    } catch (e) {
      debugPrint('Error broadcasting notification: $e');
    }
  }

  Future<void> showDelayedNotification() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    Future.delayed(const Duration(seconds: 5), () async {
      await _localNotifications.show(
        id: 999,
        title: 'Test Push Notifikasi',
        body: 'Ini adalah simulasi push notifikasi (muncul setelah 5 detik).',
        notificationDetails: details,
      );
    });
  }

  void listenToUserNotifications() async {
    final user = _authRepository.currentUser;
    if (user == null) return;

    final userDoc = await _authRepository.getUserDoc(user.uid);
    final role = (userDoc.data()?['role'] ?? 'retailer').toString().toLowerCase();

    _notificationRepository.getUserNotificationsSnapshotStream(user.uid).listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          debugPrint('NEW User Notification detected: ${data['title']}');
          _showLocalNotificationFromData(data);
        }
      }
    });

    if (role == 'admin' || role == 'cs' || role == 'customer_support') {
      _notificationRepository.getAdminNotificationsSnapshotStream().listen((snapshot) {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final data = change.doc.data() as Map<String, dynamic>;
            debugPrint('NEW Admin Notification detected: ${data['title']}');
            _showLocalNotificationFromData(data);
          }
        }
      });
    }
  }

  Future<void> _showLocalNotificationFromData(Map<String, dynamic> data) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      showWhen: true,
      enableLights: true,
      color: const Color(0xFF458833),
    );
    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      id: DateTime.now().millisecond,
      title: data['title'] ?? 'Notifikasi Baru',
      body: data['message'] ?? '',
      notificationDetails: details,
    );
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          importance: Importance.max,
          priority: Priority.high,
        );
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      id: message.hashCode,
      title: message.notification?.title,
      body: message.notification?.body,
      notificationDetails: details,
    );
  }
}

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
}
