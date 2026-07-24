import '../../repositories/i_goal_repository.dart';

class DeleteGoalUsecase {
  final GoalRepository _repository;
  DeleteGoalUsecase(this._repository);

  Future<String?> call(String id) async {
    _repository.deleteLocalGoal(id);
    final result = await _repository.deleteGoal(id);
    if (result.isSuccess) {
      _repository.markLocalSynced(id);
    }
    return result.error;
  }
}