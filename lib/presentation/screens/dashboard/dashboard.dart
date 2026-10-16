part of 'dashboard_imports.dart';

class DashboardScreen extends StatefulWidget {
  final ValueChanged<int>? onSwitchTab;
  const DashboardScreen({super.key, this.onSwitchTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

enum DashboardTxFilter { all, expense, income }

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime _selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );
  bool _showIncome =
      false; // Toggles between Expenses & Income on Hero & Categories
  DashboardTxFilter _activityFilter =
      DashboardTxFilter.all; // Filters Recent Activity
  String _userName = 'User';
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<GoalBloc>().add(GoalLoadRequested());
      }
    });
  }

  void _openMonthPicker(BuildContext context) {
    HapticFeedback.lightImpact();
    DateTime tempMonth = _selectedMonth;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      sheetAnimationStyle: appSheetAnimationStyle,
      builder: (BuildContext ctx) {
        return Container(
          height: 335,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 36,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: AppTheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          color: AppTheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                    Text(
                      'Select Month',
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
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: () {
                        setState(() => _selectedMonth = tempMonth);
                        Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppTheme.outlineVariant),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _selectedMonth,
                  minimumDate: DateTime(2020, 1, 1),
                  maximumDate: DateTime(2035, 12, 31),
                  onDateTimeChanged: (DateTime newDate) {
                    tempMonth = DateTime(newDate.year, newDate.month, 1);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();
    if (user != null) {
      setState(() {
        _userName = prefs.getString('userName') ?? user.displayName ?? 'User';
        _photoUrl = user.photoURL;
      });
    } else {
      setState(() {
        _userName = prefs.getString('userName') ?? 'Guest';
        _photoUrl = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildIosAppBar(context),
      body: RefreshIndicator.adaptive(
        color: AppTheme.primary,
        onRefresh: () async {
          context.read<TransactionBloc>().add(TransactionLoadRequested());
          context.read<GoalBloc>().add(GoalLoadRequested());
          await _loadUserProfile();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreetingsSection(context),
              const SizedBox(height: 14),
              _buildVerdantHeroCard(context),
              const SizedBox(height: 24),
              _buildActiveGoalsSection(context),
              const SizedBox(height: 24),
              _buildCategoriesSection(context),
              const SizedBox(height: 24),
              _buildRecentTransactions(context),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 74),
        child: FloatingActionButton(
          heroTag: 'dashboard_fab',
          backgroundColor: AppTheme.primaryDark,
          foregroundColor: Colors.white,
          elevation: 6,
          shape: const CircleBorder(),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              CupertinoPageRoute(
                fullscreenDialog: true,
                builder: (_) => BlocProvider.value(
                  value: context.read<TransactionBloc>(),
                  child: const AddTransactionScreen(),
                ),
              ),
            );
          },
          child: const Icon(CupertinoIcons.plus, size: 22),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildIosAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(56),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.background.withValues(alpha: 0.88),
              border: const Border(
                bottom: BorderSide(color: Color(0x10000000), width: 0.5),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: ClipOval(
                        child: _photoUrl != null && _photoUrl!.isNotEmpty
                            ? Image.network(
                                _photoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildAvatarFallback(),
                              )
                            : _buildAvatarFallback(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Sajilo Khata',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLow,
                        shape: BoxShape.circle,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(CupertinoIcons.bell, size: 20),
                            color: AppTheme.onSurface,
                            splashRadius: 20,
                            onPressed: () {
                              HapticFeedback.selectionClick();
                            },
                          ),
                          Positioned(
                            top: 8,
                            right: 9,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: AppTheme.coral,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.background,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarFallback() {
    final initial = _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U';
    return Container(
      color: AppTheme.mint,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppTheme.primaryDark,
        ),
      ),
    );
  }

  Widget _buildGreetingsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Namaste, $_userName',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Financial Overview',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppTheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  /// Verdant Sol Hero Card matching image.png:
  /// - Real user data from TransactionBloc
  /// - Segmented control inside the card: [Income] vs [Expenses]
  /// - Real Month-over-Month calculation badge
  /// - Real Balance figure with cents smaller
  /// - Real wave curve chart based on past 6 months transactions
  /// - Real tooltip displaying current month total
  Widget _buildVerdantHeroCard(BuildContext context) {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        double income = 0;
        double expense = 0;
        double prevIncome = 0;
        double prevExpense = 0;

        // Generate 5 months window with _selectedMonth centered at index 2
        // [-2, -1, 0, 1, 2] -> index 2 is _selectedMonth
        final displayMonths = List.generate(5, (i) {
          final offset = i - 2;
          return DateTime(
            _selectedMonth.year,
            _selectedMonth.month + offset,
            1,
          );
        });
        const selectedIndex = 2; // Center month

        final List<double> monthlyPoints = [];

        if (state is TransactionLoaded) {
          // Current selected month
          final currentTxs = state.getTransactionsForMonth(_selectedMonth);
          income = currentTxs
              .where((tx) => tx.type == TransactionType.credit)
              .fold(0.0, (sum, tx) => sum + tx.amount);
          expense = currentTxs
              .where((tx) => tx.type == TransactionType.debit)
              .fold(0.0, (sum, tx) => sum + tx.amount);

          // Previous month for real % change
          final prevMonth = DateTime(
            _selectedMonth.year,
            _selectedMonth.month - 1,
            1,
          );
          final prevTxs = state.getTransactionsForMonth(prevMonth);
          prevIncome = prevTxs
              .where((tx) => tx.type == TransactionType.credit)
              .fold(0.0, (sum, tx) => sum + tx.amount);
          prevExpense = prevTxs
              .where((tx) => tx.type == TransactionType.debit)
              .fold(0.0, (sum, tx) => sum + tx.amount);

          // 5 months points centered on _selectedMonth
          for (final m in displayMonths) {
            final txs = state.getTransactionsForMonth(m);
            final amt = txs
                .where(
                  (tx) =>
                      tx.type ==
                      (_showIncome
                          ? TransactionType.credit
                          : TransactionType.debit),
                )
                .fold(0.0, (sum, tx) => sum + tx.amount);
            monthlyPoints.add(amt);
          }
        } else {
          monthlyPoints.addAll([0, 0, 0, 0, 0]);
        }

        final activeAmount = _showIncome ? income : expense;
        final prevActive = _showIncome ? prevIncome : prevExpense;

        // Real percentage calculation
        String badgeText;
        IconData badgeIcon = CupertinoIcons.arrow_up_right;
        if (prevActive > 0) {
          final diff = ((activeAmount - prevActive) / prevActive * 100);
          final isUp = diff >= 0;
          badgeIcon = isUp
              ? CupertinoIcons.arrow_up_right
              : CupertinoIcons.arrow_down_right;
          badgeText = '${diff.abs().toStringAsFixed(1)}% this month';
        } else if (activeAmount > 0) {
          badgeText = 'Logged this month';
          badgeIcon = CupertinoIcons.check_mark;
        } else {
          badgeText = 'No activity';
          badgeIcon = CupertinoIcons.minus;
        }

        final formattedStr = CurrencyHelper.format(activeAmount);
        String integerPart = formattedStr;
        String decimalPart = '';
        if (formattedStr.contains('.')) {
          final parts = formattedStr.split('.');
          integerPart = parts[0];
          decimalPart = '.${parts[1]}';
        }

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6B8F62), // Soft bright sage moss
                Color(0xFF5A7853), // Muted Moss primary
                Color(0xFF45633E), // Deep botanical obsidian moss
              ],
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: AppTheme.dashboardShadow,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: -30,
                right: -20,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Header Row: [ Income / Expenses ] toggle + [ 📅 Month Year ▾ ] selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _HeroSegmentTab(
                                label: 'Income',
                                icon: CupertinoIcons.arrow_down_left,
                                isActive: _showIncome,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _showIncome = true);
                                },
                              ),
                              _HeroSegmentTab(
                                label: 'Expenses',
                                icon: CupertinoIcons.creditcard,
                                isActive: !_showIncome,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _showIncome = false);
                                },
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _openMonthPicker(context),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.22),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  CupertinoIcons.calendar,
                                  size: 13,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  DateFormat('MMM yyyy').format(_selectedMonth),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                const Icon(
                                  CupertinoIcons.chevron_down,
                                  size: 10,
                                  color: Colors.white70,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Growth Pill Chip: Real calculated metric
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(badgeIcon, size: 11, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            badgeText,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Main Big Balance with lighter smaller cents
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${CurrencyHelper.symbol}$integerPart',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.2,
                            color: Colors.white,
                          ),
                        ),
                        if (decimalPart.isNotEmpty)
                          Text(
                            decimalPart,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Wavy Curve Chart with Floating Dark Tooltip
                    SizedBox(
                      height: 140,
                      width: double.infinity,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapUp: (details) {
                              final count = displayMonths.length;
                              final stepX = constraints.maxWidth / (count - 1);
                              final tappedIndex =
                                  (details.localPosition.dx / stepX)
                                      .round()
                                      .clamp(0, count - 1);
                              final targetMonth = displayMonths[tappedIndex];
                              if (targetMonth.month != _selectedMonth.month ||
                                  targetMonth.year != _selectedMonth.year) {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _selectedMonth = targetMonth;
                                });
                              }
                            },
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _HeroWaveChartPainter(
                                      points: monthlyPoints,
                                      isIncome: _showIncome,
                                      selectedIndex: selectedIndex,
                                    ),
                                  ),
                                ),

                                // Floating Dark Tooltip Card showing active real month data in center
                                Align(
                                  alignment: Alignment.topCenter,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF101510),
                                        borderRadius: BorderRadius.circular(18),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.35,
                                            ),
                                            blurRadius: 18,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                '${CurrencyHelper.symbol}${CurrencyHelper.format(activeAmount)}',
                                                style:
                                                    GoogleFonts.plusJakartaSans(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: Colors.white,
                                                    ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  _showIncome
                                                      ? 'INCOME'
                                                      : 'EXPENSES',
                                                  style:
                                                      GoogleFonts.plusJakartaSans(
                                                        fontSize: 9,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color: Colors.black,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'for ${DateFormat('MMMM yyyy').format(_selectedMonth)}',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.white.withValues(
                                                alpha: 0.65,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Interactive Months Axis centered on _selectedMonth
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: displayMonths.map((m) {
                        final isHighlighted =
                            m.month == _selectedMonth.month &&
                            m.year == _selectedMonth.year;
                        final label = DateFormat('MMM').format(m);
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedMonth = m;
                            });
                          },
                          behavior: HitTestBehavior.opaque,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: isHighlighted
                                  ? Colors.white.withValues(alpha: 0.24)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: isHighlighted
                                  ? Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.45,
                                      ),
                                      width: 0.8,
                                    )
                                  : null,
                            ),
                            child: Text(
                              label,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: isHighlighted
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                                color: isHighlighted
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.65),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Active Goals Section:
  /// - Prominently displays the user's active savings goal on homepage
  /// - Real-time progress bar, saved vs target metrics, and quick deposit action
  /// - "See All" directly switches to the Goals tab while preserving the bottom bar!
  Widget _buildActiveGoalsSection(BuildContext context) {
    return BlocBuilder<GoalBloc, GoalState>(
      builder: (context, state) {
        final List<Goal> activeGoals = state is GoalLoaded
            ? state.activeGoals
            : [];
        final topGoal = activeGoals.isNotEmpty ? activeGoals.first : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Active Goals',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: AppTheme.onSurface,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    if (widget.onSwitchTab != null) {
                      widget.onSwitchTab!(2);
                    } else {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (_) => BlocProvider.value(
                            value: context.read<GoalBloc>(),
                            child: const GoalsListScreen(),
                          ),
                        ),
                      );
                    }
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      Text(
                        'See All',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        CupertinoIcons.chevron_forward,
                        size: 14,
                        color: AppTheme.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (topGoal != null)
              _buildTopActiveGoalCard(context, topGoal, activeGoals.length)
            else
              _buildEmptyGoalCard(context),
          ],
        );
      },
    );
  }

  Widget _buildTopActiveGoalCard(
    BuildContext context,
    Goal goal,
    int totalActive,
  ) {
    final isOnTrack = goal.status == GoalStatus.onTrack;
    final isAchieved = goal.status == GoalStatus.achieved;
    final statusLabel = isAchieved
        ? 'ACHIEVED'
        : isOnTrack
        ? 'ON TRACK'
        : 'BEHIND';
    final progressColor = isAchieved
        ? AppTheme.income
        : isOnTrack
        ? AppTheme.primary
        : AppTheme.expense;

    final progressPct = (goal.progressPercent * 100).clamp(0, 100).toInt();

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<GoalBloc>(),
              child: GoalDetailScreen(initialGoal: goal),
            ),
          ),
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: AppTheme.iosCardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppTheme.mint,
                    borderRadius: BorderRadius.circular(
                      AppTheme.squircleRadius,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      goal.emoji.isNotEmpty ? goal.emoji : '🎯',
                      style: const TextStyle(fontSize: 22),
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
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurface,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isAchieved || isOnTrack
                                  ? AppTheme.mint
                                  : AppTheme.tertiaryContainer,
                              borderRadius: BorderRadius.circular(
                                AppTheme.pillRadius,
                              ),
                            ),
                            child: Text(
                              statusLabel,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: isAchieved || isOnTrack
                                    ? AppTheme.primaryDark
                                    : AppTheme.onTertiaryContainer,
                              ),
                            ),
                          ),
                          if (totalActive > 1) ...[
                            const SizedBox(width: 6),
                            Text(
                              '• +${totalActive - 1} more',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF101510),
                    borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                  ),
                  child: Text(
                    '$progressPct%',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SAVED',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${CurrencyHelper.symbol}${CurrencyHelper.format(goal.savedAmount)}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: progressColor,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'TARGET',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${CurrencyHelper.symbol}${CurrencyHelper.format(goal.targetAmount)}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.pillRadius),
              child: LinearProgressIndicator(
                value: goal.progressPercent.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: AppTheme.surfaceContainerLow,
                valueColor: AlwaysStoppedAnimation(progressColor),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${CurrencyHelper.symbol}${CurrencyHelper.format(goal.remaining)} remaining',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    AddSavingsBottomSheet.show(context, goal);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.mint,
                      borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          CupertinoIcons.plus,
                          size: 13,
                          color: AppTheme.primaryDark,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Deposit',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyGoalCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: AppTheme.iosCardDecoration,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.flag,
              size: 22,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'No Active Goals',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Set savings targets to track your milestones\nand achieve financial freedom.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              height: 1.35,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<GoalBloc>(),
                    child: const AddGoalScreen(),
                  ),
                ),
              );
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF101510),
                borderRadius: BorderRadius.circular(AppTheme.pillRadius),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    CupertinoIcons.plus,
                    size: 13,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Create Goal',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
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

  /// Categories Section:
  /// - 100% computed from real user transactions for the selected month
  /// - Seamlessly toggles between Income and Expense categories based on _showIncome
  /// - If no transactions, shows an authentic Apple empty state card
  /// - If transactions exist, shows the 2-column Bento Grid from image.png
  Widget _buildCategoriesSection(BuildContext context) {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        final categoryTotals = <String, double>{};
        final targetType = _showIncome
            ? TransactionType.credit
            : TransactionType.debit;
        if (state is TransactionLoaded) {
          final monthTxs = state.getTransactionsForMonth(_selectedMonth);
          for (final tx in monthTxs.where((tx) => tx.type == targetType)) {
            categoryTotals[tx.category] =
                (categoryTotals[tx.category] ?? 0) + tx.amount;
          }
        }

        final sortedCategories = categoryTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _showIncome ? 'Income Categories' : 'Expense Categories',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: AppTheme.onSurface,
                  ),
                ),
                if (sortedCategories.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      if (widget.onSwitchTab != null) {
                        widget.onSwitchTab!(1);
                      } else {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (_) => BlocProvider.value(
                              value: context.read<TransactionBloc>(),
                              child: const TransactionListScreen(),
                            ),
                          ),
                        );
                      }
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Text(
                      'View All',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            if (sortedCategories.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 26,
                ),
                decoration: AppTheme.iosCardDecoration,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLow,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _showIncome
                            ? CupertinoIcons.arrow_down_circle
                            : CupertinoIcons.square_grid_2x2,
                        size: 22,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No ${_showIncome ? "Income" : "Expenses"} in ${DateFormat('MMMM yyyy').format(_selectedMonth)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Categorized ${_showIncome ? "income sources" : "spending"} for ${DateFormat('MMMM yyyy').format(_selectedMonth)} will appear here as you log transactions.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  for (int i = 0; i < sortedCategories.length; i += 2)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: i + 2 < sortedCategories.length ? 14 : 0,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _CategoryBentoCard(
                              title: sortedCategories[i].key,
                              amount: sortedCategories[i].value,
                              icon: _getCategoryIcon(sortedCategories[i].key),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: i + 1 < sortedCategories.length
                                ? _CategoryBentoCard(
                                    title: sortedCategories[i + 1].key,
                                    amount: sortedCategories[i + 1].value,
                                    icon: _getCategoryIcon(
                                      sortedCategories[i + 1].key,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }

  /// Recent Activity Section:
  /// - 100% computed from real user transactions for the selected month
  /// - User can filter by [ All | Expenses | Income ] for that month
  Widget _buildRecentTransactions(BuildContext context) {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        if (state is! TransactionLoaded) {
          return const Center(child: CupertinoActivityIndicator(radius: 12));
        }

        final monthTxs = state.getTransactionsForMonth(_selectedMonth);
        final filteredTxs = switch (_activityFilter) {
          DashboardTxFilter.all => monthTxs,
          DashboardTxFilter.expense =>
            monthTxs.where((tx) => tx.type == TransactionType.debit).toList(),
          DashboardTxFilter.income =>
            monthTxs.where((tx) => tx.type == TransactionType.credit).toList(),
        }..sort((a, b) => b.dateAD.compareTo(a.dateAD));

        final monthName = DateFormat('MMMM yyyy').format(_selectedMonth);
        final latestTxs = filteredTxs.take(5).toList();

        return Container(
          decoration: AppTheme.iosCardDecoration,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Activity',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.onSurface,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${filteredTxs.length}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            if (widget.onSwitchTab != null) {
                              widget.onSwitchTab!(1);
                            } else {
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (_) => BlocProvider.value(
                                    value: context.read<TransactionBloc>(),
                                    child: const TransactionListScreen(),
                                  ),
                                ),
                              );
                            }
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Row(
                            children: [
                              Text(
                                'See All',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primary,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(
                                CupertinoIcons.chevron_forward,
                                size: 14,
                                color: AppTheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // iOS Segmented Type Selector [ All | Expenses | Income ]
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(
                          AppTheme.pillRadius,
                        ),
                        border: Border.all(
                          color: AppTheme.outlineVariant.withValues(alpha: 0.6),
                          width: 0.6,
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildActivityFilterTab('All', DashboardTxFilter.all),
                          _buildActivityFilterTab(
                            'Expenses',
                            DashboardTxFilter.expense,
                          ),
                          _buildActivityFilterTab(
                            'Income',
                            DashboardTxFilter.income,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppTheme.outlineVariant),
              if (filteredTxs.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 28,
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLow,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _activityFilter == DashboardTxFilter.income
                              ? CupertinoIcons.arrow_down_circle
                              : _activityFilter == DashboardTxFilter.expense
                              ? CupertinoIcons.arrow_up_circle
                              : CupertinoIcons.tray,
                          size: 22,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No ${_activityFilter == DashboardTxFilter.all
                            ? 'Transactions'
                            : _activityFilter == DashboardTxFilter.expense
                            ? 'Expenses'
                            : 'Income'} in $monthName',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'No transactions found for this filter in $monthName.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: [
                    ...latestTxs.asMap().entries.map((entry) {
                      final tx = entry.value;
                      final isDebit = tx.type == TransactionType.debit;
                      final isLast = entry.key == latestTxs.length - 1;

                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isDebit
                                        ? AppTheme.coral.withValues(alpha: 0.12)
                                        : AppTheme.mint.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _getCategoryIcon(tx.category),
                                    size: 18,
                                    color: isDebit
                                        ? AppTheme.coral
                                        : AppTheme.primaryDark,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tx.note != null && tx.note!.isNotEmpty
                                            ? tx.note!
                                            : tx.category,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.onSurface,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${_getDateLabel(tx.dateAD)} • ${tx.category}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          color: AppTheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${isDebit ? '-' : '+'}${CurrencyHelper.symbol}${CurrencyHelper.format(tx.amount)}',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isDebit
                                        ? AppTheme.onSurface
                                        : AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isLast)
                            const Divider(
                              height: 0.8,
                              indent: 68,
                              endIndent: 16,
                              color: AppTheme.outlineVariant,
                            ),
                        ],
                      );
                    }),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActivityFilterTab(String label, DashboardTxFilter filter) {
    final isSelected = _activityFilter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _activityFilter = filter);
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.pillRadius),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppTheme.onSurface
                    : AppTheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getDateLabel(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    return DateFormat('d MMM, yyyy').format(date);
  }

  IconData _getCategoryIcon(String category) {
    return switch (category) {
      'Food & Dining' || 'Groceries' => CupertinoIcons.cart,
      'Transport' => CupertinoIcons.car_detailed,
      'Shopping' || 'Clothes and Shoes' => CupertinoIcons.bag,
      'Utilities' => CupertinoIcons.bolt,
      'Health' || 'Sport' => CupertinoIcons.sportscourt,
      'Education' => CupertinoIcons.book,
      'Salary / Income' => CupertinoIcons.money_dollar_circle,
      'Cafes and Restaurants' => Icons.local_cafe_rounded,
      _ => CupertinoIcons.doc_text,
    };
  }
}

/// Category Bento Card matching image.png with real amount and icon
class _CategoryBentoCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;

  const _CategoryBentoCard({
    required this.title,
    required this.amount,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final formatted = CurrencyHelper.format(amount);
    String intPart = formatted;
    String decPart = '';
    if (formatted.contains('.')) {
      final parts = formatted.split('.');
      intPart = parts[0];
      decPart = '.${parts[1]}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppTheme.outlineVariant.withValues(alpha: 0.6),
          width: 0.8,
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                icon,
                size: 16,
                color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${CurrencyHelper.symbol}$intPart',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: AppTheme.onSurface,
                ),
              ),
              if (decPart.isNotEmpty)
                Text(
                  decPart,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurfaceVariant.withValues(alpha: 0.75),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroSegmentTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _HeroSegmentTab({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withValues(alpha: 0.28)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isActive
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for the smooth bezier wave chart based on real past/surrounding months points
class _HeroWaveChartPainter extends CustomPainter {
  final List<double> points;
  final bool isIncome;
  final int selectedIndex;

  _HeroWaveChartPainter({
    required this.points,
    required this.isIncome,
    this.selectedIndex = 2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    final path = Path();
    final fillPath = Path();

    // Check if any point is non-zero
    final maxVal = points.fold(0.0, (m, v) => math.max(m, v));
    final count = points.length;
    final validIndex = selectedIndex.clamp(0, count - 1);
    final stepX = count > 1 ? width / (count - 1) : width / 2;
    final dotX = validIndex * stepX;
    double dotY;

    if (maxVal <= 0) {
      // Baseline wave when user has 0 transactions
      final List<Offset> baseline = [];
      for (int i = 0; i < count; i++) {
        final x = i * stepX;
        final waveOffset = (i == 1 || i == 3) ? -3.0 : (i == 2 ? 0.0 : 3.0);
        baseline.add(Offset(x, height * 0.75 + waveOffset));
      }
      path.moveTo(baseline.first.dx, baseline.first.dy);
      for (int i = 0; i < baseline.length - 1; i++) {
        final p0 = baseline[i];
        final p1 = baseline[i + 1];
        final midX = (p0.dx + p1.dx) / 2;
        path.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
      }
      dotY = baseline[validIndex].dy;
    } else {
      // Normalize values between top margin (0.46 * height) and bottom margin (0.85 * height)
      // so peak wave stays comfortably beneath top popup card
      final List<Offset> normalized = [];
      for (int i = 0; i < count; i++) {
        final x = i * stepX;
        final ratio = (points[i] / maxVal).clamp(0.0, 1.0);
        final y = height * 0.85 - ratio * (height * 0.38);
        normalized.add(Offset(x, y));
      }

      path.moveTo(normalized.first.dx, normalized.first.dy);
      for (int i = 0; i < normalized.length - 1; i++) {
        final p0 = normalized[i];
        final p1 = normalized[i + 1];
        final midX = (p0.dx + p1.dx) / 2;
        path.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
      }
      dotY = normalized[validIndex].dy;
    }

    // Fill path underneath the curve
    fillPath.addPath(path, Offset.zero);
    fillPath.lineTo(width, height);
    fillPath.lineTo(0, height);
    fillPath.close();

    // Gradient fill beneath curve
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.white.withValues(alpha: 0.22),
        Colors.white.withValues(alpha: 0.0),
      ],
    );

    final fillPaint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, width, height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Stroke line
    final linePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);

    // Draw dashed vertical indicator line starting beneath tooltip down to bottom
    final dashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    const topDashStart = 56.0;
    double startY = math.min(topDashStart, dotY - 8);
    while (startY < height) {
      if ((startY - dotY).abs() > 7) {
        canvas.drawLine(
          Offset(dotX, startY),
          Offset(dotX, math.min(startY + 4, height)),
          dashPaint,
        );
      }
      startY += 8;
    }

    // Outer glow dot
    canvas.drawCircle(
      Offset(dotX, dotY),
      6.5,
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );
    // Inner white dot
    canvas.drawCircle(Offset(dotX, dotY), 3.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _HeroWaveChartPainter oldDelegate) => true;
}
