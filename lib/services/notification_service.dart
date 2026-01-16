// lib/services/notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  // Initialize FCM and local notifications
  static Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Notification permission granted');
    }

    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initSettings);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Get FCM token and save to user document
    await _saveTokenToUser();
  }

  // Save FCM token to user's Firestore document
  static Future<void> _saveTokenToUser() async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        final userId = await _getCurrentUserId();
        if (userId != null) {
          await _firestore.collection('users').doc(userId).update({
            'fcmToken': token,
            'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          });
          print('✅ FCM token saved: ${token.substring(0, 20)}...');
        }
      }
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  // Get current user ID (helper)
  static Future<String?> _getCurrentUserId() async {
    // This will be replaced with actual auth check
    // For now, return null if no auth
    return null;
  }

  // Handle foreground messages (show local notification)
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('📩 Foreground message: ${message.notification?.title}');

    if (message.notification != null) {
      await _showLocalNotification(
        title: message.notification!.title ?? 'Notification',
        body: message.notification!.body ?? '',
      );
    }
  }

  // Show local notification
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'panchakarma_channel',
      'Panchakarma Notifications',
      channelDescription: 'Notifications for therapy sessions and feedback',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  // ========== NOTIFICATION TRIGGERS (Called from UI/Services) ==========

  // Notify patient: Session scheduled
  static Future<void> notifySessionScheduled({
    required String patientId,
    required String therapyName,
    required DateTime scheduledDate,
  }) async {
    await _sendNotificationToUser(
      userId: patientId,
      title: 'Session Scheduled',
      body: '$therapyName scheduled for ${_formatDate(scheduledDate)}',
      data: {'type': 'session_scheduled'},
    );
  }

  // Notify patient: Session completed (feedback available)
  static Future<void> notifySessionCompleted({
    required String patientId,
    required String therapyName,
  }) async {
    await _sendNotificationToUser(
      userId: patientId,
      title: 'Session Completed',
      body: 'Your $therapyName session is complete. Please provide feedback.',
      data: {'type': 'feedback_available'},
    );
  }

  // Notify patient: Session rescheduled
  static Future<void> notifySessionRescheduled({
    required String patientId,
    required String therapyName,
    required DateTime newDate,
  }) async {
    await _sendNotificationToUser(
      userId: patientId,
      title: 'Session Rescheduled',
      body: '$therapyName has been rescheduled to ${_formatDate(newDate)}',
      data: {'type': 'session_rescheduled'},
    );
  }

  // Notify doctor: Session missed
  static Future<void> notifySessionMissed({
    required String doctorId,
    required String patientName,
    required String therapyName,
  }) async {
    await _sendNotificationToUser(
      userId: doctorId,
      title: 'Missed Session Alert',
      body: '$patientName missed $therapyName session',
      data: {'type': 'session_missed'},
    );
  }

  // Notify patient: Session reminder (24h before)
  static Future<void> notifySessionReminder({
    required String patientId,
    required String therapyName,
    required DateTime scheduledDate,
  }) async {
    await _sendNotificationToUser(
      userId: patientId,
      title: 'Session Reminder',
      body: 'Your $therapyName session is tomorrow at ${_formatTime(scheduledDate)}',
      data: {'type': 'session_reminder'},
    );
  }

  // ========== CORE SEND LOGIC ==========

  // Send notification to specific user via their FCM token
  static Future<void> _sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get user's FCM token from Firestore
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final fcmToken = userDoc.data()?['fcmToken'] as String?;

      if (fcmToken == null) {
        print('⚠️ No FCM token for user $userId');
        return;
      }

      // Create notification document in Firestore
      // (Cloud Functions will handle sending via FCM)
      await _firestore.collection('notifications').add({
        'userId': userId,
        'fcmToken': fcmToken,
        'title': title,
        'body': body,
        'data': data ?? {},
        'sentAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      print('✅ Notification queued for $userId: $title');
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  // ========== HELPERS ==========

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  static String _formatTime(DateTime date) {
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📩 Background message: ${message.notification?.title}');
}