import 'package:equatable/equatable.dart';
import '../../../domain/entities/goal.dart';

abstract class GoalEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class GoalLoadRequested extends GoalEvent {}

class GoalAddRequested extends GoalEvent {
  final Goal goal;

  GoalAddRequested({required this.goal});

  @override
  List<Object?> get props => [goal.id];
}

class GoalContributeRequested extends GoalEvent {
  final String goalId;
  final double amount;

  GoalContributeRequested({required this.goalId, required this.amount});

  @override
  List<Object?> get props => [goalId, amount];
}

class GoalRemoveContributionRequested extends GoalEvent {
  final String goalId;
  final String contributionId;
  final double amount;

  GoalRemoveContributionRequested({
    required this.goalId,
    required this.contributionId,
    required this.amount,
  });

  @override
  List<Object?> get props => [goalId, contributionId, amount];
}

class GoalEditContributionRequested extends GoalEvent {
  final String goalId;
  final String contributionId;
  final double oldAmount;
  final double newAmount;

  GoalEditContributionRequested({
    required this.goalId,
    required this.contributionId,
    required this.oldAmount,
    required this.newAmount,
  });

  @override
  List<Object?> get props => [goalId, contributionId, oldAmount, newAmount];
}

class GoalDeleteRequested extends GoalEvent {
  final String id;

  GoalDeleteRequested({required this.id});

  @override
  List<Object?> get props => [id];
}

class GoalUpdateRequested extends GoalEvent {
  final Goal goal;

  GoalUpdateRequested({required this.goal});

  @override
  List<Object?> get props => [goal.id];
}