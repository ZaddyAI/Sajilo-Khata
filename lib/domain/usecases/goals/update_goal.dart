import '../../entities/goal.dart';
import '../../repositories/i_goal_repository.dart';

class UpdateGoalUsecase {
  final GoalRepository _repository;
  UpdateGoalUsecase(this._repository);

  Future<String?> call(Goal goal) async {
    _repository.updateLocalGoal(goal);
    final result = await _repository.updateGoal(goal);
    if (result.isSuccess) {
      _repository.markLocalSynced(goal.id);
    }
    return result.error;
  }
}