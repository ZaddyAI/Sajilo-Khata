enum GoalStatus { onTrack, behind, achieved }

class SavingsContribution {
  final String id;
  final double amount;
  final DateTime date;

  SavingsContribution({
    required this.id,
    required this.amount,
    required this.date,
  });

  factory SavingsContribution.fromMap(Map<String, dynamic> map, String id) {
    return SavingsContribution(
      id: id,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date']),
    );
  }

  Map<String, dynamic> toMap() => {
    'amount': amount,
    'date': date.toIso8601String(),
  };
}

class GoalModel {
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

  GoalModel({
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
  double get remaining =>
      (targetAmount - savedAmount).clamp(0.0, double.infinity);

  /// How much to save per day to hit the deadline
  double get requiredDailyAmount {
    final daysLeft = deadlineAD.difference(DateTime.now()).inDays;
    if (daysLeft <= 0 || remaining <= 0) return 0;
    return remaining / daysLeft;
  }

  factory GoalModel.fromMap(Map<String, dynamic> map, String id) {
    final historyList = (map['savingsHistory'] as List<dynamic>?)
        ?.map((e) => SavingsContribution.fromMap(e as Map<String, dynamic>, e['id'] ?? ''))
        .toList() ?? [];
    return GoalModel(
      id: id,
      name: map['name'],
      emoji: map['emoji'] ?? '🎯',
      targetAmount: (map['targetAmount'] as num).toDouble(),
      savedAmount: (map['savedAmount'] as num).toDouble(),
      deadlineAD: DateTime.parse(map['deadlineAD']),
      deadlineBS: map['deadlineBS'] ?? '',
      status: _parseStatus(map['status']),
      createdAt: DateTime.parse(map['createdAt']),
      savingsHistory: historyList,
    );
  }

  static GoalStatus _parseStatus(String? s) {
    switch (s) {
      case 'achieved':
        return GoalStatus.achieved;
      case 'behind':
        return GoalStatus.behind;
      default:
        return GoalStatus.onTrack;
    }
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'emoji': emoji,
    'targetAmount': targetAmount,
    'savedAmount': savedAmount,
    'deadlineAD': deadlineAD.toIso8601String(),
    'deadlineBS': deadlineBS,
    'status': status == GoalStatus.achieved
        ? 'achieved'
        : status == GoalStatus.behind
        ? 'behind'
        : 'on_track',
    'createdAt': createdAt.toIso8601String(),
    'savingsHistory': savingsHistory.map((e) => e.toMap()).toList(),
  };

  GoalModel copyWith({
    double? savedAmount,
    GoalStatus? status,
    String? name,
    String? emoji,
    double? targetAmount,
    DateTime? deadlineAD,
    List<SavingsContribution>? savingsHistory,
  }) {
    return GoalModel(
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
