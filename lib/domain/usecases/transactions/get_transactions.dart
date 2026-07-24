import 'dart:async';
import '../../entities/transaction.dart';
import '../../repositories/i_transaction_repository.dart';

class GetTransactions {
  final TransactionRepository _repository;
  GetTransactions(this._repository);

  List<Transaction> getLocal() => _repository.getLocalTransactions();

  Stream<List<Transaction>> observe() => _repository.getTransactionsStream();

  Future<List<Transaction>> fetchAll() => _repository.fetchAllTransactions();
}
