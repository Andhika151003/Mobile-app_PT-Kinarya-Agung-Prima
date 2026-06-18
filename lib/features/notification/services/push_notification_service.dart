import 'dart:ui';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class PushNotificationService {
  FirebaseMessaging? _fcmOverride;
  FlutterLocalNotificationsPlugin? _localNotificationsOverride;
  FirebaseFirestore? _firestoreOverride;
  FirebaseAuth? _authOverride;

  FirebaseMessaging get _fcm => _fcmOverride ?? FirebaseMessaging.instance;
  FlutterLocalNotificationsPlugin get _localNotifications =>
      _localNotificationsOverride ?? FlutterLocalNotificationsPlugin();
  FirebaseFirestore get _firestore => _firestoreOverride ?? FirebaseFirestore.instance;
  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;

  StreamSubscription<QuerySnapshot>? _userNotifSubscription;
  StreamSubscription<QuerySnapshot>? _adminNotifSubscription;

  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  @visibleForTesting
  void setupMocks({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseMessaging? fcm,
    FlutterLocalNotificationsPlugin? localNotifications,
  }) {
    _firestoreOverride = firestore;
    _authOverride = auth;
    _fcmOverride = fcm;
    _localNotificationsOverride = localNotifications;
  }

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

    _auth.authStateChanges().listen((user) {
      if (user != null) {
        listenToUserNotifications();
        saveTokenToFirestore();
      } else {
        _cancelSubscriptions();
      }
    });
  }

  void _cancelSubscriptions() {
    _userNotifSubscription?.cancel();
    _adminNotifSubscription?.cancel();
    _userNotifSubscription = null;
    _adminNotifSubscription = null;
  }

  Future<void> saveTokenToFirestore() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('FCM Token saved to Firestore');
      }
    } catch (e) {
      debugPrint('Error saving FCM Token: $e');
    }
  }

  Future<void> clearToken() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      _firestore.collection('users').doc(user.uid).update({
        'fcmToken': FieldValue.delete(),
      }).catchError((e) => debugPrint('Background clear token failed: $e'));
      
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
      await _firestore.collection('admin_notifications').add({
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
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
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
      final usersSnapshot = await _firestore.collection('users').get();
      
      final batch = _firestore.batch();
      for (var userDoc in usersSnapshot.docs) {
        final notifRef = userDoc.reference.collection('notifications').doc();
        batch.set(notifRef, {
          'title': title,
          'message': message,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'type': type,
          'relatedId': relatedId,
        });
      }
      await batch.commit();
      debugPrint('Broadcast notification sent to ${usersSnapshot.docs.length} users');
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
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final role = (userDoc.data()?['role'] ?? 'retailer').toString().toLowerCase();

      _cancelSubscriptions(); // Batalkan yang lama sebelum membuat baru
      
      _userNotifSubscription = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .where('timestamp', isGreaterThan: Timestamp.now())
          .snapshots()
          .listen((snapshot) {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final data = change.doc.data() as Map<String, dynamic>;
            debugPrint('NEW User Notification detected: ${data['title']}');
            _showLocalNotificationFromData(data);
          }
        }
      }, onError: (e) {
        debugPrint('Error listening to user notifications (handled): $e');
      });

      if (role == 'admin' || role == 'cs' || role == 'customer_support') {
        _adminNotifSubscription = _firestore
            .collection('admin_notifications')
            .where('timestamp', isGreaterThan: Timestamp.now())
            .snapshots()
            .listen((snapshot) {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final data = change.doc.data() as Map<String, dynamic>;
              debugPrint('NEW Admin Notification detected: ${data['title']}');
              _showLocalNotificationFromData(data);
            }
          }
        }, onError: (e) {
          debugPrint('Error listening to admin notifications (handled): $e');
        });
      }
    } catch (e) {
      debugPrint('Error in listenToUserNotifications: $e');
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
