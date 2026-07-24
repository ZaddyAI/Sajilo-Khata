import 'dart:async';
import '../../entities/goal.dart';
import '../../repositories/i_goal_repository.dart';

class GetGoals {
  final GoalRepository _repository;
  GetGoals(this._repository);

  List<Goal> getLocal() => _repository.getLocalGoals();

  Stream<List<Goal>> observe() => _repository.getGoalsStream();

  Future<List<Goal>> fetchAll() => _repository.fetchAllGoals();
}
