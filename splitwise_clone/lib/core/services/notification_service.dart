import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'; // Добавляем импорт для debugPrint
import '../../core/utils/currency_utils.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    // Request permissions
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);

    // Handle FCM messages
    FirebaseMessaging.onMessage.listen((message) {
      _showNotification(
        title: message.notification?.title ?? 'Новое уведомление',
        body: message.notification?.body ?? '',
      );
    });

    // Get FCM token
    final token = await _messaging.getToken();
    debugPrint('FCM Token: $token'); // Теперь debugPrint доступен
  }

  static Future<void> _showNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Default',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  static Future<void> showExpenseNotification({
    required String groupName,
    required String userName,
    required double amount,
    required String currency,
  }) async {
    await _showNotification(
      title: 'Новый расход в группе "$groupName"',
      body: '$userName добавил расход на сумму ${CurrencyUtils.formatAmount(amount, currency)}',
    );
  }

  static Future<void> showDebtNotification({
    required String userName,
    required double amount,
    required String currency,
    required bool isOwed,
  }) async {
    await _showNotification(
      title: 'Обновление долга',
      body: isOwed
          ? '$userName должен вам ${CurrencyUtils.formatAmount(amount, currency)}'
          : 'Вы должны $userName ${CurrencyUtils.formatAmount(amount, currency)}',
    );
  }

  static Future<void> showSettlementNotification({
    required String userName,
    required double amount,
    required String currency,
  }) async {
    await _showNotification(
      title: 'Долг погашен',
      body: '$userName погасил долг на сумму ${CurrencyUtils.formatAmount(amount, currency)}',
    );
  }
}