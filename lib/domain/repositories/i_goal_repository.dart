import '../../../core/error/result.dart';
import '../entities/goal.dart';

abstract class GoalRepository {
  Stream<List<Goal>> getGoalsStream();
  Future<List<Goal>> fetchAllGoals();
  Future<Result<void>> addGoal(Goal goal);
  Future<Result<void>> updateGoal(Goal goal);
  Future<Result<void>> deleteGoal(String id);
  Future<Result<void>> contributeToGoal(String goalId, double amount);
  Future<Result<void>> removeContribution(String goalId, String contributionId, double amount);
  Future<Result<void>> editContribution(String goalId, String contributionId, double oldAmount, double newAmount);
  List<Goal> getLocalGoals();
  void saveLocalGoal(Goal goal, {bool fromFirestore = false});
  void saveAllLocalGoals(List<Goal> goals);
  void updateLocalGoal(Goal goal, {bool fromFirestore = false});
  void deleteLocalGoal(String id);
  void markLocalSynced(String id);
}