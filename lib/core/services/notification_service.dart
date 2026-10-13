import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../constants/app_theme.dart';
import '../../domain/entities/goal.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    try {
      await _initLocalNotifications();
    } catch (_) {}

    try {
      await _requestPermission().timeout(const Duration(seconds: 2));
    } catch (_) {}

    try {
      await _initFCM().timeout(const Duration(seconds: 3));
    } catch (_) {}
  }

  Future<void> _requestPermission() async {
    try {
      await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        sound: true,
      );
    } catch (_) {}
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(initSettings);
  }

  Future<void> _initFCM() async {
    try {
      final token = await _firebaseMessaging.getToken().timeout(
        const Duration(seconds: 3),
      );
      await _saveTokenToFirestore(token);
    } catch (_) {}

    try {
      _firebaseMessaging.onTokenRefresh.listen((token) {
        _saveTokenToFirestore(token);
      });
      FirebaseMessaging.onMessage.listen(_showLocalNotification);
    } catch (_) {}
  }

  Future<void> _saveTokenToFirestore(String? token) async {
    if (token == null) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'fcmToken': token}, SetOptions(merge: true))
          .timeout(const Duration(seconds: 2));
    } catch (_) {}
  }

  void _showLocalNotification(RemoteMessage message) {
    const androidDetails = AndroidNotificationDetails(
      'sajilo_khata_channel',
      'Sajilo Khata',
      channelDescription: 'Transaction and goal notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      details,
    );
  }

  Future<void> showTransactionLoggedNotification({
    required double amount,
    required bool isDebit,
  }) async {
    final type = isDebit ? 'Expense' : 'Income';
    const androidDetails = AndroidNotificationDetails(
      'transaction_channel',
      'Transactions',
      channelDescription: 'Transaction notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const details = NotificationDetails(android: androidDetails);

    _localNotifications.show(
      0,
      'Transaction Recorded',
      '${CurrencyHelper.symbol}${amount.toStringAsFixed(0)} $type logged',
      details,
    );
  }

  Future<void> showGoalCreatedNotification(Goal goal) async {
    const androidDetails = AndroidNotificationDetails(
      'goal_channel',
      'Savings Goals',
      channelDescription: 'Goal notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const details = NotificationDetails(android: androidDetails);

    _localNotifications.show(
      goal.id.hashCode,
      'New Goal Created',
      'You created "${goal.name}" savings goal of ${CurrencyHelper.symbol}${goal.targetAmount.toStringAsFixed(0)}',
      details,
    );
  }

  Future<void> showGoalCompletedNotification(Goal goal) async {
    const androidDetails = AndroidNotificationDetails(
      'goal_channel',
      'Savings Goals',
      channelDescription: 'Goal achievement notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    _localNotifications.show(
      goal.id.hashCode,
      'Goal Achieved!',
      'Congratulations! You reached your "${goal.name}" goal!',
      details,
    );
  }

  Future<void> showSyncCompleteNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'sync_channel',
      'Sync Status',
      channelDescription: 'Data sync notifications',
      importance: Importance.low,
      priority: Priority.low,
    );
    const details = NotificationDetails(android: androidDetails);

    _localNotifications.show(
      999,
      'Data Synced',
      'Your data has been synced with the cloud',
      details,
    );
  }
}
