import '../../domain/entities/goal.dart';

class GoalModel {
  static Goal fromMap(Map<String, dynamic> map, String id) {
    final historyList =
        (map['savingsHistory'] as List<dynamic>?)
            ?.map(
              (e) => SavingsContribution(
                id: e['id']?.toString() ?? '',
                amount: (e['amount'] as num?)?.toDouble() ?? 0,
                date:
                    DateTime.tryParse(e['date']?.toString() ?? '') ??
                    DateTime.now(),
              ),
            )
            .toList() ??
        [];

    return Goal(
      id: id,
      name: map['name']?.toString() ?? '',
      emoji: map['emoji']?.toString() ?? '🎯',
      targetAmount: (map['targetAmount'] as num?)?.toDouble() ?? 0,
      savedAmount: (map['savedAmount'] as num?)?.toDouble() ?? 0,
      deadlineAD:
          DateTime.tryParse(map['deadlineAD']?.toString() ?? '') ??
          DateTime.now(),
      deadlineBS: map['deadlineBS']?.toString() ?? '',
      status: _parseStatus(map['status']?.toString()),
      createdAt:
          DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
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

  static Map<String, dynamic> toMap(Goal goal) => {
    'name': goal.name,
    'emoji': goal.emoji,
    'targetAmount': goal.targetAmount,
    'savedAmount': goal.savedAmount,
    'deadlineAD': goal.deadlineAD.toIso8601String(),
    'deadlineBS': goal.deadlineBS,
    'status': goal.status == GoalStatus.achieved
        ? 'achieved'
        : goal.status == GoalStatus.behind
        ? 'behind'
        : 'on_track',
    'createdAt': goal.createdAt.toIso8601String(),
    'savingsHistory': goal.savingsHistory
        .map(
          (e) => {
            'id': e.id,
            'amount': e.amount,
            'date': e.date.toIso8601String(),
          },
        )
        .toList(),
  };
}
