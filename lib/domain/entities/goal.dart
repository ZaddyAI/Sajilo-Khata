enum GoalStatus { onTrack, behind, achieved }

class SavingsContribution {
  final String id;
  final double amount;
  final DateTime date;

  const SavingsContribution({
    required this.id,
    required this.amount,
    required this.date,
  });
}

class Goal {
  final String id;
  final String name;
  final String emoji;
  final double targetAmount;
  final double savedAmount;
  final DateTime deadlineAD;
  final String deadlineBS;
  final GoalStatus status;
  final DateTime createdAt;
  final List<SavingsContribution> savingsHistory;

  const Goal({
    required this.id,
    required this.name,
    required this.emoji,
    required this.targetAmount,
    required this.savedAmount,
    required this.deadlineAD,
    required this.deadlineBS,
    required this.status,
    required this.createdAt,
    this.savingsHistory = const [],
  });

  double get progressPercent => (savedAmount / targetAmount).clamp(0.0, 1.0);
  double get remaining => (targetAmount - savedAmount).clamp(0.0, double.infinity);

  double get requiredDailyAmount {
    final daysLeft = deadlineAD.difference(DateTime.now()).inDays;
    if (daysLeft <= 0 || remaining <= 0) return 0;
    return remaining / daysLeft;
  }

  Goal copyWith({
    double? savedAmount,
    GoalStatus? status,
    String? name,
    String? emoji,
    double? targetAmount,
    DateTime? deadlineAD,
    List<SavingsContribution>? savingsHistory,
  }) {
    return Goal(
      id: id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      deadlineAD: deadlineAD ?? this.deadlineAD,
      deadlineBS: deadlineBS,
      status: status ?? this.status,
      createdAt: createdAt,
      savingsHistory: savingsHistory ?? this.savingsHistory,
    );
  }
}