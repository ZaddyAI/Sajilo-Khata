import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/goal_model.dart';
import 'local_storage_service.dart';
import 'firebase_service.dart';
import 'notification_service.dart';

class SyncService {
  static final SyncService instance = SyncService._();
  SyncService._();

  final _connectivity = Connectivity();
  final _local = LocalStorageService.instance;
  final _firebase = FirebaseService.instance;
  final _notifications = NotificationService.instance;

  StreamSubscription? _connectivitySubscription;
  bool _isSyncing = false;
  ConnectivityResult _lastConnectivityResult = ConnectivityResult.none;
  bool get isOnline => _lastConnectivityResult != ConnectivityResult.none;

  static const _syncDebounce = Duration(seconds: 10);

  Future<void> init() async {
    try {
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _onConnectivityChanged,
      );
      final result = await _connectivity.checkConnectivity();
      _lastConnectivityResult = result.isNotEmpty
          ? result.first
          : ConnectivityResult.none;
    } catch (e) {
      print('[Sync] Connectivity init failed: $e');
      _lastConnectivityResult = ConnectivityResult.none;
    }
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final wasOffline = _lastConnectivityResult == ConnectivityResult.none;
    _lastConnectivityResult = results.isNotEmpty
        ? results.first
        : ConnectivityResult.none;

    if (!wasOffline && isOnline) {
      _triggerSync();
    }
  }

  void _triggerSync() {
    if (_isSyncing || !isOnline) return;
    Future.delayed(_syncDebounce, syncAll);
  }

  Future<void> syncAll() async {
    if (_isSyncing || !isOnline) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _isSyncing = true;
    try {
      await _syncTransactions();
      await _syncGoals();
      _notifications.showSyncCompleteNotification();
    } catch (e) {
      print('[Sync] Error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncTransactions() async {
    final queue = _local
        .getSyncQueue()
        .where((item) => item['type'] == 'transaction')
        .toList();

    for (final item in queue) {
      final id = item['id'] as String;
      final action = item['action'] as String;

      try {
        switch (action) {
          case 'create':
            final tx = _local.getTransactionLocal(id);
            if (tx != null) {
              await _firebase.addTransaction(null, tx);
              await _local.markAsSynced(id, 'transaction');
            }
            break;
          case 'update':
            final tx = _local.getTransactionLocal(id);
            if (tx != null) {
              await _firebase.updateTransaction(tx);
              await _local.markAsSynced(id, 'transaction');
            }
            break;
          case 'delete':
            await _firebase.deleteTransaction(id);
            await _local.markAsSynced(id, 'transaction');
            break;
        }
      } catch (e) {
        print('[Sync] Transaction $id failed: $e');
      }
    }
  }

  Future<void> _syncGoals() async {
    final queue = _local
        .getSyncQueue()
        .where((item) => item['type'] == 'goal')
        .toList();

    for (final item in queue) {
      final id = item['id'] as String;
      final action = item['action'] as String;

      try {
        switch (action) {
          case 'create':
            final goal = _local.getGoalLocal(id);
            if (goal != null) {
              await _firebase.addGoal(goal);
              _notifications.showGoalCreatedNotification(goal);
              await _local.markAsSynced(id, 'goal');
            }
            break;
          case 'update':
            final goal = _local.getGoalLocal(id);
            if (goal != null) {
              if (goal.status == GoalStatus.achieved) {
                _notifications.showGoalCompletedNotification(goal);
              }
              await _firebase.updateGoal(goal);
              await _local.markAsSynced(id, 'goal');
            }
            break;
          case 'delete':
            await _firebase.deleteGoal(id);
            await _local.markAsSynced(id, 'goal');
            break;
        }
      } catch (e) {
        print('[Sync] Goal $id failed: $e');
      }
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }
}
