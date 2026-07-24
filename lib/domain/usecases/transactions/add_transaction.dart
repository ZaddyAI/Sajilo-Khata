import '../../entities/transaction.dart';
import '../../repositories/i_transaction_repository.dart';
import '../../../core/utils/categorizer.dart';

class AddTransaction {
  final TransactionRepository _repository;
  AddTransaction(this._repository);

  Future<String?> call(String? duplicateKey, Transaction transaction) async {
    final category = transaction.category.isEmpty
        ? Categorizer.categorize(note: transaction.note, bank: transaction.bank)
        : transaction.category;
    final tx = transaction.copyWith(category: category);

    _repository.saveLocalTransaction(tx);

    final result = await _repository.addTransaction(duplicateKey, tx);
    if (result.isSuccess) {
      _repository.markLocalSynced(tx.id);
    }
    return result.error;
  }
}