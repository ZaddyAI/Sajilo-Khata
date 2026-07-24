import 'package:equatable/equatable.dart';
import '../../../domain/entities/goal.dart';

abstract class GoalState extends Equatable {
  @override
  List<Object?> get props => [];
}

class GoalInitial extends GoalState {}

class GoalLoading extends GoalState {}

class GoalLoaded extends GoalState {
  final List<Goal> goals;
  final bool isLocalOnly;

  GoalLoaded({required this.goals, this.isLocalOnly = false});

  @override
  List<Object?> get props => [goals, isLocalOnly];

  List<Goal> get activeGoals =>
      goals.where((g) => g.status != GoalStatus.achieved).toList();

  List<Goal> get achievedGoals =>
      goals.where((g) => g.status == GoalStatus.achieved).toList();

  double get totalSaved => goals.fold(0.0, (sum, g) => sum + g.savedAmount);
}

class GoalError extends GoalState {
  final String message;

  GoalError({required this.message});

  @override
  List<Object?> get props => [message];
}