import 'package:equatable/equatable.dart';
import '../../../core/models/goal_model.dart';

abstract class GoalState extends Equatable {
  @override
  List<Object?> get props => [];
}

class GoalInitial extends GoalState {}

class GoalLoading extends GoalState {}

class GoalLoaded extends GoalState {
  final List<GoalModel> goals;

  GoalLoaded({required this.goals});

  @override
  List<Object?> get props => [goals];

  List<GoalModel> get activeGoals =>
      goals.where((g) => g.status != GoalStatus.achieved).toList();

  List<GoalModel> get achievedGoals =>
      goals.where((g) => g.status == GoalStatus.achieved).toList();

  double get totalSaved => goals.fold(0.0, (sum, g) => sum + g.savedAmount);
}

class GoalError extends GoalState {
  final String message;

  GoalError({required this.message});

  @override
  List<Object?> get props => [message];
}