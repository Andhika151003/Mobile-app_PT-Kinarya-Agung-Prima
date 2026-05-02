import 'dart:ui';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  Future<void> initialize() async {
    // 1. Request Permissions
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

    // 4. Get FCM Token and save to Firestore
    await saveTokenToFirestore();

    // 4. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Received foreground message: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // 5. Handle Background/Terminated Messages (Interaction)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('App opened from notification: ${message.data}');
    });

    // 6. Listen to Firestore User Notifications (Simulation for status changes)
    listenToUserNotifications();

    // 7. Watch for Auth changes to re-initialize listener if user logs in later
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        listenToUserNotifications();
        saveTokenToFirestore(); // Also refresh token on login
      }
    });
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
      // JANGAN di-await agar tidak menghambat proses navigasi UI
      // Biarkan berjalan di background (fire and forget)
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
      // In a real production app, you would use FCM Topics (/topics/all)
      // For this simulation, we send to all users in the 'users' collection
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

    // Kirim setelah 5 detik untuk memberi waktu pengguna menutup aplikasi (simulasi push)
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

    // Get user role first to decide which collections to listen to
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final role = (userDoc.data()?['role'] ?? 'retailer').toString().toLowerCase();

    // 1. Listen for personal notifications (For everyone)
    _firestore
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
    });

    // 2. Listen for Admin notifications (ONLY for Admins and CS)
    if (role == 'admin' || role == 'cs' || role == 'customer_support') {
      _firestore
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

// Global background message handler
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
}
