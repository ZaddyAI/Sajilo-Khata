import 'package:equatable/equatable.dart';
import '../../../domain/entities/transaction.dart';

abstract class TransactionEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class TransactionLoadRequested extends TransactionEvent {}

class TransactionAddRequested extends TransactionEvent {
  final Transaction transaction;

  TransactionAddRequested({required this.transaction});

  @override
  List<Object?> get props => [transaction.id];
}

class TransactionUpdateRequested extends TransactionEvent {
  final Transaction transaction;

  TransactionUpdateRequested({required this.transaction});

  @override
  List<Object?> get props => [transaction.id];
}

class TransactionDeleteRequested extends TransactionEvent {
  final String id;

  TransactionDeleteRequested({required this.id});

  @override
  List<Object?> get props => [id];
}