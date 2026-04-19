import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/categorizer.dart';
import '../../../core/models/transaction_model.dart';
import 'transaction_event.dart';
import 'transaction_state.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final FirebaseService _firebaseService;
  final LocalStorageService _local = LocalStorageService.instance;
  final _notifications = NotificationService.instance;

  TransactionBloc(this._firebaseService) : super(TransactionInitial()) {
    on<TransactionLoadRequested>(_onLoadRequested);
    on<TransactionAddRequested>(_onAddRequested);
    on<TransactionUpdateRequested>(_onUpdateRequested);
    on<TransactionDeleteRequested>(_onDeleteRequested);
  }

  Future<void> _onLoadRequested(
    TransactionLoadRequested event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    await emit.forEach(
      _firebaseService.transactionsStream(),
      onData: (transactions) => TransactionLoaded(transactions: transactions),
      onError: (error, _) => TransactionError(message: error.toString()),
    );
  }

  Future<void> _onAddRequested(
    TransactionAddRequested event,
    Emitter<TransactionState> emit,
  ) async {
    final category = event.transaction.category.isEmpty
        ? Categorizer.categorize(note: event.transaction.note, bank: event.transaction.bank)
        : event.transaction.category;
    final tx = event.transaction.copyWith(category: category);
    
    try {
      await _firebaseService.addTransaction(null, tx);
      _notifications.showTransactionLoggedNotification(
        amount: tx.amount,
        isDebit: tx.type == TransactionType.debit,
      );
    } catch (e) {
      await _local.saveTransactionLocal(tx);
      _notifications.showTransactionLoggedNotification(
        amount: tx.amount,
        isDebit: tx.type == TransactionType.debit,
      );
    }
  }

  Future<void> _onUpdateRequested(
    TransactionUpdateRequested event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      await _firebaseService.updateTransaction(event.transaction);
    } catch (e) {
      await _local.updateTransactionLocal(event.transaction);
    }
  }

  Future<void> _onDeleteRequested(
    TransactionDeleteRequested event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      await _firebaseService.deleteTransaction(event.id);
    } catch (e) {
      await _local.deleteTransactionLocal(event.id);
    }
  }
}