part of 'goals_imports.dart';

class AddSavingsBottomSheet extends StatefulWidget {
  final Goal goal;

  const AddSavingsBottomSheet({super.key, required this.goal});

  static void show(BuildContext context, Goal goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      sheetAnimationStyle: appSheetAnimationStyle,
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
      padding: EdgeInsets.fromLTRB(22, 14, 22, 24 + keyboardHeight),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header Row
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.mint.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    widget.goal.emoji,
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
                      'Add to ${widget.goal.name}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Remaining: ${CurrencyHelper.symbol}${CurrencyHelper.format(remaining)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 32,
                onPressed: () => Navigator.pop(context),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.xmark,
                    size: 14,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Amount Input Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.outlineVariant, width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DEPOSIT AMOUNT',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      CurrencyHelper.currency,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
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
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Quick Amount Pills
          Text(
            'QUICK AMOUNTS',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickAmounts.map((amount) {
              final isSelected =
                  _controller.text == amount.toString() && _isQuickAmount;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _controller.text = amount.toString();
                    _isQuickAmount = true;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.outlineVariant,
                      width: 1,
                    ),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Text(
                    '+${CurrencyHelper.symbol}${amount.toString()}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : AppTheme.onSurface,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),

          // Progress Preview
          if (_controller.text.isNotEmpty) ...[
            _buildProgressPreview(),
            const SizedBox(height: 18),
          ],

          // Confirm Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: CupertinoButton(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(24),
              padding: EdgeInsets.zero,
              onPressed: _addSavings,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    CupertinoIcons.plus_circle,
                    size: 18,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Confirm Contribution',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isGoalAchieved
            ? AppTheme.mint.withValues(alpha: 0.2)
            : AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGoalAchieved ? AppTheme.primary : AppTheme.outlineVariant,
          width: 0.8,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Updated Progress',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              if (isGoalAchieved)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'GOAL ACHIEVED!',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: newProgress,
              minHeight: 6,
              backgroundColor: Colors.white,
              valueColor: AlwaysStoppedAnimation(
                isGoalAchieved ? AppTheme.primary : AppTheme.mintAccent,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${CurrencyHelper.symbol}${CurrencyHelper.format(newSavedAmount)} / ${CurrencyHelper.symbol}${CurrencyHelper.format(widget.goal.targetAmount)}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurface,
                ),
              ),
              Text(
                '${(newProgress * 100).toStringAsFixed(1)}%',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _addSavings() {
    HapticFeedback.lightImpact();
    final inputAmount = double.tryParse(_controller.text);
    if (inputAmount == null || inputAmount <= 0) {
      return;
    }

    final storedAmount = CurrencyHelper.convertToStored(inputAmount);
    context.read<GoalBloc>().add(
      GoalContributeRequested(goalId: widget.goal.id, amount: storedAmount),
    );

    Navigator.pop(context);

    final newSavedAmount = widget.goal.savedAmount + storedAmount;
    if (newSavedAmount >= widget.goal.targetAmount) {
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (_) => GoalAchievedScreen(
            goal: widget.goal.copyWith(
              savedAmount: newSavedAmount,
              status: GoalStatus.achieved,
            ),
          ),
        ),
      );
    }
  }
}
