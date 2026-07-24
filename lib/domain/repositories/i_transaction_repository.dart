import '../../../core/error/result.dart';
import '../entities/transaction.dart';

abstract class TransactionRepository {
  Stream<List<Transaction>> getTransactionsStream();
  Future<List<Transaction>> fetchAllTransactions();
  Future<Result<void>> addTransaction(String? duplicateKey, Transaction transaction);
  Future<Result<void>> updateTransaction(Transaction transaction);
  Future<Result<void>> deleteTransaction(String id);
  Future<Result<bool>> checkDuplicate(String key);
  List<Transaction> getLocalTransactions();
  void saveLocalTransaction(Transaction transaction, {bool fromFirestore = false});
  void saveAllLocalTransactions(List<Transaction> transactions);
  void updateLocalTransaction(Transaction transaction, {bool fromFirestore = false});
  void deleteLocalTransaction(String id);
  void markLocalSynced(String id);
}