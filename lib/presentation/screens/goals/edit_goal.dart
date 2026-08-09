part of 'goals_imports.dart';

class EditGoalScreen extends StatefulWidget {
  final Goal goal;

  const EditGoalScreen({super.key, required this.goal});

  @override
  State<EditGoalScreen> createState() => _EditGoalScreenState();
}

class _EditGoalScreenState extends State<EditGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  late DateTime _deadline;
  late String _emoji;
  late GoalStatus _status;
  bool _showBS = true;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.goal.name;
    final displayAmount = CurrencyHelper.convertFromStored(
      widget.goal.targetAmount,
    );
    _amountController.text = displayAmount > 0
        ? displayAmount.toStringAsFixed(0)
        : '';
    _deadline = widget.goal.deadlineAD;
    _emoji = widget.goal.emoji;
    _status = widget.goal.status;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  static const _emojis = [
    '\u{1F3AF}',
    '\u{1F4BB}',
    '\u{1F4F1}',
    '\u{1F3E0}',
    '\u{1F697}',
    '\u{2708}\u{FE0F}',
    '\u{1F48D}',
    '\u{1F393}',
    '\u{1F3E5}',
    '\u{1F381}',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Goal',
          style: GoogleFonts.manrope(
            fontSize: 20,
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
          TextButton.icon(
            onPressed: () => _confirmDelete(context),
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 18,
              color: AppTheme.error,
            ),
            label: Text(
              'Delete',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.error,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
          children: [
            _buildEmojiSelector(),
            const SizedBox(height: 24),
            _buildLabel('GOAL NAME'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.outlineVariant, width: 1),
              ),
              child: TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'What are you saving for?',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 16,
                    color: AppTheme.outline,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a goal name';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 20),
            _buildLabel('TARGET AMOUNT'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.outlineVariant, width: 1),
              ),
              child: TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
                decoration: InputDecoration(
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 14, right: 8),
                    child: Text(
                      CurrencyHelper.currency,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 0,
                    minHeight: 0,
                  ),
                  hintText: '0',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a target amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 20),
            _buildDeadlineSection(),
            const SizedBox(height: 20),
            _buildLabel('GOAL STATUS'),
            const SizedBox(height: 8),
            _buildStatusSelector(),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.only(top: 24),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppTheme.outlineVariant, width: 1),
                ),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmDelete(context),
                      icon: const Icon(
                        Icons.delete_forever_rounded,
                        color: AppTheme.error,
                      ),
                      label: Text(
                        'Delete This Goal',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.error,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.error, width: 1),
                        backgroundColor: AppTheme.errorContainer.withValues(
                          alpha: 0.1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Deleting this goal will also archive its saving history. This action is irreversible.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }

  Widget _buildEmojiSelector() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outlineVariant, width: 1),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _showEmojiPicker,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryFixed,
                    shape: BoxShape.circle,
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
                      color: AppTheme.onPrimary,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tap to change icon',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: _emojis.length,
            itemBuilder: (context, index) {
              final emoji = _emojis[index];
              final isSelected = emoji == _emoji;
              return GestureDetector(
                onTap: () => setState(() => _emoji = emoji),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary.withValues(alpha: 0.08)
                        : AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.outlineVariant,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 24)),
                  ),
                ),
              );
            },
          ),
        ],
      ),
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

  Widget _buildDeadlineSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLabel('DEADLINE'),
            Container(
              height: 28,
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  _buildToggleBtn('BS', _showBS, () {
                    setState(() => _showBS = true);
                  }),
                  _buildToggleBtn('AD', !_showBS, () {
                    setState(() => _showBS = false);
                  }),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _deadline,
              firstDate: DateTime.now().add(const Duration(days: 1)),
              lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
            );
            if (picked != null) setState(() => _deadline = picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppTheme.surfaceContainerLowest,
              border: Border.all(color: AppTheme.outlineVariant, width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    DateFormat('MMMM dd, yyyy').format(_deadline),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ),
                const Icon(
                  Icons.calendar_month,
                  color: AppTheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Approximately ${_deadline.difference(DateTime.now()).inDays ~/ 30} months left to save.',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildToggleBtn(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isActive ? AppTheme.onPrimary : AppTheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusSelector() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _status = GoalStatus.onTrack),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: _status == GoalStatus.onTrack
                    ? AppTheme.secondary.withValues(alpha: 0.1)
                    : AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _status == GoalStatus.onTrack
                      ? AppTheme.secondary
                      : AppTheme.outlineVariant,
                  width: _status == GoalStatus.onTrack ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: _status == GoalStatus.onTrack
                        ? AppTheme.secondary
                        : AppTheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'On Track',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: _status == GoalStatus.onTrack
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: _status == GoalStatus.onTrack
                          ? AppTheme.secondary
                          : AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _status = GoalStatus.behind),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: _status == GoalStatus.behind
                    ? AppTheme.tertiaryFixed.withValues(alpha: 0.3)
                    : AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _status == GoalStatus.behind
                      ? AppTheme.onTertiaryContainer
                      : AppTheme.outlineVariant,
                  width: _status == GoalStatus.behind ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_rounded,
                    size: 18,
                    color: _status == GoalStatus.behind
                        ? AppTheme.onTertiaryContainer
                        : AppTheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Off Track',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: _status == GoalStatus.behind
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: _status == GoalStatus.behind
                          ? AppTheme.onTertiaryContainer
                          : AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.05,
        color: AppTheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        border: Border(top: BorderSide(color: AppTheme.outlineVariant, width: 1)),
      ),
      child: SizedBox(
        height: 54,
        child: ElevatedButton.icon(
          onPressed: _saveGoal,
          icon: const Icon(Icons.save_rounded, size: 20),
          label: Text(
            'Save Changes',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: AppTheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  void _saveGoal() {
    if (!_formKey.currentState!.validate()) return;

    final inputAmount = double.parse(_amountController.text);
    final storedAmount = CurrencyHelper.convertToStored(inputAmount);

    final updatedGoal = widget.goal.copyWith(
      name: _nameController.text.trim(),
      emoji: _emoji,
      targetAmount: storedAmount,
      deadlineAD: _deadline,
      status: _status,
    );
    context.read<GoalBloc>().add(GoalUpdateRequested(goal: updatedGoal));
    Navigator.pop(context);
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Goal'),
          content: Text(
            'Are you sure you want to delete "${widget.goal.name}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                context.read<GoalBloc>().add(
                  GoalDeleteRequested(id: widget.goal.id),
                );
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
}
