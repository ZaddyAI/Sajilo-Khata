import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../constants/app_theme.dart';
import '../models/goal_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    await _requestPermission();
    await _initLocalNotifications();
    await _initFCM();
  }

  Future<void> _requestPermission() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      sound: true,
    );
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
    final token = await _firebaseMessaging.getToken();
    await _saveTokenToFirestore(token);

    _firebaseMessaging.onTokenRefresh.listen((token) {
      _saveTokenToFirestore(token);
    });

    FirebaseMessaging.onMessage.listen(_showLocalNotification);
  }

  Future<void> _saveTokenToFirestore(String? token) async {
    if (token == null) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'fcmToken': token,
    }, SetOptions(merge: true));
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

  Future<void> showGoalAchievedNotification(String goalName) async {
    const androidDetails = AndroidNotificationDetails(
      'goal_channel',
      'Savings Goals',
      channelDescription: 'Goal achievement notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    _localNotifications.show(
      1,
      'Goal Achieved!',
      'Congratulations! You reached your "$goalName" goal!',
      details,
    );
  }

  Future<void> showBudgetAlert({
    required double spent,
    required double limit,
  }) async {
    final percent = ((spent / limit) * 100).toStringAsFixed(0);
    const androidDetails = AndroidNotificationDetails(
      'budget_channel',
      'Budget Alerts',
      channelDescription: 'Monthly budget notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const details = NotificationDetails(android: androidDetails);

    _localNotifications.show(
      2,
      'Budget Alert',
      'You\'ve spent $percent% of your monthly budget',
      details,
    );
  }

  Future<void> showGoalCreatedNotification(GoalModel goal) async {
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

  Future<void> showGoalCompletedNotification(GoalModel goal) async {
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

  Future<void> showSyncPendingNotification(int count) async {
    const androidDetails = AndroidNotificationDetails(
      'sync_channel',
      'Sync Status',
      channelDescription: 'Data sync notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const details = NotificationDetails(android: androidDetails);

    _localNotifications.show(
      998,
      'Sync Pending',
      '$count items waiting to sync when online',
      details,
    );
  }
}
