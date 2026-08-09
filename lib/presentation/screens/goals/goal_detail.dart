part of 'goals_imports.dart';

class GoalDetailScreen extends StatelessWidget {
  final Goal initialGoal;
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

  Goal _getUpdatedGoal(GoalState state, String goalId) {
    if (state is GoalLoaded) {
      final found = state.goals.where((g) => g.id == goalId).firstOrNull;
      if (found != null) return found;
    }
    return initialGoal;
  }
}

class _GoalDetailContent extends StatelessWidget {
  final Goal goal;
  const _GoalDetailContent({required this.goal});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (goal.status) {
      GoalStatus.onTrack => AppTheme.secondary,
      GoalStatus.behind => AppTheme.tertiary,
      GoalStatus.achieved => AppTheme.secondary,
    };

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppTheme.primary,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Sajilo Khata',
          style: GoogleFonts.manrope(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppTheme.primary,
          ),
        ),
        backgroundColor: AppTheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.outlineVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => _editGoal(context),
            child: Text(
              'Edit',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.05,
                color: AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerHigh,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.outlineVariant,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.onSurface.withValues(alpha: 0.03),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      goal.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  goal.name,
                  style: GoogleFonts.manrope(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: goal.status == GoalStatus.achieved
                        ? AppTheme.secondaryContainer
                        : goal.status == GoalStatus.behind
                        ? AppTheme.errorContainer
                        : AppTheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        goal.status == GoalStatus.behind
                            ? Icons.error
                            : Icons.check_circle,
                        size: 14,
                        color: goal.status == GoalStatus.achieved
                            ? AppTheme.onSecondaryContainer
                            : goal.status == GoalStatus.behind
                            ? AppTheme.onErrorContainer
                            : AppTheme.onSecondaryContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        goal.status == GoalStatus.achieved
                            ? 'ACHIEVED'
                            : goal.status == GoalStatus.behind
                            ? 'OFF TRACK'
                            : 'ON TRACK',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.05,
                          color: goal.status == GoalStatus.achieved
                              ? AppTheme.onSecondaryContainer
                              : goal.status == GoalStatus.behind
                              ? AppTheme.onErrorContainer
                              : AppTheme.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.outlineVariant,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 192,
                            height: 192,
                            child: CircularProgressIndicator(
                              value: goal.progressPercent,
                              strokeWidth: 12,
                              backgroundColor: AppTheme.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation(statusColor),
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Column(
                            children: [
                              Text(
                                '${(goal.progressPercent * 100).toStringAsFixed(0)}%',
                                style: GoogleFonts.manrope(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primary,
                                ),
                              ),
                              Text(
                                'SAVED',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.1,
                                  color: AppTheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Current Progress',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                          ),
                          children: [
                            TextSpan(
                              text:
                                  '${CurrencyHelper.symbol}${CurrencyHelper.format(goal.savedAmount)}',
                              style: const TextStyle(color: AppTheme.primary),
                            ),
                            TextSpan(
                              text: ' of ',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: AppTheme.onSurfaceVariant,
                              ),
                            ),
                            TextSpan(
                              text:
                                  '${CurrencyHelper.symbol}${CurrencyHelper.format(goal.targetAmount)}',
                              style: const TextStyle(color: AppTheme.outline),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.tertiaryFixed,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.outlineVariant,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: AppTheme.onTertiaryFixed,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.trending_up,
                          color: AppTheme.tertiaryFixed,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Growth Insight',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.05,
                                color: AppTheme.onTertiaryFixedVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              goal.status == GoalStatus.achieved
                                  ? 'Congratulations! You reached your goal.'
                                  : 'Save ${CurrencyHelper.symbol}${CurrencyHelper.format(goal.requiredDailyAmount)}/day to reach your goal by ${DateFormat('MMM yyyy').format(goal.deadlineAD)}.',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: AppTheme.onTertiaryFixed,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                if (goal.savingsHistory.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Contribution History',
                        style: GoogleFonts.manrope(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                      Icon(Icons.history, color: AppTheme.outline),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...goal.savingsHistory.reversed.map(
                    (c) => _ContributionTile(
                      contribution: c,
                      onEdit: () => _showEditContributionDialog(context, c),
                      onDelete: () => _confirmRemoveContribution(context, c),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.expand_more, size: 20),
                      label: Text(
                        'View All Transactions',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.05,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          width: 2,
                          color: AppTheme.outlineVariant,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.surface.withValues(alpha: 0),
                    AppTheme.background,
                  ],
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () => _showContributeDialog(context),
                  icon: const Icon(Icons.add_circle, size: 18),
                  label: Text(
                    'Add Savings',
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: AppTheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showContributeDialog(BuildContext context) {
    AddSavingsBottomSheet.show(context, goal);
  }

  void _editGoal(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<GoalBloc>(),
          child: EditGoalScreen(goal: goal),
        ),
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

class _ContributionTile extends StatelessWidget {
  final SavingsContribution contribution;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ContributionTile({
    required this.contribution,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMMM');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.outlineVariant, width: 1),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 4,
              decoration: const BoxDecoration(color: AppTheme.secondary),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dateFormat.format(contribution.date),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.05,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Manual Deposit',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: AppTheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '+${CurrencyHelper.symbol}${CurrencyHelper.format(contribution.amount)}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
