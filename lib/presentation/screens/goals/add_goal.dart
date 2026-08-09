part of 'goals_imports.dart';

class AddGoalScreen extends StatefulWidget {
  final Goal? goal;

  const AddGoalScreen({super.key, this.goal});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  late DateTime _deadline;
  String _emoji = '\u{1F3AF}';
  bool _isBS = false;

  @override
  void initState() {
    super.initState();
    if (widget.goal != null) {
      _nameController.text = widget.goal!.name;
      final displayAmount = CurrencyHelper.convertFromStored(
        widget.goal!.targetAmount,
      );
      _amountController.text = displayAmount > 0
          ? displayAmount.toStringAsFixed(0)
          : '';
      _deadline = widget.goal!.deadlineAD;
      _emoji = widget.goal!.emoji;
    } else {
      _deadline = DateTime.now().add(const Duration(days: 90));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.goal != null;
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppTheme.onSurface,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? 'Edit Goal' : 'Add Goal',
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.primary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.outlineVariant),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              _buildIconSelector(),
              const SizedBox(height: 32),
              _buildTextField(
                label: 'GOAL NAME',
                controller: _nameController,
                icon: Icons.flag_outlined,
                hintText: 'e.g., New Laptop',
              ),
              const SizedBox(height: 20),
              _buildAmountField(),
              const SizedBox(height: 20),
              _buildDatePicker(),
              const SizedBox(height: 24),
              _buildGrowthTipCard(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomSheet: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.outlineVariant, width: 1)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _saveGoal,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: AppTheme.onPrimary,
              elevation: 4,
              shadowColor: AppTheme.primary.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            icon: const Icon(Icons.add_task, size: 22),
            label: Text(
              isEditing ? 'Update Goal' : 'CREATE GOAL',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.05,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconSelector() {
    return Column(
      children: [
        GestureDetector(
          onTap: _showEmojiPicker,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHigh,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.outlineVariant,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Center(
                  child: Text(_emoji, style: const TextStyle(fontSize: 48)),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit,
                    size: 16,
                    color: AppTheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Tap icon to choose or type your own emoji',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _QuickEmojiButton(
              emoji: '\u{1F3E0}',
              onTap: () => setState(() => _emoji = '\u{1F3E0}'),
            ),
            const SizedBox(width: 8),
            _QuickEmojiButton(
              emoji: '\u{1F697}',
              onTap: () => setState(() => _emoji = '\u{1F697}'),
            ),
            const SizedBox(width: 8),
            _QuickEmojiButton(
              emoji: '\u{2708}\u{FE0F}',
              onTap: () => setState(() => _emoji = '\u{2708}\u{FE0F}'),
            ),
            const SizedBox(width: 8),
            _QuickEmojiButton(
              emoji: '\u{1F393}',
              onTap: () => setState(() => _emoji = '\u{1F393}'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'SELECT GOAL ICON',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  void _showEmojiPicker() {
    final emojiController = TextEditingController(text: _emoji);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose Goal Icon',
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Type any emoji from your keyboard or pick one below',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.outlineVariant, width: 1),
                  ),
                  child: TextField(
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 48),
                    controller: emojiController,
                    decoration: InputDecoration(
                      hintText: '\u{1F3AF}',
                      hintStyle: const TextStyle(fontSize: 48),
                      counterText: '',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        setSheetState(() {});
                        setState(() => _emoji = value.characters.last);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Quick picks',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    '\u{1F3AF}', '\u{1F4BB}', '\u{1F4F1}', '\u{1F3E0}',
                    '\u{1F697}', '\u{2708}\u{FE0F}', '\u{1F48D}', '\u{1F393}',
                    '\u{1F3E5}', '\u{1F381}', '\u{1F4B0}', '\u{1F3D7}\u{FE0F}',
                    '\u{1F6B2}', '\u{1F3A8}', '\u{1F3C6}', '\u{2B50}',
                    '\u{1F4DA}', '\u{1F6CD}\u{FE0F}', '\u{1F3E6}', '\u{1F4B3}',
                  ].map((emoji) => GestureDetector(
                    onTap: () {
                      setState(() => _emoji = emoji);
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _emoji == emoji
                            ? AppTheme.primary.withValues(alpha: 0.1)
                            : AppTheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _emoji == emoji
                              ? AppTheme.primary
                              : AppTheme.outlineVariant,
                          width: _emoji == emoji ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(emoji, style: const TextStyle(fontSize: 22)),
                      ),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.05,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.outlineVariant, width: 1),
          ),
          child: TextFormField(
            controller: controller,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: GoogleFonts.inter(
                fontSize: 16,
                color: AppTheme.outline,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            style: GoogleFonts.inter(fontSize: 16, color: AppTheme.onSurface),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a name';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TARGET AMOUNT',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.05,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.outlineVariant, width: 1),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Positioned(
                left: 16,
                child: Text(
                  'NPR',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primary,
                ),
                decoration: InputDecoration(
                  hintText: '0.00',
                  hintStyle: GoogleFonts.jetBrainsMono(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.outline,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.only(
                    left: 64,
                    right: 16,
                    top: 16,
                    bottom: 16,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'DEADLINE',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.05,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            Container(
              height: 32,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainer,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _isBS = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      height: 24,
                      decoration: BoxDecoration(
                        color: !_isBS ? AppTheme.surface : Colors.transparent,
                        borderRadius: BorderRadius.circular(99),
                        boxShadow: !_isBS
                            ? [
                                BoxShadow(
                                  color: AppTheme.onSurface.withValues(alpha: 0.1),
                                  blurRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          'AD',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: !_isBS
                                ? AppTheme.primary
                                : AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => setState(() => _isBS = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      height: 24,
                      decoration: BoxDecoration(
                        color: _isBS ? AppTheme.surface : Colors.transparent,
                        borderRadius: BorderRadius.circular(99),
                        boxShadow: _isBS
                            ? [
                                BoxShadow(
                                  color: AppTheme.onSurface.withValues(alpha: 0.1),
                                  blurRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          'BS',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _isBS
                                ? AppTheme.primary
                                : AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.outlineVariant, width: 1),
          ),
          child: GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _deadline,
                firstDate: DateTime.now().add(const Duration(days: 1)),
                lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
              );
              if (picked != null) setState(() => _deadline = picked);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      DateFormat('MMM dd, yyyy').format(_deadline),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: AppTheme.onSurface,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.calendar_today,
                    size: 20,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGrowthTipCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.secondaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.secondaryContainer, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppTheme.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lightbulb,
              size: 18,
              color: AppTheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GROWTH TIP',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                    color: AppTheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.onSurface,
                    ),
                    children: [
                      const TextSpan(
                        text: 'People who write down their goals are ',
                      ),
                      TextSpan(
                        text: '40% more likely',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(
                        text: ' to achieve them. You\'re already ahead!',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _saveGoal() {
    if (!_formKey.currentState!.validate()) return;

    final inputAmount = double.parse(_amountController.text);
    final storedAmount = CurrencyHelper.convertToStored(inputAmount);
    final isEditing = widget.goal != null;

    if (isEditing) {
      final updatedGoal = widget.goal!.copyWith(
        name: _nameController.text.trim(),
        emoji: _emoji,
        targetAmount: storedAmount,
        deadlineAD: _deadline,
      );
      context.read<GoalBloc>().add(GoalUpdateRequested(goal: updatedGoal));
    } else {
      final goal = Goal(
        id: Uuid().v4(),
        name: _nameController.text.trim(),
        emoji: _emoji,
        targetAmount: storedAmount,
        savedAmount: 0,
        deadlineAD: _deadline,
        deadlineBS: '',
        status: GoalStatus.onTrack,
        createdAt: DateTime.now(),
      );
      context.read<GoalBloc>().add(GoalAddRequested(goal: goal));
    }
    Navigator.pop(context);
  }
}

class _QuickEmojiButton extends StatelessWidget {
  final String emoji;
  final VoidCallback onTap;

  const _QuickEmojiButton({required this.emoji, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
      ),
    );
  }
}
