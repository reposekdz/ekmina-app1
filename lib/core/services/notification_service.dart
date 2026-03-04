import 'package:dio/dio.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../config/app_config.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final Dio _dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _notifications.initialize(initSettings);
  }

  Future<void> showNotification({required String title, required String body, String? payload}) async {
    const androidDetails = AndroidNotificationDetails('channel_id', 'channel_name', importance: Importance.max, priority: Priority.high);
    const iosDetails = DarwinNotificationDetails();
    const platformDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _notifications.show(0, title, body, platformDetails, payload: payload);
  }
}
