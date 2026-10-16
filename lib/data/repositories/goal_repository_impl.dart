import 'dart:async';
import '../../../core/error/result.dart';
import '../../../domain/entities/goal.dart';
import '../../../domain/repositories/i_goal_repository.dart';
import '../datasources/remote/firebase_firestore_datasource.dart';
import '../datasources/local/hive_datasource.dart';

class GoalRepositoryImpl implements GoalRepository {
  final FirebaseFirestoreDataSource _remoteDataSource;
  final HiveDataSource _localDataSource;

  GoalRepositoryImpl(this._remoteDataSource, this._localDataSource);

  @override
  Future<Result<void>> addGoal(Goal goal) async {
    _localDataSource.saveGoal(goal);
    try {
      await _remoteDataSource.addGoal(goal);
      _localDataSource.markAsSynced(goal.id, 'goal');
      return Result.success(null);
    } on Exception catch (e) {
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<void>> deleteGoal(String id) async {
    _localDataSource.deleteGoal(id);
    try {
      await _remoteDataSource.deleteGoal(id);
      return Result.success(null);
    } on Exception catch (e) {
      return Result.failure(e.toString());
    }
  }

  @override
  Future<List<Goal>> fetchAllGoals() async {
    try {
      return await _remoteDataSource.fetchAllGoals();
    } catch (_) {
      return [];
    }
  }

  @override
  Stream<List<Goal>> getGoalsStream() {
    return _remoteDataSource.goalsStream();
  }

  @override
  Future<Result<void>> updateGoal(Goal goal) async {
    _localDataSource.updateGoal(goal);
    try {
      await _remoteDataSource.updateGoal(goal);
      _localDataSource.markAsSynced(goal.id, 'goal');
      return Result.success(null);
    } on Exception catch (e) {
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<void>> contributeToGoal(String goalId, double amount) async {
    final goal = _localDataSource.getGoal(goalId);
    if (goal != null) {
      final contribution = SavingsContribution(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: amount,
        date: DateTime.now(),
      );
      final newHistory = [...goal.savingsHistory, contribution];
      final newSaved = goal.savedAmount + amount;
      final newStatus = newSaved >= goal.targetAmount
          ? GoalStatus.achieved
          : goal.requiredDailyAmount > (goal.remaining / 1)
          ? GoalStatus.behind
          : GoalStatus.onTrack;
      _localDataSource.updateGoal(
        goal.copyWith(
          savedAmount: newSaved,
          status: newStatus,
          savingsHistory: newHistory,
        ),
      );
    }
    try {
      await _remoteDataSource.contributeToGoal(goalId, amount);
      return Result.success(null);
    } on Exception catch (e) {
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<void>> removeContribution(
    String goalId,
    String contributionId,
    double amount,
  ) async {
    final goal = _localDataSource.getGoal(goalId);
    if (goal != null) {
      final newAmt = (goal.savedAmount - amount) < 0
          ? 0.0
          : (goal.savedAmount - amount);
      final newHistory = goal.savingsHistory
          .where((c) => c.id != contributionId)
          .toList();
      final newStatus = newAmt >= goal.targetAmount
          ? GoalStatus.achieved
          : newAmt > 0 && goal.requiredDailyAmount > (goal.remaining / 1)
          ? GoalStatus.behind
          : GoalStatus.onTrack;
      _localDataSource.updateGoal(
        goal.copyWith(
          savedAmount: newAmt,
          status: newStatus,
          savingsHistory: newHistory,
        ),
      );
    }
    try {
      await _remoteDataSource.removeContribution(
        goalId,
        contributionId,
        amount,
      );
      return Result.success(null);
    } on Exception catch (e) {
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<void>> editContribution(
    String goalId,
    String contributionId,
    double oldAmount,
    double newAmount, {
    DateTime? newDate,
  }) async {
    final goal = _localDataSource.getGoal(goalId);
    if (goal != null) {
      final newSaved = (goal.savedAmount - oldAmount + newAmount).clamp(
        0.0,
        double.infinity,
      );
      final newHistory = goal.savingsHistory.map((c) {
        if (c.id == contributionId) {
          return SavingsContribution(
            id: c.id,
            amount: newAmount,
            date: newDate ?? c.date,
          );
        }
        return c;
      }).toList();
      final newStatus = newSaved >= goal.targetAmount
          ? GoalStatus.achieved
          : newSaved > 0 && goal.requiredDailyAmount > (goal.remaining / 1)
          ? GoalStatus.behind
          : GoalStatus.onTrack;
      _localDataSource.updateGoal(
        goal.copyWith(
          savedAmount: newSaved,
          status: newStatus,
          savingsHistory: newHistory,
        ),
      );
    }
    try {
      await _remoteDataSource.editContribution(
        goalId,
        contributionId,
        oldAmount,
        newAmount,
        newDate: newDate,
      );
      return Result.success(null);
    } on Exception catch (e) {
      return Result.failure(e.toString());
    }
  }

  // ── Local Operations ──

  @override
  List<Goal> getLocalGoals() => _localDataSource.getAllGoals();

  @override
  void saveLocalGoal(Goal goal, {bool fromFirestore = false}) {
    _localDataSource.saveGoal(goal, fromFirestore: fromFirestore);
  }

  @override
  void saveAllLocalGoals(List<Goal> goals) {
    _localDataSource.saveAllGoals(goals);
  }

  @override
  void updateLocalGoal(Goal goal, {bool fromFirestore = false}) {
    _localDataSource.updateGoal(goal, fromFirestore: fromFirestore);
  }

  @override
  void deleteLocalGoal(String id) {
    _localDataSource.deleteGoal(id);
  }

  @override
  void markLocalSynced(String id) {
    _localDataSource.markAsSynced(id, 'goal');
  }
}
