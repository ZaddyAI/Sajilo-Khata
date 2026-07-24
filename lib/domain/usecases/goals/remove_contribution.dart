import '../../repositories/i_goal_repository.dart';

class RemoveContributionUsecase {
  final GoalRepository _repository;
  RemoveContributionUsecase(this._repository);

  Future<String?> call(String goalId, String contributionId, double amount) async {
    final result = await _repository.removeContribution(goalId, contributionId, amount);
    return result.error;
  }
}