import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/notification_service.dart';
import '../../../domain/entities/goal.dart';
import '../../../domain/repositories/i_goal_repository.dart';
import '../../../domain/usecases/goals/add_goal.dart';
import '../../../domain/usecases/goals/contribute_to_goal.dart';
import '../../../domain/usecases/goals/delete_goal.dart';
import '../../../domain/usecases/goals/edit_contribution.dart';
import '../../../domain/usecases/goals/get_goals.dart';
import '../../../domain/usecases/goals/remove_contribution.dart';
import '../../../domain/usecases/goals/update_goal.dart';
import 'goal_event.dart';
import 'goal_state.dart';

class GoalBloc extends Bloc<GoalEvent, GoalState> {
  final GoalRepository goalRepository;
  final GetGoals getGoals;
  final AddGoalUsecase addGoal;
  final UpdateGoalUsecase updateGoal;
  final DeleteGoalUsecase deleteGoal;
  final ContributeToGoalUsecase contributeToGoal;
  final RemoveContributionUsecase removeContribution;
  final EditContributionUsecase editContribution;
  final _notifications = NotificationService.instance;

  GoalBloc({
    required this.goalRepository,
    required this.getGoals,
    required this.addGoal,
    required this.updateGoal,
    required this.deleteGoal,
    required this.contributeToGoal,
    required this.removeContribution,
    required this.editContribution,
  }) : super(GoalInitial()) {
    on<GoalLoadRequested>(_onLoadRequested);
    on<GoalAddRequested>(_onAddRequested);
    on<GoalContributeRequested>(_onContributeRequested);
    on<GoalRemoveContributionRequested>(_onRemoveContributionRequested);
    on<GoalEditContributionRequested>(_onEditContributionRequested);
    on<GoalDeleteRequested>(_onDeleteRequested);
    on<GoalUpdateRequested>(_onUpdateRequested);
    add(GoalLoadRequested());
  }

  /// Guards against stacking multiple remote observers when
  /// `GoalLoadRequested` is dispatched repeatedly (sign-in/sign-out, refresh).
  bool _isObservingRemote = false;

  Future<void> _onLoadRequested(
    GoalLoadRequested event,
    Emitter<GoalState> emit,
  ) async {
    if (state is! GoalLoaded) emit(GoalLoading());
    emit(GoalLoaded(goals: getGoals.getLocal(), isLocalOnly: true));

    if (_isObservingRemote) return;

    _isObservingRemote = true;
    try {
      await emit.forEach(
        getGoals.observe(),
        onData: (firestoreGoals) {
          if (firestoreGoals.isEmpty) {
            return GoalLoaded(goals: getGoals.getLocal(), isLocalOnly: true);
          }
          goalRepository.saveAllLocalGoals(firestoreGoals);
          return GoalLoaded(goals: firestoreGoals);
        },
        onError: (error, stack) {
          _isObservingRemote = false;
          return GoalLoaded(goals: getGoals.getLocal(), isLocalOnly: true);
        },
      );
    } finally {
      _isObservingRemote = false;
    }
  }

  Future<void> _onAddRequested(
    GoalAddRequested event,
    Emitter<GoalState> emit,
  ) async {
    await addGoal.call(event.goal);
    try {
      _notifications.showGoalCreatedNotification(event.goal);
    } catch (_) {}
    emit(GoalLoaded(goals: getGoals.getLocal(), isLocalOnly: true));
  }

  Future<void> _onContributeRequested(
    GoalContributeRequested event,
    Emitter<GoalState> emit,
  ) async {
    await contributeToGoal.call(event.goalId, event.amount);
    emit(GoalLoaded(goals: getGoals.getLocal(), isLocalOnly: true));
  }

  Future<void> _onRemoveContributionRequested(
    GoalRemoveContributionRequested event,
    Emitter<GoalState> emit,
  ) async {
    await removeContribution.call(
      event.goalId,
      event.contributionId,
      event.amount,
    );
    emit(GoalLoaded(goals: getGoals.getLocal(), isLocalOnly: true));
  }

  Future<void> _onEditContributionRequested(
    GoalEditContributionRequested event,
    Emitter<GoalState> emit,
  ) async {
    await editContribution.call(
      event.goalId,
      event.contributionId,
      event.oldAmount,
      event.newAmount,
      newDate: event.newDate,
    );
    emit(GoalLoaded(goals: getGoals.getLocal(), isLocalOnly: true));
  }

  Future<void> _onDeleteRequested(
    GoalDeleteRequested event,
    Emitter<GoalState> emit,
  ) async {
    await deleteGoal.call(event.id);
    emit(GoalLoaded(goals: getGoals.getLocal(), isLocalOnly: true));
  }

  Future<void> _onUpdateRequested(
    GoalUpdateRequested event,
    Emitter<GoalState> emit,
  ) async {
    if (event.goal.status == GoalStatus.achieved) {
      try {
        _notifications.showGoalCompletedNotification(event.goal);
      } catch (_) {}
    }
    await updateGoal.call(event.goal);
    emit(GoalLoaded(goals: getGoals.getLocal(), isLocalOnly: true));
  }
}
