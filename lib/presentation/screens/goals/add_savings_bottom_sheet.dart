part of 'goals_imports.dart';

class AddSavingsBottomSheet extends StatefulWidget {
  final Goal goal;

  const AddSavingsBottomSheet({super.key, required this.goal});

  static void show(BuildContext context, Goal goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddSavingsBottomSheet(goal: goal),
    );
  }

  @override
  State<AddSavingsBottomSheet> createState() => _AddSavingsBottomSheetState();
}

class _AddSavingsBottomSheetState extends State<AddSavingsBottomSheet> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isQuickAmount = false;

  static const _quickAmounts = [100, 500, 1000, 5000, 10000];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.goal.remaining;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + keyboardHeight),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Savings',
                    style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Remaining: ${CurrencyHelper.symbol}${CurrencyHelper.format(remaining)}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 14,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
                color: AppTheme.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Amount Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AMOUNT',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.05,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 4, right: 8),
                      child: Text(
                        CurrencyHelper.currency,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 0,
                      minHeight: 0,
                    ),
                    border: InputBorder.none,
                    hintText: '0',
                    hintStyle: GoogleFonts.jetBrainsMono(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.outlineVariant,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _isQuickAmount = false;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Quick Amount Chips
          Text(
            'QUICK AMOUNTS',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.05,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickAmounts.map((amount) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _controller.text = amount.toString();
                    _isQuickAmount = true;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color:
                        _controller.text == amount.toString() && _isQuickAmount
                        ? AppTheme.primary
                        : AppTheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color:
                          _controller.text == amount.toString() &&
                              _isQuickAmount
                          ? AppTheme.primary
                          : AppTheme.outlineVariant,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${CurrencyHelper.symbol}${amount.toString()}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color:
                          _controller.text == amount.toString() &&
                              _isQuickAmount
                          ? AppTheme.onPrimary
                          : AppTheme.onSurface,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Goal Progress Preview
          if (_controller.text.isNotEmpty) ...[
            _buildProgressPreview(),
            const SizedBox(height: 24),
          ],

          // Add Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _addSavings,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(
                'Add Savings',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressPreview() {
    final inputAmount = double.tryParse(_controller.text) ?? 0;
    final storedAmount = CurrencyHelper.convertToStored(inputAmount);
    final newSavedAmount = widget.goal.savedAmount + storedAmount;
    final newProgress = (newSavedAmount / widget.goal.targetAmount).clamp(
      0.0,
      1.0,
    );
    final isGoalAchieved = newSavedAmount >= widget.goal.targetAmount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isGoalAchieved
            ? AppTheme.secondaryContainer.withValues(alpha: 0.2)
            : AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isGoalAchieved ? AppTheme.secondary : AppTheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'New Progress',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              if (isGoalAchieved)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'GOAL ACHIEVED!',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSecondary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: newProgress,
              minHeight: 8,
              backgroundColor: AppTheme.surfaceContainerLowest,
              valueColor: AlwaysStoppedAnimation(
                isGoalAchieved ? AppTheme.secondary : AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${CurrencyHelper.symbol}${CurrencyHelper.format(newSavedAmount)}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurface,
                ),
              ),
              Text(
                '${(newProgress * 100).toStringAsFixed(1)}%',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isGoalAchieved ? AppTheme.secondary : AppTheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _addSavings() {
    final inputAmount = double.tryParse(_controller.text);
    if (inputAmount == null || inputAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a valid amount',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final storedAmount = CurrencyHelper.convertToStored(inputAmount);
    context.read<GoalBloc>().add(
      GoalContributeRequested(goalId: widget.goal.id, amount: storedAmount),
    );

    Navigator.pop(context);

    // Check if goal is achieved
    final newSavedAmount = widget.goal.savedAmount + storedAmount;
    if (newSavedAmount >= widget.goal.targetAmount) {
      // Navigate to goal achieved screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GoalAchievedScreen(
            goal: widget.goal.copyWith(
              savedAmount: newSavedAmount,
              status: GoalStatus.achieved,
            ),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Added ${CurrencyHelper.symbol}${CurrencyHelper.format(inputAmount)} to ${widget.goal.name}',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: AppTheme.secondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }
}
