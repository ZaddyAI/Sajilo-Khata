import 'dart:async';
import '../../../core/error/result.dart';
import '../../../domain/entities/goal.dart';
import '../../../domain/repositories/i_goal_repository.dart';
import '../datasources/remote/firebase_firestore_datasource.dart';
import '../datasources/local/hive_datasource.dart';

class GoalRepositoryImpl implements GoalRepository {
  final FirebaseFirestoreDataSource _remoteDataSource;
  final HiveDataSource _localDataSource;

  GoalRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
  );

  @override
  Future<Result<void>> addGoal(Goal goal) async {
    try {
      await _remoteDataSource.addGoal(goal);
      return Result.success(null);
    } on Exception catch (e) {
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<void>> deleteGoal(String id) async {
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
    try {
      await _remoteDataSource.updateGoal(goal);
      return Result.success(null);
    } on Exception catch (e) {
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<void>> contributeToGoal(String goalId, double amount) async {
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
    double newAmount,
  ) async {
    try {
      await _remoteDataSource.editContribution(
        goalId,
        contributionId,
        oldAmount,
        newAmount,
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
