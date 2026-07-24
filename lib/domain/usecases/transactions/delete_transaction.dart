import '../../repositories/i_transaction_repository.dart';

class DeleteTransactionUsecase {
  final TransactionRepository _repository;
  DeleteTransactionUsecase(this._repository);

  Future<String?> call(String id) async {
    _repository.deleteLocalTransaction(id);
    final result = await _repository.deleteTransaction(id);
    if (result.isSuccess) {
      _repository.markLocalSynced(id);
    }
    return result.error;
  }
}