import '../../repositories/i_goal_repository.dart';

class ContributeToGoalUsecase {
  final GoalRepository _repository;
  ContributeToGoalUsecase(this._repository);

  Future<String?> call(String goalId, double amount) async {
    final result = await _repository.contributeToGoal(goalId, amount);
    return result.error;
  }
}