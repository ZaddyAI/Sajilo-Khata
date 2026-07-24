import '../../repositories/i_goal_repository.dart';

class EditContributionUsecase {
  final GoalRepository _repository;
  EditContributionUsecase(this._repository);

  Future<String?> call(String goalId, String contributionId, double oldAmount, double newAmount) async {
    final result = await _repository.editContribution(goalId, contributionId, oldAmount, newAmount);
    return result.error;
  }
}