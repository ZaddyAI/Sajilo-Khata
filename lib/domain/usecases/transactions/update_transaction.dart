import '../../entities/transaction.dart';
import '../../repositories/i_transaction_repository.dart';

class UpdateTransactionUsecase {
  final TransactionRepository _repository;
  UpdateTransactionUsecase(this._repository);

  Future<String?> call(Transaction transaction) async {
    _repository.updateLocalTransaction(transaction);
    final result = await _repository.updateTransaction(transaction);
    if (result.isSuccess) {
      _repository.markLocalSynced(transaction.id);
    }
    return result.error;
  }
}