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

  /// Whether a remote (Firestore) observer is currently running.
  /// Guards against stacking multiple `emit.forEach` subscriptions when
  /// `TransactionLoadRequested` is dispatched repeatedly (pull-to-refresh,
  /// SMS import, sign-in/sign-out).
  bool _isObservingRemote = false;

  Future<void> _onLoadRequested(
    TransactionLoadRequested event,
    Emitter<TransactionState> emit,
  ) async {
    // Always surface the locally stored transactions immediately so the UI
    // updates instantly (guest mode, offline, or right after an SMS import).
    if (state is! TransactionLoaded) emit(TransactionLoading());
    emit(TransactionLoaded(transactions: getTransactions.getLocal(), isLocalOnly: true));

    if (_isObservingRemote) return;

    _isObservingRemote = true;
    try {
      await emit.forEach(
        getTransactions.observe(),
        onData: (firestoreTxs) {
          if (firestoreTxs.isEmpty) {
            // Remote empty/unreadable: keep whatever is stored locally instead
            // of blanking the ledger (guest mode, signed out, parse errors).
            return TransactionLoaded(
              transactions: getTransactions.getLocal(),
              isLocalOnly: true,
            );
          }
          transactionRepository.saveAllLocalTransactions(firestoreTxs);
          return TransactionLoaded(transactions: firestoreTxs);
        },
        onError: (error, stack) {
          _isObservingRemote = false;
          return TransactionLoaded(
            transactions: getTransactions.getLocal(),
            isLocalOnly: true,
          );
        },
      );
    } finally {
      _isObservingRemote = false;
    }
  }

  Future<void> _onAddRequested(
    TransactionAddRequested event,
    Emitter<TransactionState> emit,
  ) async {
    await addTransaction.call(null, event.transaction);
    try {
      _notifications.showTransactionLoggedNotification(
        amount: event.transaction.amount,
        isDebit: event.transaction.type == TransactionType.debit,
      );
    } catch (_) {}
    emit(TransactionLoaded(
      transactions: getTransactions.getLocal(),
      isLocalOnly: true,
    ));
  }

  Future<void> _onUpdateRequested(
    TransactionUpdateRequested event,
    Emitter<TransactionState> emit,
  ) async {
    await updateTransaction.call(event.transaction);
    emit(TransactionLoaded(
      transactions: getTransactions.getLocal(),
      isLocalOnly: true,
    ));
  }

  Future<void> _onDeleteRequested(
    TransactionDeleteRequested event,
    Emitter<TransactionState> emit,
  ) async {
    await deleteTransaction.call(event.id);
    emit(TransactionLoaded(
      transactions: getTransactions.getLocal(),
      isLocalOnly: true,
    ));
  }
}
