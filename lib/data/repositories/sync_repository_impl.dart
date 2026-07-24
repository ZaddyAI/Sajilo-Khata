import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/error/result.dart';
import '../../../domain/repositories/i_sync_repository.dart';
import '../datasources/remote/firebase_firestore_datasource.dart';
import '../datasources/local/hive_datasource.dart';

class SyncRepositoryImpl implements SyncRepository {
  final FirebaseFirestoreDataSource _remoteDataSource;
  final HiveDataSource _localDataSource;
  final Connectivity _connectivity;

  StreamSubscription? _connectivitySubscription;
  bool _isSyncing = false;
  ConnectivityResult _lastResult = ConnectivityResult.none;

  final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();

  SyncRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
    this._connectivity,
  );

  @override
  Stream<bool> get connectivityStream => _connectivityController.stream;

  @override
  Future<bool> get isOnline async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result.isNotEmpty && result.first != ConnectivityResult.none;
    } catch (_) {
      return false;
    }
  }

  @override
  bool get hasPendingSync => _localDataSource.hasPendingSync;

  @override
  Future<void> init() async {
    try {
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
        results,
      ) {
        final wasOffline = _lastResult == ConnectivityResult.none;
        _lastResult = results.isNotEmpty
            ? results.first
            : ConnectivityResult.none;
        _connectivityController.add(_lastResult != ConnectivityResult.none);

        if (wasOffline && _lastResult != ConnectivityResult.none) {
          syncAll();
        }
      });
      final result = await _connectivity.checkConnectivity();
      _lastResult = result.isNotEmpty ? result.first : ConnectivityResult.none;
      _connectivityController.add(_lastResult != ConnectivityResult.none);
    } catch (_) {
      _lastResult = ConnectivityResult.none;
      _connectivityController.add(false);
    }
  }

  @override
  Future<Result<void>> syncAll() async {
    if (_isSyncing) return Result.failure('Already syncing');
    final online = await isOnline;
    if (!online) return Result.failure('No internet');

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Result.failure('Not authenticated');

    _isSyncing = true;
    try {
      await _pushToFirestore();
      await _pullFromFirestore();
      return Result.success(null);
    } catch (e) {
      return Result.failure(e.toString());
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _pushToFirestore() async {
    final queue = _localDataSource.getSyncQueue();
    for (final item in queue) {
      final id = item['id'] as String;
      final type = item['type'] as String;
      final action = item['action'] as String;

      try {
        if (type == 'transaction') {
          await _syncTransactionItem(id, action);
        } else if (type == 'goal') {
          await _syncGoalItem(id, action);
        }
      } catch (e) {
        print('[Sync] Item $id failed: $e');
      }
    }
  }

  Future<void> _syncTransactionItem(String id, String action) async {
    switch (action) {
      case 'create' || 'update':
        final tx = _localDataSource.getTransaction(id);
        if (tx != null) {
          await _remoteDataSource.addTransaction(null, tx);
          _localDataSource.markAsSynced(id, 'transaction');
        }
        break;
      case 'delete':
        await _remoteDataSource.deleteTransaction(id);
        _localDataSource.markAsSynced(id, 'transaction');
        break;
    }
  }

  Future<void> _syncGoalItem(String id, String action) async {
    switch (action) {
      case 'create' || 'update':
        final goal = _localDataSource.getGoal(id);
        if (goal != null) {
          await _remoteDataSource.addGoal(goal);
          _localDataSource.markAsSynced(id, 'goal');
        }
        break;
      case 'delete':
        await _remoteDataSource.deleteGoal(id);
        _localDataSource.markAsSynced(id, 'goal');
        break;
    }
  }

  Future<void> _pullFromFirestore() async {
    try {
      final remoteTxs = await _remoteDataSource.fetchAllTransactions();
      if (remoteTxs.isNotEmpty) _localDataSource.saveAllTransactions(remoteTxs);

      final remoteGoals = await _remoteDataSource.fetchAllGoals();
      if (remoteGoals.isNotEmpty) _localDataSource.saveAllGoals(remoteGoals);
    } catch (e) {
      print('[Sync] Pull failed: $e');
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityController.close();
  }
}
