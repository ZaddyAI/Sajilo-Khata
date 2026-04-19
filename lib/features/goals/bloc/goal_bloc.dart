import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../core/models/goal_model.dart';
import 'goal_event.dart';
import 'goal_state.dart';

class GoalBloc extends Bloc<GoalEvent, GoalState> {
  final FirebaseService _firebaseService;
  final LocalStorageService _local = LocalStorageService.instance;
  final _notifications = NotificationService.instance;

  GoalBloc(this._firebaseService) : super(GoalInitial()) {
    on<GoalLoadRequested>(_onLoadRequested);
    on<GoalAddRequested>(_onAddRequested);
    on<GoalContributeRequested>(_onContributeRequested);
    on<GoalRemoveContributionRequested>(_onRemoveContributionRequested);
    on<GoalEditContributionRequested>(_onEditContributionRequested);
    on<GoalDeleteRequested>(_onDeleteRequested);
    on<GoalUpdateRequested>(_onUpdateRequested);
  }

  Future<void> _onLoadRequested(
    GoalLoadRequested event,
    Emitter<GoalState> emit,
  ) async {
    emit(GoalLoading());
    await emit.forEach(
      _firebaseService.goalsStream(),
      onData: (goals) => GoalLoaded(goals: goals),
      onError: (error, _) => GoalError(message: error.toString()),
    );
  }

  Future<void> _onAddRequested(
    GoalAddRequested event,
    Emitter<GoalState> emit,
  ) async {
    try {
      await _firebaseService.addGoal(event.goal);
      _notifications.showGoalCreatedNotification(event.goal);
    } catch (e) {
      await _local.saveGoalLocal(event.goal);
      _notifications.showGoalCreatedNotification(event.goal);
    }
  }

  Future<void> _onContributeRequested(
    GoalContributeRequested event,
    Emitter<GoalState> emit,
  ) async {
    try {
      await _firebaseService.contributeToGoal(event.goalId, event.amount);
      final goal = _local.getGoalLocal(event.goalId);
      if (goal != null && goal.status == GoalStatus.achieved) {
        _notifications.showGoalCompletedNotification(goal);
      }
    } catch (e) {
      // fallback not implemented - just sync later
    }
  }

  Future<void> _onRemoveContributionRequested(
    GoalRemoveContributionRequested event,
    Emitter<GoalState> emit,
  ) async {
    try {
      await _firebaseService.removeContribution(
        event.goalId,
        event.contributionId,
        event.amount,
      );
    } catch (e) {
      // handle error
    }
  }

  Future<void> _onEditContributionRequested(
    GoalEditContributionRequested event,
    Emitter<GoalState> emit,
  ) async {
    try {
      await _firebaseService.editContribution(
        event.goalId,
        event.contributionId,
        event.oldAmount,
        event.newAmount,
      );
    } catch (e) {
      // handle error
    }
  }

  Future<void> _onDeleteRequested(
    GoalDeleteRequested event,
    Emitter<GoalState> emit,
  ) async {
    try {
      await _firebaseService.deleteGoal(event.id);
    } catch (e) {
      await _local.deleteGoalLocal(event.id);
    }
  }

  Future<void> _onUpdateRequested(
    GoalUpdateRequested event,
    Emitter<GoalState> emit,
  ) async {
    try {
      await _firebaseService.updateGoal(event.goal);
      if (event.goal.status == GoalStatus.achieved) {
        _notifications.showGoalCompletedNotification(event.goal);
      }
    } catch (e) {
      await _local.updateGoalLocal(event.goal);
    }
  }
}
