part of 'dashboard_imports.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DateTime _selectedMonth = DateTime.now();
  bool _isBS = true;
  String _userName = 'User';
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _userName = prefs.getString('userName') ?? user.displayName ?? 'User';
        _photoUrl = user.photoURL;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () async {
          context.read<TransactionBloc>().add(TransactionLoadRequested());
          context.read<GoalBloc>().add(GoalLoadRequested());
          await _loadUserProfile();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreetingsSection(context),
              const SizedBox(height: 16),
              _buildBalanceOverview(context),
              const SizedBox(height: 20),
              _buildRecentTransactions(context),
              const SizedBox(height: 20),
              _buildSpendingByCategory(context),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        heroTag: 'dashboard_fab',
        backgroundColor: AppTheme.secondary,
        foregroundColor: AppTheme.onSecondary,
        shape: const CircleBorder(),
        elevation: 4,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<TransactionBloc>(),
              child: const AddTransactionScreen(),
            ),
          ),
        ),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        decoration: const BoxDecoration(color: AppTheme.surface),
      ),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.outline, width: 1),
            ),
            child: ClipOval(
              child: _photoUrl != null && _photoUrl!.isNotEmpty
                  ? Image.network(
                      _photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppTheme.primaryContainer,
                          child: const Icon(
                            Icons.person,
                            color: AppTheme.onPrimaryContainer,
                            size: 20,
                          ),
                        );
                      },
                    )
                  : Container(
                      color: AppTheme.primaryContainer,
                      child: const Icon(
                        Icons.person,
                        color: AppTheme.onPrimaryContainer,
                        size: 20,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Sajilo Khata',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              color: AppTheme.onSurfaceVariant,
              onPressed: () {},
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.error,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGreetingsSection(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Namaste, $_userName',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Financial Summary',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              _ToggleButton(
                label: 'BS',
                isActive: _isBS,
                onTap: () => setState(() => _isBS = true),
              ),
              _ToggleButton(
                label: 'AD',
                isActive: !_isBS,
                onTap: () => setState(() => _isBS = false),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceOverview(BuildContext context) {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        double income = 0;
        double expense = 0;

        if (state is TransactionLoaded) {
          final monthTxs = state.getTransactionsForMonth(_selectedMonth);
          income = monthTxs
              .where((tx) => tx.type == TransactionType.credit)
              .fold(0.0, (sum, tx) => sum + tx.amount);
          expense = monthTxs
              .where((tx) => tx.type == TransactionType.debit)
              .fold(0.0, (sum, tx) => sum + tx.amount);
        }

        final net = income - expense;
        final savingsPercent = income > 0
            ? ((income - expense) / income * 100)
            : 0;

        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.outlineVariant, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NET BALANCE',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: AppTheme.onSurfaceVariant,
                                  letterSpacing: 0.05,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${CurrencyHelper.symbol} ${CurrencyHelper.format(net.abs())}',
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                              letterSpacing: -0.02,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          color: AppTheme.onPrimaryContainer,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.only(top: 16),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: AppTheme.outlineVariant,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.arrow_upward,
                                    size: 16,
                                    color: AppTheme.secondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'MONTHLY INCOME',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: AppTheme.secondary,
                                          letterSpacing: 0.05,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${CurrencyHelper.symbol} ${CurrencyHelper.format(income)}',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontFamily: 'JetBrains Mono',
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.secondary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.arrow_downward,
                                    size: 16,
                                    color: AppTheme.onTertiaryContainer,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'MONTHLY EXPENSES',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: AppTheme.onTertiaryContainer,
                                          letterSpacing: 0.05,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${CurrencyHelper.symbol} ${CurrencyHelper.format(expense)}',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontFamily: 'JetBrains Mono',
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.onTertiaryContainer,
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
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.outlineVariant, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 80,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        _MiniBar(
                          height: 32,
                          color: AppTheme.secondaryContainer,
                        ),
                        SizedBox(width: 8),
                        _MiniBar(
                          height: 52,
                          color: AppTheme.secondaryContainer,
                        ),
                        SizedBox(width: 8),
                        _MiniBar(
                          height: 40,
                          color: AppTheme.secondaryContainer,
                        ),
                        SizedBox(width: 8),
                        _MiniBar(height: 72, color: AppTheme.primary),
                        SizedBox(width: 8),
                        _MiniBar(
                          height: 60,
                          color: AppTheme.secondaryContainer,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Growth Insight',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your savings increased by ${savingsPercent.toStringAsFixed(0)}% compared to last month.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final homeState = context
                            .findAncestorStateOfType<State>();
                        if (homeState != null) {
                          (homeState as dynamic).onTabTapped(1);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: AppTheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'View Full Report',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentTransactions(BuildContext context) {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        if (state is! TransactionLoaded) return const SizedBox.shrink();

        final transactions = state.transactions;
        if (transactions.isEmpty) return const SizedBox.shrink();

        final recentTxs = List<Transaction>.from(transactions)
          ..sort((a, b) => b.dateAD.compareTo(a.dateAD));
        final latestTxs = recentTxs.take(5).toList();

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.outlineVariant, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Transactions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BlocProvider.value(
                            value: context.read<TransactionBloc>(),
                            child: const TransactionListScreen(),
                          ),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'View All',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppTheme.outlineVariant),
              ...latestTxs.asMap().entries.map((entry) {
                final tx = entry.value;
                final isDebit = tx.type == TransactionType.debit;
                final isLast = entry.key == latestTxs.length - 1;

                return Column(
                  children: [
                    Container(
                      color: AppTheme.surfaceContainerLowest,
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              width: 4,
                              color: isDebit
                                  ? AppTheme.error
                                  : AppTheme.secondary,
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: isDebit
                                            ? AppTheme.errorContainer
                                                  .withValues(alpha: 0.3)
                                            : AppTheme.secondaryContainer
                                                  .withValues(alpha: 0.3),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _getCategoryIcon(tx.category),
                                        size: 20,
                                        color: isDebit
                                            ? AppTheme.onTertiaryContainer
                                            : AppTheme.secondary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            tx.note ?? tx.category,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.onSurface,
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${_getDateLabel(tx.dateAD)} • ${tx.category}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color:
                                                      AppTheme.onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '${isDebit ? '-' : '+'} ${CurrencyHelper.symbol} ${CurrencyHelper.format(tx.amount)}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                fontFamily: 'JetBrains Mono',
                                                fontWeight: FontWeight.w700,
                                                color: isDebit
                                                    ? AppTheme
                                                          .onTertiaryContainer
                                                    : AppTheme.secondary,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isDebit
                                                ? AppTheme.errorContainer
                                                : AppTheme.secondaryContainer,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            isDebit ? 'SPENT' : 'RECEIVED',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  color: isDebit
                                                      ? AppTheme
                                                            .onErrorContainer
                                                      : AppTheme
                                                            .onSecondaryContainer,
                                                  letterSpacing: 0.05,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!isLast)
                      const Divider(
                        height: 1,
                        indent: 56,
                        color: AppTheme.outlineVariant,
                      ),
                  ],
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSpendingByCategory(BuildContext context) {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        if (state is! TransactionLoaded) return const SizedBox.shrink();

        final monthTxs = state.getTransactionsForMonth(_selectedMonth);
        final categoryTotals = <String, double>{};

        for (final tx in monthTxs.where(
          (tx) => tx.type == TransactionType.debit,
        )) {
          categoryTotals[tx.category] =
              (categoryTotals[tx.category] ?? 0) + tx.amount;
        }

        if (categoryTotals.isEmpty) {
          return const SizedBox.shrink();
        }

        final totalExpense = categoryTotals.values.fold(0.0, (a, b) => a + b);
        final sortedCategories = categoryTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final topCategories = sortedCategories.take(3).toList();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.outlineVariant, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Spending by Category',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: SizedBox(
                  width: 160,
                  height: 100,
                  child: CustomPaint(
                    painter: _SemiCircleChartPainter(
                      categories: topCategories,
                      total: totalExpense,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Total Spent',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppTheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        Text(
                          '${CurrencyHelper.symbol} ${(totalExpense / 1000).toStringAsFixed(1)}k',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ...topCategories.map((entry) {
                final percent = (entry.value / totalExpense) * 100;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getCategoryColor(entry.key),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.key,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.onSurface),
                        ),
                      ),
                      Text(
                        '${percent.toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'JetBrains Mono',
                          color: AppTheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
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
      'Food & Dining' => Icons.restaurant,
      'Transport' => Icons.directions_car,
      'Shopping' => Icons.shopping_cart,
      'Utilities' => Icons.electric_bolt,
      'Health' => Icons.health_and_safety,
      'Education' => Icons.school,
      'Remittance / Transfer' => Icons.send,
      'Salary / Income' => Icons.payments,
      'Savings' => Icons.savings,
      'Entertainment' => Icons.movie,
      'Groceries' => Icons.local_grocery_store,
      _ => Icons.receipt,
    };
  }

  Color _getCategoryColor(String category) {
    final colors = {
      'Food & Dining': AppTheme.primaryContainer,
      'Transport': AppTheme.secondary,
      'Shopping': AppTheme.secondaryContainer,
      'Utilities': AppTheme.onTertiaryContainer,
      'Health': AppTheme.error,
      'Education': AppTheme.primary,
      'Remittance / Transfer': AppTheme.onSurfaceVariant,
      'Salary / Income': AppTheme.secondary,
      'Savings': AppTheme.secondaryFixedDim,
      'Entertainment': AppTheme.onSurfaceVariant,
      'Groceries': AppTheme.outline,
    };
    return colors[category] ?? AppTheme.outlineVariant;
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.surfaceContainerLowest
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: isActive ? AppTheme.primary : AppTheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _MiniBar extends StatelessWidget {
  final double height;
  final Color color;

  const _MiniBar({required this.height, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      ),
    );
  }
}

class _SemiCircleChartPainter extends CustomPainter {
  final List<MapEntry<String, double>> categories;
  final double total;

  _SemiCircleChartPainter({required this.categories, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2;
    const strokeWidth = 20.0;

    final bgPaint = Paint()
      ..color = AppTheme.surfaceContainer
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.14159,
      3.14159,
      false,
      bgPaint,
    );

    double startAngle = 3.14159;
    final colors = [
      AppTheme.primaryContainer,
      AppTheme.secondary,
      AppTheme.onTertiaryContainer,
    ];

    for (int i = 0; i < categories.length && i < 3; i++) {
      final sweepAngle = (categories[i].value / total) * 3.14159;
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
