import 'package:equatable/equatable.dart';
import '../../../domain/entities/transaction.dart';

abstract class TransactionState extends Equatable {
  @override
  List<Object?> get props => [];
}

class TransactionInitial extends TransactionState {}

class TransactionLoading extends TransactionState {}

class TransactionLoaded extends TransactionState {
  final List<Transaction> transactions;
  final bool isLocalOnly;

  TransactionLoaded({required this.transactions, this.isLocalOnly = false});

  @override
  List<Object?> get props => [transactions, isLocalOnly];

  double get totalIncome => transactions
      .where((tx) => tx.type == TransactionType.credit)
      .fold(0.0, (sum, tx) => sum + tx.amount);

  double get totalExpense => transactions
      .where((tx) => tx.type == TransactionType.debit)
      .fold(0.0, (sum, tx) => sum + tx.amount);

  double get netBalance => totalIncome - totalExpense;

  Map<String, double> get categoryTotals {
    final Map<String, double> totals = {};
    for (final tx in transactions.where((tx) => tx.type == TransactionType.debit)) {
      totals[tx.category] = (totals[tx.category] ?? 0) + tx.amount;
    }
    return totals;
  }

  List<Transaction> getTransactionsForMonth(DateTime month) {
    return transactions.where((tx) {
      return tx.dateAD.year == month.year && tx.dateAD.month == month.month;
    }).toList();
  }
}

class TransactionError extends TransactionState {
  final String message;

  TransactionError({required this.message});

  @override
  List<Object?> get props => [message];
}