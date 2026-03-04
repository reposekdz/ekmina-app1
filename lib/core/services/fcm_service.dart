import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await FCMService.handleBackgroundMessage(message);
}

class FCMService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static final Dio _dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000/api'));
  static bool _initialized = false;
  static String? _fcmToken;
  static Function(Map<String, dynamic>)? _onMessageTap;

  // Initialize FCM with all features
  static Future<void> initialize({Function(Map<String, dynamic>)? onMessageTap}) async {
    if (_initialized) return;
    
    _onMessageTap = onMessageTap;

    // Request permissions (iOS)
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      criticalAlert: true,
      announcement: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get FCM token
      _fcmToken = await _fcm.getToken();
      if (_fcmToken != null) {
        await _saveFCMToken(_fcmToken!);
      }

      // Token refresh listener
      _fcm.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        _saveFCMToken(newToken);
      });

      // Background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Message opened from terminated state
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

      // Check for initial message (app opened from notification)
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageTap(initialMessage);
      }

      _initialized = true;
    }
  }

  // Initialize local notifications with channels
  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null && _onMessageTap != null) {
          _onMessageTap!(jsonDecode(details.payload!));
        }
      },
    );

    // Create notification channels (Android)
    await _createNotificationChannels();
  }

  // Create Android notification channels
  static Future<void> _createNotificationChannels() async {
    final channels = [
      const AndroidNotificationChannel(
        'contributions',
        'Kwishyura',
        description: 'Amakuru yo kwishyura',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
        showBadge: true,
      ),
      const AndroidNotificationChannel(
        'loans',
        'Inguzanyo',
        description: 'Amakuru y\'inguzanyo',
        importance: Importance.max,
        enableVibration: true,
        playSound: true,
        showBadge: true,
      ),
      const AndroidNotificationChannel(
        'meetings',
        'Inama',
        description: 'Amakuru y\'inama',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
        showBadge: true,
      ),
      const AndroidNotificationChannel(
        'transactions',
        'Amafaranga',
        description: 'Amakuru y\'amafaranga',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
        showBadge: true,
      ),
      const AndroidNotificationChannel(
        'announcements',
        'Itangazo',
        description: 'Amatangazo',
        importance: Importance.defaultImportance,
        enableVibration: true,
        playSound: true,
        showBadge: true,
      ),
      const AndroidNotificationChannel(
        'penalties',
        'Ibihano',
        description: 'Amakuru y\'ibihano',
        importance: Importance.max,
        enableVibration: true,
        playSound: true,
        showBadge: true,
      ),
      const AndroidNotificationChannel(
        'dividends',
        'Inyungu',
        description: 'Amakuru y\'inyungu',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
        showBadge: true,
      ),
    ];

    for (var channel in channels) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  // Handle foreground messages
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      await _showLocalNotification(
        title: notification.title ?? 'E-Kimina',
        body: notification.body ?? '',
        channelId: data['type'] ?? 'announcements',
        payload: jsonEncode(data),
        imageUrl: notification.android?.imageUrl ?? notification.apple?.imageUrl,
      );
    }

    // Update badge count
    await _updateBadgeCount();
  }

  // Handle message tap (navigation)
  static void _handleMessageTap(RemoteMessage message) {
    final data = message.data;
    if (_onMessageTap != null) {
      _onMessageTap!(data);
    }
  }

  // Handle background messages
  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    // Process background message (e.g., update local database)
  }

  // Show local notification with rich features
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    required String channelId,
    String? payload,
    String? imageUrl,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      _getChannelName(channelId),
      channelDescription: _getChannelDescription(channelId),
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      styleInformation: imageUrl != null
          ? BigPictureStyleInformation(
              FilePathAndroidBitmap(imageUrl),
              contentTitle: title,
              summaryText: body,
            )
          : BigTextStyleInformation(body),
      actions: _getNotificationActions(channelId),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.active,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload,
    );
  }

  // Get notification actions based on type
  static List<AndroidNotificationAction> _getNotificationActions(String type) {
    switch (type) {
      case 'contributions':
        return [
          const AndroidNotificationAction('pay', 'Ishyura', showsUserInterface: true),
          const AndroidNotificationAction('view', 'Reba', showsUserInterface: true),
        ];
      case 'loans':
        return [
          const AndroidNotificationAction('pay', 'Ishyura', showsUserInterface: true),
          const AndroidNotificationAction('details', 'Ibisobanuro', showsUserInterface: true),
        ];
      case 'meetings':
        return [
          const AndroidNotificationAction('confirm', 'Emeza', showsUserInterface: true),
          const AndroidNotificationAction('view', 'Reba', showsUserInterface: true),
        ];
      default:
        return [
          const AndroidNotificationAction('view', 'Reba', showsUserInterface: true),
        ];
    }
  }

  // Helper methods for channel names
  static String _getChannelName(String channelId) {
    final names = {
      'contributions': 'Kwishyura',
      'loans': 'Inguzanyo',
      'meetings': 'Inama',
      'transactions': 'Amafaranga',
      'announcements': 'Itangazo',
      'penalties': 'Ibihano',
      'dividends': 'Inyungu',
    };
    return names[channelId] ?? 'Amakuru';
  }

  static String _getChannelDescription(String channelId) {
    final descriptions = {
      'contributions': 'Amakuru yo kwishyura',
      'loans': 'Amakuru y\'inguzanyo',
      'meetings': 'Amakuru y\'inama',
      'transactions': 'Amakuru y\'amafaranga',
      'announcements': 'Amatangazo',
      'penalties': 'Amakuru y\'ibihano',
      'dividends': 'Amakuru y\'inyungu',
    };
    return descriptions[channelId] ?? 'Amakuru';
  }

  // Save FCM token to server
  static Future<void> _saveFCMToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      
      if (userId != null) {
        await _dio.post('/users/fcm-token', data: {
          'userId': userId,
          'fcmToken': token,
          'platform': 'mobile',
        });
      }
      
      await prefs.setString('fcm_token', token);
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  // Subscribe to topic
  static Future<void> subscribeToTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
  }

  // Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    await _fcm.unsubscribeFromTopic(topic);
  }

  // Subscribe to group notifications
  static Future<void> subscribeToGroup(String groupId) async {
    await subscribeToTopic('group_$groupId');
  }

  // Unsubscribe from group notifications
  static Future<void> unsubscribeFromGroup(String groupId) async {
    await unsubscribeFromTopic('group_$groupId');
  }

  // Update badge count
  static Future<void> _updateBadgeCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      
      if (userId != null) {
        final response = await _dio.get('/notifications/unread-count', 
          queryParameters: {'userId': userId});
        
        if (response.statusCode == 200) {
          final count = response.data['count'] as int;
          await _localNotifications
              .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
              ?.getActiveNotifications();
        }
      }
    } catch (e) {
      print('Error updating badge count: $e');
    }
  }

  // Get FCM token
  static String? get fcmToken => _fcmToken;

  // Clear all notifications
  static Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  // Send notification to specific user (server-side)
  static Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _dio.post('/notifications/send', data: {
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'data': data,
      });
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  // Send notification to group (server-side)
  static Future<void> sendNotificationToGroup({
    required String groupId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _dio.post('/notifications/send-group', data: {
        'groupId': groupId,
        'title': title,
        'body': body,
        'type': type,
        'data': data,
      });
    } catch (e) {
      print('Error sending group notification: $e');
    }
  }
}
