import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/goal_model.dart';
import '../../../core/constants/app_theme.dart';
import '../bloc/goal_bloc.dart';
import '../bloc/goal_state.dart';
import 'add_goal_screen.dart';
import 'goal_detail_screen.dart';

class GoalsListScreen extends StatelessWidget {
  const GoalsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Savings Goals')),
      body: BlocBuilder<GoalBloc, GoalState>(
        builder: (context, state) {
          if (state is GoalLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          if (state is GoalLoaded) {
            if (state.goals.isEmpty) {
              return _buildEmpty(context);
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: [
                if (state.activeGoals.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12),
                    child: Text(
                      'Active Goals',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  ...state.activeGoals.map(
                    (goal) => _GoalCard(
                      goal: goal,
                      onTap: () => _openGoalDetail(context, goal),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                if (state.achievedGoals.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.emoji_events_rounded,
                          size: 18,
                          color: AppColors.achieved,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Achieved',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  ...state.achievedGoals.map(
                    (goal) => _GoalCard(
                      goal: goal,
                      onTap: () => _openGoalDetail(context, goal),
                    ),
                  ),
                ],
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton.extended(
          heroTag: 'goal_fab',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<GoalBloc>(),
                child: const AddGoalScreen(),
              ),
            ),
          ),
          icon: const Icon(Icons.add_rounded),
          label: const Text('New Goal'),
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFECEFED),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.savings_outlined,
                size: 36,
                color: AppTheme.outlineVariant,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No savings goals yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Set a goal and start building\nyour financial future',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _openGoalDetail(BuildContext context, GoalModel goal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<GoalBloc>(),
          child: GoalDetailScreen(initialGoal: goal),
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final GoalModel goal;
  final VoidCallback? onTap;

  const _GoalCard({required this.goal, this.onTap});

  @override
  Widget build(BuildContext context) {
    final daysLeft = goal.deadlineAD.difference(DateTime.now()).inDays;
    final statusColor = switch (goal.status) {
      GoalStatus.onTrack => AppTheme.primary,
      GoalStatus.behind => AppTheme.error,
      GoalStatus.achieved => AppTheme.secondary,
    };
    final statusLabel = switch (goal.status) {
      GoalStatus.onTrack => 'On Track',
      GoalStatus.behind => 'Behind',
      GoalStatus.achieved => 'Achieved',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: const Color(0xFFF0F2F1), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Center(
                        child: Text(
                          goal.emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.name,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${CurrencyHelper.symbol}${CurrencyHelper.format(goal.savedAmount)} / ${CurrencyHelper.symbol}${CurrencyHelper.format(goal.targetAmount)}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppTheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusLabel,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: goal.progressPercent,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFECEFED),
                    valueColor: AlwaysStoppedAnimation(statusColor),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(goal.progressPercent * 100).toStringAsFixed(0)}% complete',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    if (goal.status != GoalStatus.achieved && daysLeft > 0)
                      Text(
                        '$daysLeft days left \u00B7 ${CurrencyHelper.symbol}${CurrencyHelper.format(goal.requiredDailyAmount)}/day',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
