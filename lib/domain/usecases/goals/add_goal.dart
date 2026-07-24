import '../../entities/goal.dart';
import '../../repositories/i_goal_repository.dart';

class AddGoalUsecase {
  final GoalRepository _repository;
  AddGoalUsecase(this._repository);

  Future<String?> call(Goal goal) async {
    _repository.saveLocalGoal(goal);
    final result = await _repository.addGoal(goal);
    if (result.isSuccess) {
      _repository.markLocalSynced(goal.id);
    }
    return result.error;
  }
}