import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction_model.dart';
import '../models/goal_model.dart';

enum SyncStatus { pending, synced, conflict }

class LocalStorageService {
  static final LocalStorageService instance = LocalStorageService._();
  LocalStorageService._();

  static const String transactionsBox = 'transactions';
  static const String goalsBox = 'goals';
  static const String syncQueueBox = 'sync_queue';
  static const String settingsBox = 'settings';

  static bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    
    await Hive.openBox<Map<dynamic, dynamic>>(transactionsBox);
    await Hive.openBox<Map<dynamic, dynamic>>(goalsBox);
    await Hive.openBox<Map<dynamic, dynamic>>(syncQueueBox);
    await Hive.openBox(settingsBox);
    
    _initialized = true;
  }

  Box<Map<dynamic, dynamic>> get _txBox => Hive.box<Map<dynamic, dynamic>>(transactionsBox);
  Box<Map<dynamic, dynamic>> get _goalBox => Hive.box<Map<dynamic, dynamic>>(goalsBox);
  Box get _queueBox => Hive.box(syncQueueBox);
  Box get _settingsBox => Hive.box(settingsBox);

  // ── Transactions ─────────────────────────────────────────────────────────────

  Future<void> saveTransactionLocal(TransactionModel tx) async {
    final data = tx.toMap();
    data['_syncStatus'] = SyncStatus.pending.name;
    data['_createdAt'] = tx.createdAt.toIso8601String();
    await _txBox.put(tx.id, data);
    await _addToSyncQueue('transaction', tx.id, 'create');
  }

  Future<void> updateTransactionLocal(TransactionModel tx) async {
    final data = tx.toMap();
    data['_syncStatus'] = SyncStatus.pending.name;
    await _txBox.put(tx.id, data);
    await _addToSyncQueue('transaction', tx.id, 'update');
  }

  Future<void> deleteTransactionLocal(String id) async {
    await _txBox.delete(id);
    await _addToSyncQueue('transaction', id, 'delete');
  }

  List<TransactionModel> getAllTransactionsLocal() {
    final List<TransactionModel> result = [];
    for (final key in _txBox.keys) {
      final data = _txBox.get(key);
      if (data != null) {
        try {
          final map = Map<String, dynamic>.from(data);
          result.add(TransactionModel.fromMap(map, key.toString()));
        } catch (_) {}
      }
    }
    result.sort((a, b) => b.dateAD.compareTo(a.dateAD));
    return result;
  }

  TransactionModel? getTransactionLocal(String id) {
    final data = _txBox.get(id);
    if (data == null) return null;
    return TransactionModel.fromMap(Map<String, dynamic>.from(data), id);
  }

  // ── Goals ───────────────────────────────────────────────────────────────────────

  Future<void> saveGoalLocal(GoalModel goal) async {
    final data = goal.toMap();
    data['_syncStatus'] = SyncStatus.pending.name;
    data['_createdAt'] = DateTime.now().toIso8601String();
    await _goalBox.put(goal.id, data);
    await _addToSyncQueue('goal', goal.id, 'create');
  }

  Future<void> updateGoalLocal(GoalModel goal) async {
    final data = goal.toMap();
    data['_syncStatus'] = SyncStatus.pending.name;
    await _goalBox.put(goal.id, data);
    await _addToSyncQueue('goal', goal.id, 'update');
  }

  Future<void> deleteGoalLocal(String id) async {
    await _goalBox.delete(id);
    await _addToSyncQueue('goal', id, 'delete');
  }

  List<GoalModel> getAllGoalsLocal() {
    final List<GoalModel> result = [];
    for (final key in _goalBox.keys) {
      final data = _goalBox.get(key);
      if (data != null) {
        try {
          final map = Map<String, dynamic>.from(data);
          result.add(GoalModel.fromMap(map, key.toString()));
        } catch (_) {}
      }
    }
    return result;
  }

  GoalModel? getGoalLocal(String id) {
    final data = _goalBox.get(id);
    if (data == null) return null;
    return GoalModel.fromMap(Map<String, dynamic>.from(data), id);
  }

  // ── Sync Queue ───────────────────────────────────────────────────────

  Future<void> _addToSyncQueue(String type, String id, String action) async {
    final existing = _queueBox.get('queue') as List? ?? [];
    final queue = List<Map>.from(existing);
    queue.add({
      'type': type,
      'id': id,
      'action': action,
      'timestamp': DateTime.now().toIso8601String(),
    });
    await _queueBox.put('queue', queue);
  }

  List<Map> getSyncQueue() {
    final queue = _queueBox.get('queue');
    if (queue == null) return [];
    return List<Map>.from(queue as List);
  }

  Future<void> clearSyncQueue() async {
    await _queueBox.delete('queue');
  }

  Future<void> removeFromSyncQueue(String id) async {
    final queue = getSyncQueue();
    queue.removeWhere((item) => item['id'] == id);
    await _queueBox.put('queue', queue);
  }

  // ── Settings ───────────────────────────────────────────────────────

  Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }

  T? getSetting<T>(String key, {T? defaultValue}) {
    return _settingsBox.get(key, defaultValue: defaultValue) as T?;
  }

  // ── Utilities ────────────────────────────────────────────────────

  Future<void> markAsSynced(String id, String type) async {
    if (type == 'transaction') {
      final data = _txBox.get(id);
      if (data != null) {
        final map = Map<String, dynamic>.from(data);
        map['syncStatus'] = SyncStatus.synced.name;
        await _txBox.put(id, map);
      }
    } else if (type == 'goal') {
      final data = _goalBox.get(id);
      if (data != null) {
        final map = Map<String, dynamic>.from(data);
        map['syncStatus'] = SyncStatus.synced.name;
        await _goalBox.put(id, map);
      }
    }
    await removeFromSyncQueue(id);
  }

  List<Map> get pendingItems {
    final txPending = _txBox.values.where((d) => d['_syncStatus'] == SyncStatus.pending.name);
    final goalPending = _goalBox.values.where((d) => d['_syncStatus'] == SyncStatus.pending.name);
    return [...txPending, ...goalPending];
  }

  bool get hasPendingSync => getSyncQueue().isNotEmpty;
}