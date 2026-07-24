import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/notification_service.dart';
import '../../../domain/entities/transaction.dart';
import '../../../domain/repositories/i_transaction_repository.dart';
import '../../../domain/usecases/transactions/add_transaction.dart';
import '../../../domain/usecases/transactions/delete_transaction.dart';
import '../../../domain/usecases/transactions/get_transactions.dart';
import '../../../domain/usecases/transactions/update_transaction.dart';
import 'transaction_event.dart';
import 'transaction_state.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final TransactionRepository transactionRepository;
  final GetTransactions getTransactions;
  final AddTransaction addTransaction;
  final UpdateTransactionUsecase updateTransaction;
  final DeleteTransactionUsecase deleteTransaction;
  final _notifications = NotificationService.instance;

  TransactionBloc({
    required this.transactionRepository,
    required this.getTransactions,
    required this.addTransaction,
    required this.updateTransaction,
    required this.deleteTransaction,
  }) : super(TransactionInitial()) {
    on<TransactionLoadRequested>(_onLoadRequested);
    on<TransactionAddRequested>(_onAddRequested);
    on<TransactionUpdateRequested>(_onUpdateRequested);
    on<TransactionDeleteRequested>(_onDeleteRequested);
    add(TransactionLoadRequested());
  }

  Future<void> _onLoadRequested(
    TransactionLoadRequested event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());

    final localTxs = getTransactions.getLocal();
    if (localTxs.isNotEmpty) {
      emit(TransactionLoaded(transactions: localTxs, isLocalOnly: true));
    }

    await emit.forEach(
      getTransactions.observe(),
      onData: (firestoreTxs) {
        transactionRepository.saveAllLocalTransactions(firestoreTxs);
        return TransactionLoaded(transactions: firestoreTxs);
      },
      onError: (error, stack) {
        print('[TxBloc] Firestore stream error: $error');
        return TransactionLoaded(transactions: [], isLocalOnly: true);
      },
    );
  }

  Future<void> _onAddRequested(
    TransactionAddRequested event,
    Emitter<TransactionState> emit,
  ) async {
    await addTransaction.call(null, event.transaction);
    _notifications.showTransactionLoggedNotification(
      amount: event.transaction.amount,
      isDebit: event.transaction.type == TransactionType.debit,
    );
  }

  Future<void> _onUpdateRequested(
    TransactionUpdateRequested event,
    Emitter<TransactionState> emit,
  ) async {
    await updateTransaction.call(event.transaction);
  }

  Future<void> _onDeleteRequested(
    TransactionDeleteRequested event,
    Emitter<TransactionState> emit,
  ) async {
    await deleteTransaction.call(event.id);
  }
}
