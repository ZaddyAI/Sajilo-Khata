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

  Future<void> _onLoadRequested(
    GoalLoadRequested event,
    Emitter<GoalState> emit,
  ) async {
    emit(GoalLoading());

    final localGoals = getGoals.getLocal();
    if (localGoals.isNotEmpty) {
      emit(GoalLoaded(goals: localGoals, isLocalOnly: true));
    }

    await emit.forEach(
      getGoals.observe(),
      onData: (firestoreGoals) {
        goalRepository.saveAllLocalGoals(firestoreGoals);
        return GoalLoaded(goals: firestoreGoals);
      },
      onError: (error, stack) {
        print('[GoalBloc] Firestore stream error: $error');
        return GoalLoaded(goals: [], isLocalOnly: true);
      },
    );
  }

  Future<void> _onAddRequested(
    GoalAddRequested event,
    Emitter<GoalState> emit,
  ) async {
    await addGoal.call(event.goal);
    _notifications.showGoalCreatedNotification(event.goal);
  }

  Future<void> _onContributeRequested(
    GoalContributeRequested event,
    Emitter<GoalState> emit,
  ) async {
    await contributeToGoal.call(event.goalId, event.amount);
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
    );
  }

  Future<void> _onDeleteRequested(
    GoalDeleteRequested event,
    Emitter<GoalState> emit,
  ) async {
    await deleteGoal.call(event.id);
  }

  Future<void> _onUpdateRequested(
    GoalUpdateRequested event,
    Emitter<GoalState> emit,
  ) async {
    if (event.goal.status == GoalStatus.achieved) {
      _notifications.showGoalCompletedNotification(event.goal);
    }
    await updateGoal.call(event.goal);
  }
}
