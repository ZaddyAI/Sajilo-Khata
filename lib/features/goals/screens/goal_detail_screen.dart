import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_theme.dart'
    show getCurrencyIcon, CurrencyHelper, AppTheme;
import '../../../core/models/goal_model.dart';
import '../bloc/goal_bloc.dart';
import '../bloc/goal_event.dart';
import '../bloc/goal_state.dart';
import 'add_goal_screen.dart';

class GoalDetailScreen extends StatelessWidget {
  final GoalModel initialGoal;
  const GoalDetailScreen({super.key, required this.initialGoal});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GoalBloc, GoalState>(
      builder: (context, state) {
        final goal = _getUpdatedGoal(state, initialGoal.id);
        return _GoalDetailContent(goal: goal);
      },
    );
  }

  GoalModel _getUpdatedGoal(GoalState state, String goalId) {
    if (state is GoalLoaded) {
      final found = state.goals.where((g) => g.id == goalId).firstOrNull;
      if (found != null) return found;
    }
    return initialGoal;
  }
}

class _GoalDetailContent extends StatelessWidget {
  final GoalModel goal;
  const _GoalDetailContent({required this.goal});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMMM dd, yyyy');
    final daysLeft = goal.deadlineAD.difference(DateTime.now()).inDays;

    final statusColor = switch (goal.status) {
      GoalStatus.onTrack => AppTheme.primary,
      GoalStatus.behind => AppTheme.error,
      GoalStatus.achieved => AppTheme.secondary,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(goal.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () => _editGoal(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Delete',
            color: AppTheme.error,
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(goal.emoji, style: const TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              goal.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                goal.status == GoalStatus.achieved
                    ? 'Achieved!'
                    : goal.status == GoalStatus.behind
                    ? 'Behind Schedule'
                    : 'On Track',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ),
            const SizedBox(height: 36),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: goal.progressPercent,
                    strokeWidth: 12,
                    backgroundColor: const Color(0xFFECEFED),
                    valueColor: AlwaysStoppedAnimation(statusColor),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '${(goal.progressPercent * 100).toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'complete',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.cardShadow,
                border: Border.all(color: const Color(0xFFF0F2F1), width: 1),
              ),
              child: Column(
                children: [
                  _summaryRow(
                    context,
                    'Saved',
                    '${CurrencyHelper.symbol}${CurrencyHelper.format(goal.savedAmount)}',
                    Icons.savings,
                    AppTheme.primary,
                  ),
                  const SizedBox(height: 16),
                  _summaryRow(
                    context,
                    'Target',
                    '${CurrencyHelper.symbol}${CurrencyHelper.format(goal.targetAmount)}',
                    Icons.flag,
                    AppTheme.secondary,
                  ),
                  const SizedBox(height: 16),
                  _summaryRow(
                    context,
                    'Remaining',
                    '${CurrencyHelper.symbol}${CurrencyHelper.format(goal.remaining)}',
                    Icons.hourglass_empty,
                    AppTheme.outline,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.cardShadow,
                border: Border.all(color: const Color(0xFFF0F2F1), width: 1),
              ),
              child: Column(
                children: [
                  _summaryRow(
                    context,
                    'Target Date',
                    dateFormat.format(goal.deadlineAD),
                    Icons.calendar_today,
                    AppTheme.primaryContainer,
                  ),
                  const SizedBox(height: 16),
                  _summaryRow(
                    context,
                    'Days Left',
                    daysLeft > 0 ? '$daysLeft days' : 'Deadline passed',
                    Icons.timer,
                    AppTheme.onSurfaceVariant,
                  ),
                  if (goal.status != GoalStatus.achieved && daysLeft > 0) ...[
                    const SizedBox(height: 16),
                    _summaryRow(
                      context,
                      'Save Per Day',
                      '${CurrencyHelper.symbol}${CurrencyHelper.format(goal.requiredDailyAmount)}',
                      Icons.trending_up,
                      AppTheme.secondaryContainer,
                    ),
                  ],
                ],
              ),
            ),
            if (goal.savingsHistory.isNotEmpty) ...[
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.history_rounded,
                        color: AppTheme.primary,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Savings History',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              ...goal.savingsHistory.reversed.map(
                (c) => _contributionTile(
                  context,
                  c,
                  () => _showEditContributionDialog(context, c),
                  () => _confirmRemoveContribution(context, c),
                ),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _showContributeDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: AppTheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Add Savings'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  void _showContributeDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Savings'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Amount (${CurrencyHelper.currency})',
              prefixIcon: Icon(getCurrencyIcon(CurrencyHelper.currency)),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final inputAmount = double.tryParse(controller.text);
                if (inputAmount != null && inputAmount > 0) {
                  final storedAmount = CurrencyHelper.convertToStored(
                    inputAmount,
                  );
                  context.read<GoalBloc>().add(
                    GoalContributeRequested(
                      goalId: goal.id,
                      amount: storedAmount,
                    ),
                  );
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Goal'),
          content: Text('Are you sure you want to delete "${goal.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                context.read<GoalBloc>().add(GoalDeleteRequested(id: goal.id));
                Navigator.pop(dialogContext);
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(foregroundColor: AppTheme.error),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _editGoal(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<GoalBloc>(),
          child: AddGoalScreen(goal: goal),
        ),
      ),
    );
  }

  Widget _contributionTile(
    BuildContext context,
    SavingsContribution contribution,
    VoidCallback onEdit,
    VoidCallback onDelete,
  ) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: const Color(0xFFF0F2F1), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.savings, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${CurrencyHelper.symbol}${CurrencyHelper.format(contribution.amount)}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  dateFormat.format(contribution.date),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: onEdit,
            color: AppTheme.onSurfaceVariant,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            onPressed: onDelete,
            color: AppTheme.error,
          ),
        ],
      ),
    );
  }

  void _showEditContributionDialog(
    BuildContext context,
    SavingsContribution contribution,
  ) {
    final controller = TextEditingController(
      text: CurrencyHelper.format(contribution.amount),
    );
    final bloc = context.read<GoalBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Savings'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Amount (${CurrencyHelper.currency})',
              prefixIcon: Icon(getCurrencyIcon(CurrencyHelper.currency)),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newAmount = double.tryParse(controller.text);
                if (newAmount != null && newAmount > 0) {
                  bloc.add(
                    GoalEditContributionRequested(
                      goalId: goal.id,
                      contributionId: contribution.id,
                      oldAmount: contribution.amount,
                      newAmount: newAmount,
                    ),
                  );
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _confirmRemoveContribution(
    BuildContext context,
    SavingsContribution contribution,
  ) {
    final bloc = context.read<GoalBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remove Savings'),
          content: Text(
            'Are you sure you want to remove this ${CurrencyHelper.symbol}${CurrencyHelper.format(contribution.amount)}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                bloc.add(
                  GoalRemoveContributionRequested(
                    goalId: goal.id,
                    contributionId: contribution.id,
                    amount: contribution.amount,
                  ),
                );
                Navigator.pop(dialogContext);
              },
              style: TextButton.styleFrom(foregroundColor: AppTheme.error),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }
}
