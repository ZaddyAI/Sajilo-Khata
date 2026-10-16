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
      GoalStatus.onTrack => AppTheme.primary,
      GoalStatus.behind => AppTheme.expense,
      GoalStatus.achieved => AppTheme.income,
    };

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.background.withValues(alpha: 0.88),
                border: const Border(
                  bottom: BorderSide(color: Color(0x12000000), width: 0.5),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.pop(context),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              CupertinoIcons.back,
                              size: 22,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'Goals',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => _editGoal(context),
                        child: Text(
                          'Edit',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Squircle Hero Emoji Badge
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.mint,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      goal.emoji,
                      style: const TextStyle(fontSize: 36),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  goal.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.onSurface,
                    letterSpacing: -0.4,
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
                    color: goal.status == GoalStatus.behind
                        ? AppTheme.tertiaryContainer
                        : AppTheme.mint,
                    borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        goal.status == GoalStatus.behind
                            ? CupertinoIcons.exclamationmark_circle
                            : CupertinoIcons.checkmark_circle,
                        size: 13,
                        color: goal.status == GoalStatus.behind
                            ? AppTheme.expense
                            : AppTheme.primaryDark,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        goal.status == GoalStatus.achieved
                            ? 'ACHIEVED'
                            : goal.status == GoalStatus.behind
                            ? 'OFF TRACK'
                            : 'ON TRACK',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: goal.status == GoalStatus.behind
                              ? AppTheme.expense
                              : AppTheme.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Main Progress Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: AppTheme.iosCardDecoration,
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 170,
                            height: 170,
                            child: CircularProgressIndicator(
                              value: goal.progressPercent.clamp(0.0, 1.0),
                              strokeWidth: 10,
                              backgroundColor: AppTheme.surfaceContainerLow,
                              valueColor: AlwaysStoppedAnimation(statusColor),
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Column(
                            children: [
                              Text(
                                '${(goal.progressPercent * 100).toStringAsFixed(0)}%',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1.0,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                              Text(
                                'FUNDED',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: AppTheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Total Accumulated',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                          children: [
                            TextSpan(
                              text:
                                  '${CurrencyHelper.symbol}${CurrencyHelper.format(goal.savedAmount)}',
                              style: TextStyle(color: statusColor),
                            ),
                            TextSpan(
                              text: ' of ',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.onSurfaceVariant,
                              ),
                            ),
                            TextSpan(
                              text:
                                  '${CurrencyHelper.symbol}${CurrencyHelper.format(goal.targetAmount)}',
                              style: const TextStyle(color: AppTheme.onSurface),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Financial Insight Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.mint,
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    border: Border.all(
                      color: AppTheme.mintAccent.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.lightbulb,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'FINANCIAL INSIGHT',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                                color: AppTheme.primaryDark,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              goal.status == GoalStatus.achieved
                                  ? 'Outstanding! You have reached your savings milestone.'
                                  : 'Save ${CurrencyHelper.symbol}${CurrencyHelper.format(goal.requiredDailyAmount)}/day to reach your goal by ${DateFormat('MMM yyyy').format(goal.deadlineAD)}.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                                color: AppTheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Contribution History
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Deposit History',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (goal.savingsHistory.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(
                            AppTheme.pillRadius,
                          ),
                        ),
                        child: Text(
                          '${goal.savingsHistory.length} ${goal.savingsHistory.length == 1 ? 'deposit' : 'deposits'}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (goal.savingsHistory.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 20,
                    ),
                    decoration: AppTheme.iosCardDecoration,
                    child: Column(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerLow,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.archivebox,
                            size: 20,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'No Deposits Yet',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Contributions saved towards this goal will appear here with the exact timestamp.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            height: 1.4,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...goal.savingsHistory.reversed.map(
                    (c) => _ContributionTile(
                      contribution: c,
                      onEdit: () => _showEditContributionDialog(context, c),
                      onDelete: () => _confirmRemoveContribution(context, c),
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.background.withValues(alpha: 0),
                    AppTheme.background,
                  ],
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _showContributeDialog(context);
                  },
                  icon: const Icon(CupertinoIcons.plus_circle, size: 18),
                  label: Text(
                    'Add Savings Deposit',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondary,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    elevation: 0,
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
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      CupertinoPageRoute(
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
    HapticFeedback.lightImpact();
    final bloc = context.read<GoalBloc>();
    showSmoothDialog(
      context: context,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: bloc,
          child: _EditContributionDialog(
            goal: goal,
            contribution: contribution,
          ),
        );
      },
    );
  }

  void _confirmRemoveContribution(
    BuildContext context,
    SavingsContribution contribution,
  ) {
    HapticFeedback.lightImpact();
    final bloc = context.read<GoalBloc>();
    showSmoothDialog(
      context: context,
      builder: (dialogContext) {
        return CupertinoAlertDialog(
          title: Text(
            'Delete Deposit',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Remove this ${CurrencyHelper.symbol}${CurrencyHelper.format(contribution.amount)} deposit recorded on ${DateFormat('MMM dd, yyyy • h:mm a').format(contribution.date)}?\n\nThis amount will be deducted from your total saved progress.',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.35),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                HapticFeedback.mediumImpact();
                bloc.add(
                  GoalRemoveContributionRequested(
                    goalId: goal.id,
                    contributionId: contribution.id,
                    amount: contribution.amount,
                  ),
                );
                Navigator.pop(dialogContext);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}

class _EditContributionDialog extends StatefulWidget {
  final Goal goal;
  final SavingsContribution contribution;

  const _EditContributionDialog({
    required this.goal,
    required this.contribution,
  });

  @override
  State<_EditContributionDialog> createState() =>
      _EditContributionDialogState();
}

class _EditContributionDialogState extends State<_EditContributionDialog> {
  late final TextEditingController _controller;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final displayAmount = CurrencyHelper.convertFromStored(
      widget.contribution.amount,
    );
    final isWhole = displayAmount.truncateToDouble() == displayAmount;
    _controller = TextEditingController(
      text: isWhole
          ? displayAmount.toInt().toString()
          : displayAmount.toStringAsFixed(2),
    );
    _selectedDate = widget.contribution.date;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _pickDateTime() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => Container(
        height: 280,
        padding: const EdgeInsets.only(top: 6),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                  Text(
                    'Select Date & Time',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  CupertinoButton(
                    child: const Text('Done'),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.dateAndTime,
                  initialDateTime: _selectedDate,
                  maximumDate: DateTime.now().add(const Duration(minutes: 5)),
                  onDateTimeChanged: (newDate) {
                    setState(() {
                      _selectedDate = newDate;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    final clean = _controller.text.replaceAll(',', '').trim();
    final inputVal = double.tryParse(clean);
    if (inputVal != null && inputVal > 0) {
      final storedAmount = CurrencyHelper.convertToStored(inputVal);
      context.read<GoalBloc>().add(
        GoalEditContributionRequested(
          goalId: widget.goal.id,
          contributionId: widget.contribution.id,
          oldAmount: widget.contribution.amount,
          newAmount: storedAmount,
          newDate: _selectedDate,
        ),
      );
      HapticFeedback.mediumImpact();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Text(
        'Edit Deposit',
        style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          fontSize: 17,
        ),
      ),
      content: Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Input
            CupertinoTextField(
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
              prefix: Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Text(
                  CurrencyHelper.symbol,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryDark,
                  ),
                ),
              ),
              placeholder: 'Amount (${CurrencyHelper.currency})',
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.outlineVariant, width: 0.8),
              ),
              style: GoogleFonts.jetBrainsMono(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),

            // Time Selector
            GestureDetector(
              onTap: _pickDateTime,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.outlineVariant,
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.clock,
                      size: 14,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        DateFormat(
                          'MMM dd, yyyy • h:mm a',
                        ).format(_selectedDate),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurface,
                        ),
                      ),
                    ),
                    const Icon(
                      CupertinoIcons.chevron_right,
                      size: 12,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
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

  void _showOptions(BuildContext context) {
    HapticFeedback.lightImpact();
    showCupertinoModalPopup<void>(
      context: context,
      builder: (actionSheetContext) {
        return CupertinoActionSheet(
          title: Text(
            'Deposit: +${CurrencyHelper.symbol}${CurrencyHelper.format(contribution.amount)}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurface,
            ),
          ),
          message: Text(
            DateFormat(
              'EEEE, MMMM dd, yyyy • h:mm a',
            ).format(contribution.date),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(actionSheetContext);
                onEdit();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(CupertinoIcons.pencil, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Edit Deposit',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(actionSheetContext);
                onDelete();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(CupertinoIcons.trash, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Delete Deposit',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(actionSheetContext),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDateTime = DateFormat(
      'MMM dd, yyyy • h:mm a',
    ).format(contribution.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: AppTheme.iosCardDecoration,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showOptions(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.mint,
                    borderRadius: BorderRadius.circular(
                      AppTheme.squircleRadius,
                    ),
                  ),
                  child: const Icon(
                    CupertinoIcons.arrow_down_to_line_alt,
                    size: 17,
                    color: AppTheme.primaryDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Savings Deposit',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.clock,
                            size: 11,
                            color: AppTheme.onSurfaceVariant.withValues(
                              alpha: 0.75,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              formattedDateTime,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '+${CurrencyHelper.symbol}${CurrencyHelper.format(contribution.amount)}',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.income,
                  ),
                ),
                const SizedBox(width: 2),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 32,
                  onPressed: () => _showOptions(context),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLow,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.ellipsis,
                      size: 13,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
