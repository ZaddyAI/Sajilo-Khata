import 'dart:async';
import '../../../core/error/result.dart';
import '../../../domain/entities/transaction.dart';
import '../../../domain/repositories/i_transaction_repository.dart';
import '../datasources/remote/firebase_firestore_datasource.dart';
import '../datasources/local/hive_datasource.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final FirebaseFirestoreDataSource _remoteDataSource;
  final HiveDataSource _localDataSource;

  TransactionRepositoryImpl(this._remoteDataSource, this._localDataSource);

  @override
  Future<Result<void>> addTransaction(
    String? duplicateKey,
    Transaction transaction,
  ) async {
    try {
      await _remoteDataSource.addTransaction(duplicateKey, transaction);
      return Result.success(null);
    } on Exception catch (e) {
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<bool>> checkDuplicate(String key) async {
    try {
      final isDuplicate = await _remoteDataSource.checkDuplicate(key);
      return Result.success(isDuplicate);
    } on Exception catch (e) {
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<void>> deleteTransaction(String id) async {
    try {
      await _remoteDataSource.deleteTransaction(id);
      return Result.success(null);
    } on Exception catch (e) {
      return Result.failure(e.toString());
    }
  }

  @override
  Future<List<Transaction>> fetchAllTransactions() async {
    try {
      return await _remoteDataSource.fetchAllTransactions();
    } catch (_) {
      return [];
    }
  }

  @override
  Stream<List<Transaction>> getTransactionsStream() {
    return _remoteDataSource.transactionsStream();
  }

  @override
  Future<Result<void>> updateTransaction(Transaction transaction) async {
    try {
      await _remoteDataSource.updateTransaction(transaction);
      return Result.success(null);
    } on Exception catch (e) {
      return Result.failure(e.toString());
    }
  }

  // ── Local Operations ──

  @override
  List<Transaction> getLocalTransactions() =>
      _localDataSource.getAllTransactions();

  @override
  void saveLocalTransaction(
    Transaction transaction, {
    bool fromFirestore = false,
  }) {
    _localDataSource.saveTransaction(transaction, fromFirestore: fromFirestore);
  }

  @override
  void saveAllLocalTransactions(List<Transaction> transactions) {
    _localDataSource.saveAllTransactions(transactions);
  }

  @override
  void updateLocalTransaction(
    Transaction transaction, {
    bool fromFirestore = false,
  }) {
    _localDataSource.updateTransaction(
      transaction,
      fromFirestore: fromFirestore,
    );
  }

  @override
  void deleteLocalTransaction(String id) {
    _localDataSource.deleteTransaction(id);
  }

  @override
  void markLocalSynced(String id) {
    _localDataSource.markAsSynced(id, 'transaction');
  }
}
