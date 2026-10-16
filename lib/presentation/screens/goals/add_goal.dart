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
  final _initialDepositController = TextEditingController();

  late DateTime _deadline;
  String _emoji = '🎯';
  int _selectedPresetMonths = 6;
  bool _includeInitialDeposit = false;

  // Preset goal ideas for rapid entry
  static const _goalPresets = [
    (name: 'Emergency Fund', emoji: '🛡️', months: 6),
    (name: 'Vacation Trip', emoji: '✈️', months: 4),
    (name: 'New Vehicle', emoji: '🚗', months: 12),
    (name: 'House Deposit', emoji: '🏠', months: 24),
    (name: 'New Laptop', emoji: '💻', months: 3),
    (name: 'Education Fund', emoji: '🎓', months: 12),
    (name: 'Celebration', emoji: '💍', months: 8),
    (name: 'Investments', emoji: '📈', months: 12),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.goal != null) {
      _nameController.text = widget.goal!.name;
      final displayTarget = CurrencyHelper.convertFromStored(
        widget.goal!.targetAmount,
      );
      _amountController.text = displayTarget > 0
          ? (displayTarget.truncateToDouble() == displayTarget
                ? displayTarget.toInt().toString()
                : displayTarget.toStringAsFixed(2))
          : '';
      _deadline = widget.goal!.deadlineAD;
      _emoji = widget.goal!.emoji;
      if (widget.goal!.savedAmount > 0) {
        _includeInitialDeposit = true;
        final displaySaved = CurrencyHelper.convertFromStored(
          widget.goal!.savedAmount,
        );
        _initialDepositController.text = displaySaved > 0
            ? (displaySaved.truncateToDouble() == displaySaved
                  ? displaySaved.toInt().toString()
                  : displaySaved.toStringAsFixed(2))
            : '';
      }
    } else {
      _deadline = DateTime.now().add(const Duration(days: 180));
    }

    _nameController.addListener(_onInputChanged);
    _amountController.addListener(_onInputChanged);
    _initialDepositController.addListener(_onInputChanged);
  }

  void _onInputChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _nameController.removeListener(_onInputChanged);
    _amountController.removeListener(_onInputChanged);
    _initialDepositController.removeListener(_onInputChanged);
    _nameController.dispose();
    _amountController.dispose();
    _initialDepositController.dispose();
    super.dispose();
  }

  double get _parsedTargetAmount {
    final clean = _amountController.text.replaceAll(',', '').trim();
    return double.tryParse(clean) ?? 0.0;
  }

  double get _parsedInitialDeposit {
    if (!_includeInitialDeposit) return 0.0;
    final clean = _initialDepositController.text.replaceAll(',', '').trim();
    return double.tryParse(clean) ?? 0.0;
  }

  int get _daysRemaining {
    final diff = _deadline.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : 1;
  }

  double get _dailyPace {
    final target = _parsedTargetAmount;
    final initial = _parsedInitialDeposit;
    final remaining = (target - initial).clamp(0.0, double.infinity);
    if (remaining <= 0 || _daysRemaining <= 0) return 0.0;
    return remaining / _daysRemaining;
  }

  double get _monthlyPace => _dailyPace * 30.416;

  void _applyPreset(String name, String emoji, int months) {
    HapticFeedback.selectionClick();
    setState(() {
      _nameController.text = name;
      _emoji = emoji;
      _selectedPresetMonths = months;
      _deadline = DateTime.now().add(Duration(days: months * 30));
    });
  }

  void _applyDuration(int months) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedPresetMonths = months;
      _deadline = DateTime.now().add(Duration(days: months * 30));
    });
  }

  void _bumpAmount(double delta) {
    HapticFeedback.lightImpact();
    final current = _parsedTargetAmount;
    final newAmount = current + delta;
    _amountController.text = newAmount.truncateToDouble() == newAmount
        ? newAmount.toInt().toString()
        : newAmount.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.goal != null;
    final isValid =
        _nameController.text.trim().isNotEmpty && _parsedTargetAmount > 0;

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
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          isEditing ? 'Edit Goal' : 'New Savings Goal',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurface,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: isValid ? _saveGoal : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isValid
                                ? AppTheme.primaryDark
                                : AppTheme.outlineVariant.withValues(
                                    alpha: 0.6,
                                  ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            isEditing ? 'Save' : 'Create',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isValid
                                  ? Colors.white
                                  : AppTheme.onSurfaceVariant.withValues(
                                      alpha: 0.7,
                                    ),
                            ),
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
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Live Interactive Hero Goal Preview Card
              _buildLiveHeroCard(),
              const SizedBox(height: 20),

              // One-Tap Goal Presets Carousel
              _buildPresetsCarousel(),
              const SizedBox(height: 22),

              // Form Inputs Card (Target Title & Amount)
              _buildInputsCard(),
              const SizedBox(height: 20),

              // Target Timeline & Deadline Card
              _buildTimelineCard(),
              const SizedBox(height: 20),

              // Optional Starting Balance Card
              _buildStartingBalanceCard(),
              const SizedBox(height: 24),

              // Primary Action Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: isValid ? _saveGoal : null,
                  icon: Icon(
                    isEditing
                        ? CupertinoIcons.check_mark_circled_solid
                        : CupertinoIcons.plus_circle_fill,
                    size: 20,
                    color: Colors.white,
                  ),
                  label: Text(
                    isEditing ? 'Save Changes' : 'Create Goal',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondary,
                    disabledBackgroundColor: AppTheme.outlineVariant.withValues(
                      alpha: 0.6,
                    ),
                    elevation: isValid ? 3 : 0,
                    shape: const StadiumBorder(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Hero Live Preview Card ──
  Widget _buildLiveHeroCard() {
    final title = _nameController.text.trim().isEmpty
        ? 'My Savings Goal'
        : _nameController.text.trim();
    final hasAmount = _parsedTargetAmount > 0;
    final initial = _parsedInitialDeposit;
    final progress = hasAmount
        ? (initial / _parsedTargetAmount).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEAF3E8), // Fresh soft sage
            Color(0xFFD6E9D4), // Verdant Sol biophilic gradient
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.22),
          width: 1.2,
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Interactive Avatar Badge
              GestureDetector(
                onTap: _showEmojiPicker,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                          width: 1.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryDark.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _emoji,
                          style: const TextStyle(fontSize: 34),
                        ),
                      ),
                    ),
                    Positioned(
                      right: -3,
                      bottom: -3,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryDark,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          CupertinoIcons.pencil,
                          size: 11,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.onSurface,
                        letterSpacing: -0.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasAmount
                          ? 'Target: ${CurrencyHelper.symbol}${CurrencyHelper.format(_parsedTargetAmount)}'
                          : 'Enter target amount below',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            CupertinoIcons.calendar,
                            size: 11,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MMM yyyy').format(_deadline),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryDark,
                            ),
                          ),
                          Text(
                            ' • $_daysRemaining days',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Live Progress Bar if Initial Deposit > 0
          if (initial > 0 && hasAmount) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                backgroundColor: Colors.white.withValues(alpha: 0.6),
                valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Starting balance: ${CurrencyHelper.symbol}${CurrencyHelper.format(initial)}',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(1)}%',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryDark,
                  ),
                ),
              ],
            ),
          ],

          // Real-time Savings Pace Projection Box
          if (hasAmount) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.outlineVariant.withValues(alpha: 0.5),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        'REQUIRED DAILY',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${CurrencyHelper.symbol}${CurrencyHelper.format(_dailyPace)}/day',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 1,
                    height: 26,
                    color: AppTheme.outlineVariant,
                  ),
                  Column(
                    children: [
                      Text(
                        'REQUIRED MONTHLY',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${CurrencyHelper.symbol}${CurrencyHelper.format(_monthlyPace)}/mo',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── One-Tap Inspiration Templates ──
  Widget _buildPresetsCarousel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'QUICK STARTERS',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            Text(
              'Tap to autofill',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _goalPresets.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final preset = _goalPresets[index];
              final isSelected =
                  _nameController.text.trim() == preset.name &&
                  _emoji == preset.emoji;
              return GestureDetector(
                onTap: () =>
                    _applyPreset(preset.name, preset.emoji, preset.months),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryDark : Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryDark
                          : AppTheme.outlineVariant,
                      width: 0.8,
                    ),
                    boxShadow: isSelected ? null : AppTheme.cardShadow,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(preset.emoji, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        preset.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : AppTheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Primary Form Inputs Card (Title & Target) ──
  Widget _buildInputsCard() {
    final isUsd = CurrencyHelper.currency == 'USD';
    final bumpValues = isUsd
        ? [100.0, 500.0, 1000.0, 5000.0]
        : [10000.0, 50000.0, 100000.0, 500000.0];
    final bumpLabels = isUsd
        ? ['+ \$100', '+ \$500', '+ \$1K', '+ \$5K']
        : ['+ 10K', '+ 50K', '+ 1 Lakh', '+ 5 Lakh'];

    return Container(
      decoration: AppTheme.iosCardDecoration,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Goal Name Input
          Text(
            'GOAL TITLE',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.outlineVariant, width: 0.8),
            ),
            child: Row(
              children: [
                const Icon(
                  CupertinoIcons.flag_fill,
                  size: 16,
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. Dream Trip, Emergency Cushion',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter a goal title';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Target Amount Input
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TARGET AMOUNT',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.mint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  CurrencyHelper.currency,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.outlineVariant, width: 0.8),
            ),
            child: Row(
              children: [
                Text(
                  CurrencyHelper.symbol,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: GoogleFonts.jetBrainsMono(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurfaceVariant.withValues(alpha: 0.4),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter target amount';
                      }
                      final amt = double.tryParse(
                        val.replaceAll(',', '').trim(),
                      );
                      if (amt == null || amt <= 0) {
                        return 'Please enter a valid positive amount';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Quick Bump Chips
          Row(
            children: List.generate(bumpValues.length, (i) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: i < bumpValues.length - 1 ? 6 : 0,
                  ),
                  child: GestureDetector(
                    onTap: () => _bumpAmount(bumpValues[i]),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.outlineVariant,
                          width: 0.8,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        bumpLabels[i],
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Target Timeline & Deadline Card ──
  Widget _buildTimelineCard() {
    final durations = [
      (label: '3 Mo', months: 3),
      (label: '6 Mo', months: 6),
      (label: '1 Yr', months: 12),
      (label: '2 Yrs', months: 24),
    ];

    return Container(
      decoration: AppTheme.iosCardDecoration,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TARGET TIMELINE',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              Text(
                '$_daysRemaining days to save',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Duration Pills Row
          Row(
            children: [
              ...durations.map((d) {
                final isSelected = _selectedPresetMonths == d.months;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => _applyDuration(d.months),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryDark
                              : AppTheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryDark
                                : AppTheme.outlineVariant,
                            width: 0.8,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          d.label,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : AppTheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
              // Custom Date Button
              Expanded(
                child: GestureDetector(
                  onTap: _pickCustomDeadline,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _selectedPresetMonths == -1
                          ? AppTheme.primaryDark
                          : AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _selectedPresetMonths == -1
                            ? AppTheme.primaryDark
                            : AppTheme.outlineVariant,
                        width: 0.8,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.calendar,
                          size: 13,
                          color: _selectedPresetMonths == -1
                              ? Colors.white
                              : AppTheme.onSurface,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Custom',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: _selectedPresetMonths == -1
                                ? Colors.white
                                : AppTheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Exact Date Display Row
          GestureDetector(
            onTap: _pickCustomDeadline,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.outlineVariant, width: 0.8),
              ),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.calendar_today,
                    size: 16,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TARGET DEADLINE DATE',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('EEEE, MMMM dd, yyyy').format(_deadline),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    CupertinoIcons.chevron_right,
                    size: 14,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Optional Starting Balance Card ──
  Widget _buildStartingBalanceCard() {
    return Container(
      decoration: AppTheme.iosCardDecoration,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.mint,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  CupertinoIcons.archivebox_fill,
                  size: 16,
                  color: AppTheme.primaryDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Initial Starting Balance',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    Text(
                      'Already saved money towards this target?',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoSwitch(
                value: _includeInitialDeposit,
                activeColor: AppTheme.primary,
                onChanged: (val) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _includeInitialDeposit = val;
                    if (!val) {
                      _initialDepositController.clear();
                    }
                  });
                },
              ),
            ],
          ),
          if (_includeInitialDeposit) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.outlineVariant, width: 0.8),
              ),
              child: Row(
                children: [
                  Text(
                    CurrencyHelper.symbol,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _initialDepositController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      autofocus: true,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Already saved amount',
                        hintStyle: GoogleFonts.jetBrainsMono(
                          fontSize: 14,
                          color: AppTheme.onSurfaceVariant.withValues(
                            alpha: 0.4,
                          ),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Native iOS Cupertino Date Picker Modal ──
  void _pickCustomDeadline() {
    HapticFeedback.lightImpact();
    DateTime tempDate = _deadline;

    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => Container(
        height: 310,
        padding: const EdgeInsets.only(top: 6),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                    Text(
                      'Target Deadline',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Text(
                        'Done',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _deadline = tempDate;
                          _selectedPresetMonths = -1; // custom
                        });
                        Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime:
                      _deadline.isBefore(
                        DateTime.now().add(const Duration(days: 1)),
                      )
                      ? DateTime.now().add(const Duration(days: 30))
                      : _deadline,
                  minimumDate: DateTime.now().add(const Duration(days: 1)),
                  maximumDate: DateTime.now().add(
                    const Duration(days: 365 * 15),
                  ),
                  onDateTimeChanged: (newDate) {
                    tempDate = newDate;
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Rich Categorized Emoji Picker Sheet ──
  void _showEmojiPicker() {
    HapticFeedback.lightImpact();
    final emojiController = TextEditingController(text: _emoji);

    const categories = {
      'Targets & Finance': [
        '🎯',
        '💰',
        '💳',
        '🏦',
        '💵',
        '🪙',
        '📈',
        '💎',
        '🏆',
        '⭐',
        '🛍️',
        '📦',
      ],
      'Travel & Adventure': [
        '✈️',
        '🏖️',
        '🌴',
        '🚗',
        '🏍️',
        '🚲',
        '🚢',
        '🏕️',
        '🏔️',
        '🗽',
        '🚂',
        '🚁',
      ],
      'Home & Lifestyle': [
        '🏠',
        '🏡',
        '🛋️',
        '💍',
        '👶',
        '🎓',
        '🎂',
        '🎁',
        '🐾',
        '🐶',
        '🐱',
        '🪴',
      ],
      'Tech & Education': [
        '💻',
        '📱',
        '📷',
        '🎧',
        '🎮',
        '🎨',
        '📚',
        '🎸',
        '⌚',
        '🖥️',
        '👟',
        '⚽',
      ],
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      showDragHandle: false,
      sheetAnimationStyle: appSheetAnimationStyle,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              constraints: const BoxConstraints(maxHeight: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4.5,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Choose Goal Icon',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.onSurface,
                          letterSpacing: -0.3,
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minSize: 28,
                        onPressed: () => Navigator.pop(sheetContext),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerLow,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.xmark,
                            size: 13,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Custom Emoji Input
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppTheme.outlineVariant,
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          child: Text(
                            _emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: emojiController,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Type any custom emoji from keyboard',
                              hintStyle: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: AppTheme.onSurfaceVariant.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            onChanged: (val) {
                              if (val.trim().isNotEmpty) {
                                final char = val.characters.last;
                                setSheetState(() => _emoji = char);
                                setState(() => _emoji = char);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Categorized Grid
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: categories.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.key.toUpperCase(),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.7,
                                  color: AppTheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: entry.value.map((em) {
                                  final isSelected = _emoji == em;
                                  return GestureDetector(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(() => _emoji = em);
                                      Navigator.pop(sheetContext);
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 150,
                                      ),
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppTheme.mint
                                            : AppTheme.surfaceContainerLow,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppTheme.primary
                                              : AppTheme.outlineVariant,
                                          width: isSelected ? 1.8 : 0.8,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        em,
                                        style: const TextStyle(fontSize: 22),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Save or Create Goal ──
  void _saveGoal() {
    HapticFeedback.lightImpact();
    if (!_formKey.currentState!.validate()) return;

    final targetVal = _parsedTargetAmount;
    if (targetVal <= 0) return;

    final storedTarget = CurrencyHelper.convertToStored(targetVal);
    final initialVal = _parsedInitialDeposit;
    final storedInitial = CurrencyHelper.convertToStored(initialVal);
    final isEditing = widget.goal != null;

    final initialHistory = <SavingsContribution>[];
    if (storedInitial > 0) {
      initialHistory.add(
        SavingsContribution(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          amount: storedInitial,
          date: DateTime.now(),
        ),
      );
    }

    if (isEditing) {
      final updatedGoal = widget.goal!.copyWith(
        name: _nameController.text.trim(),
        emoji: _emoji,
        targetAmount: storedTarget,
        deadlineAD: _deadline,
        savedAmount: storedInitial > 0
            ? storedInitial
            : widget.goal!.savedAmount,
        savingsHistory: storedInitial > 0 && widget.goal!.savingsHistory.isEmpty
            ? initialHistory
            : widget.goal!.savingsHistory,
      );
      context.read<GoalBloc>().add(GoalUpdateRequested(goal: updatedGoal));
    } else {
      final goalStatus = storedInitial >= storedTarget
          ? GoalStatus.achieved
          : GoalStatus.onTrack;
      final newGoal = Goal(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        emoji: _emoji,
        targetAmount: storedTarget,
        savedAmount: storedInitial,
        deadlineAD: _deadline,
        deadlineBS: '',
        status: goalStatus,
        createdAt: DateTime.now(),
        savingsHistory: initialHistory,
      );
      context.read<GoalBloc>().add(GoalAddRequested(goal: newGoal));
    }
    Navigator.pop(context);
  }
}
