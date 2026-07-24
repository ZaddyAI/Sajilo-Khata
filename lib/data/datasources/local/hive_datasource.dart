import 'package:hive_flutter/hive_flutter.dart';
import '../../models/transaction_model.dart';
import '../../models/goal_model.dart';
import '../../../domain/entities/transaction.dart';
import '../../../domain/entities/goal.dart';

enum SyncStatus { pending, synced, conflict }

class HiveDataSource {
  static const String _transactionsBox = 'transactions';
  static const String _goalsBox = 'goals';
  static const String _syncQueueBox = 'sync_queue';
  static const String _settingsBoxName = 'settings';

  late final Box<Map<dynamic, dynamic>> _txBox;
  late final Box<Map<dynamic, dynamic>> _goalBox;
  late final Box _queueBox;
  late final Box _settingsBox;

  Future<void> init() async {
    await Hive.initFlutter();
    _txBox = await Hive.openBox<Map<dynamic, dynamic>>(_transactionsBox);
    _goalBox = await Hive.openBox<Map<dynamic, dynamic>>(_goalsBox);
    _queueBox = await Hive.openBox(_syncQueueBox);
    _settingsBox = await Hive.openBox(_settingsBoxName);
  }

  // ── Transactions ──

  void saveTransaction(Transaction tx, {bool fromFirestore = false}) {
    final data = TransactionModel.toMap(tx);
    data['_syncStatus'] = fromFirestore
        ? SyncStatus.synced.name
        : SyncStatus.pending.name;
    data['_createdAt'] = tx.createdAt.toIso8601String();
    _txBox.put(tx.id, data);
    if (!fromFirestore) _addToSyncQueue('transaction', tx.id, 'create');
  }

  void updateTransaction(Transaction tx, {bool fromFirestore = false}) {
    final data = TransactionModel.toMap(tx);
    data['_syncStatus'] = fromFirestore
        ? SyncStatus.synced.name
        : SyncStatus.pending.name;
    _txBox.put(tx.id, data);
    if (!fromFirestore) _addToSyncQueue('transaction', tx.id, 'update');
  }

  void deleteTransaction(String id) {
    _txBox.delete(id);
    _addToSyncQueue('transaction', id, 'delete');
  }

  List<Transaction> getAllTransactions() {
    final result = <Transaction>[];
    for (final key in _txBox.keys) {
      final data = _txBox.get(key);
      if (data != null) {
        try {
          result.add(
            TransactionModel.fromMap(
              Map<String, dynamic>.from(data),
              key.toString(),
            ),
          );
        } catch (_) {}
      }
    }
    result.sort((a, b) => b.dateAD.compareTo(a.dateAD));
    return result;
  }

  void saveAllTransactions(List<Transaction> transactions) {
    for (final tx in transactions) {
      final existing = _txBox.get(tx.id);
      if (existing == null ||
          existing['_syncStatus'] != SyncStatus.pending.name) {
        saveTransaction(tx, fromFirestore: true);
      }
    }
  }

  Transaction? getTransaction(String id) {
    final data = _txBox.get(id);
    if (data == null) return null;
    return TransactionModel.fromMap(Map<String, dynamic>.from(data), id);
  }

  // ── Goals ──

  void saveGoal(Goal goal, {bool fromFirestore = false}) {
    final data = GoalModel.toMap(goal);
    data['_syncStatus'] = fromFirestore
        ? SyncStatus.synced.name
        : SyncStatus.pending.name;
    data['_createdAt'] = DateTime.now().toIso8601String();
    _goalBox.put(goal.id, data);
    if (!fromFirestore) _addToSyncQueue('goal', goal.id, 'create');
  }

  void updateGoal(Goal goal, {bool fromFirestore = false}) {
    final data = GoalModel.toMap(goal);
    data['_syncStatus'] = fromFirestore
        ? SyncStatus.synced.name
        : SyncStatus.pending.name;
    _goalBox.put(goal.id, data);
    if (!fromFirestore) _addToSyncQueue('goal', goal.id, 'update');
  }

  void deleteGoal(String id) {
    _goalBox.delete(id);
    _addToSyncQueue('goal', id, 'delete');
  }

  List<Goal> getAllGoals() {
    final result = <Goal>[];
    for (final key in _goalBox.keys) {
      final data = _goalBox.get(key);
      if (data != null) {
        try {
          result.add(
            GoalModel.fromMap(Map<String, dynamic>.from(data), key.toString()),
          );
        } catch (_) {}
      }
    }
    return result;
  }

  void saveAllGoals(List<Goal> goals) {
    for (final goal in goals) {
      final existing = _goalBox.get(goal.id);
      if (existing == null ||
          existing['_syncStatus'] != SyncStatus.pending.name) {
        saveGoal(goal, fromFirestore: true);
      }
    }
  }

  Goal? getGoal(String id) {
    final data = _goalBox.get(id);
    if (data == null) return null;
    return GoalModel.fromMap(Map<String, dynamic>.from(data), id);
  }

  // ── Sync Queue ──

  void _addToSyncQueue(String type, String id, String action) {
    final existing = _queueBox.get('queue') as List? ?? [];
    final queue = List<Map>.from(existing);
    queue.add({
      'type': type,
      'id': id,
      'action': action,
      'timestamp': DateTime.now().toIso8601String(),
    });
    _queueBox.put('queue', queue);
  }

  List<Map> getSyncQueue() {
    final queue = _queueBox.get('queue');
    if (queue == null) return [];
    return List<Map>.from(queue as List);
  }

  void clearSyncQueue() => _queueBox.delete('queue');

  void removeFromSyncQueue(String id) {
    final queue = getSyncQueue();
    queue.removeWhere((item) => item['id'] == id);
    _queueBox.put('queue', queue);
  }

  // ── Settings ──

  Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }

  T? getSetting<T>(String key, {T? defaultValue}) {
    return _settingsBox.get(key, defaultValue: defaultValue) as T?;
  }

  // ── Sync Status ──

  void markAsSynced(String id, String type) {
    if (type == 'transaction') {
      final data = _txBox.get(id);
      if (data != null) {
        final map = Map<String, dynamic>.from(data);
        map['_syncStatus'] = SyncStatus.synced.name;
        _txBox.put(id, map);
      }
    } else if (type == 'goal') {
      final data = _goalBox.get(id);
      if (data != null) {
        final map = Map<String, dynamic>.from(data);
        map['_syncStatus'] = SyncStatus.synced.name;
        _goalBox.put(id, map);
      }
    }
    removeFromSyncQueue(id);
  }

  bool get hasPendingSync => getSyncQueue().isNotEmpty;
}
