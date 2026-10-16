part of 'transactions_imports.dart';

enum TransactionFilterBy { all, expense, income }

class DateSpan {
  final DateTime from;
  final DateTime to;
  DateSpan({required this.from, required this.to});
}

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  TransactionFilterBy _currentFilter = TransactionFilterBy.all;
  DateSpan? _dateFilter;
  String? _selectedCategory;
  bool _initialized = false;

  static const _categories = [
    'Food & Dining',
    'Transport',
    'Shopping',
    'Utilities',
    'Health',
    'Education',
    'Remittance / Transfer',
    'Salary / Income',
    'Savings',
    'Entertainment',
    'Groceries',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _currentFilter = TransactionFilterBy.all;
    _dateFilter = null;
    _selectedCategory = null;
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      _initialized = true;
      _currentFilter = TransactionFilterBy.all;
      _dateFilter = null;
    }

    final user = FirebaseAuth.instance.currentUser;
    final photoUrl = user?.photoURL;
    final name = user?.displayName ?? user?.email ?? 'U';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

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
                          child: photoUrl != null && photoUrl.isNotEmpty
                              ? Image.network(
                                  photoUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildAvatarFallback(initial),
                                )
                              : _buildAvatarFallback(initial),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Ledger',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      PopupMenuButton<String>(
                        icon: const Icon(
                          CupertinoIcons.ellipsis_circle,
                          size: 22,
                        ),
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 10,
                        onSelected: (value) {
                          HapticFeedback.selectionClick();
                          switch (value) {
                            case 'export_all':
                              _exportTransactions(context, null);
                            case 'export_expense':
                              _exportTransactions(
                                context,
                                TransactionType.debit,
                              );
                            case 'export_income':
                              _exportTransactions(
                                context,
                                TransactionType.credit,
                              );
                          }
                        },
                        itemBuilder: (context) => [
                          _menuItem(
                            'export_all',
                            CupertinoIcons.arrow_down_doc,
                            'Export All (CSV)',
                          ),
                          _menuItem(
                            'export_expense',
                            CupertinoIcons.arrow_down_circle,
                            'Export Expenses',
                          ),
                          _menuItem(
                            'export_income',
                            CupertinoIcons.arrow_up_circle,
                            'Export Income',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: BlocBuilder<TransactionBloc, TransactionState>(
        builder: (context, state) {
          if (state is TransactionLoading) {
            return const Center(child: CupertinoActivityIndicator(radius: 14));
          }
          if (state is TransactionError) {
            return _buildError(context, state.message);
          }
          if (state is TransactionLoaded) {
            final filteredTransactions = _filterTransactions(
              state.transactions,
            );
            return Column(
              children: [
                // iOS Segmented Type Selector
                _buildIosSegmentedFilter(),
                // Filter chips (Date Range & Category)
                _buildQuickFiltersRow(),
                // Summary Cards
                _buildSummaryCards(filteredTransactions),
                const SizedBox(height: 8),
                // Transaction List
                Expanded(
                  child: filteredTransactions.isEmpty
                      ? _buildEmpty(context)
                      : _buildTransactionList(filteredTransactions),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 74),
        child: FloatingActionButton(
          heroTag: 'transaction_fab',
          backgroundColor: AppTheme.secondary,
          foregroundColor: Colors.white,
          elevation: 6,
          shape: const CircleBorder(),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<TransactionBloc>(),
                  child: const AddTransactionScreen(),
                ),
              ),
            );
          },
          child: const Icon(CupertinoIcons.plus, size: 24),
        ),
      ),
    );
  }

  Widget _buildAvatarFallback(String initial) {
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

  Widget _buildIosSegmentedFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppTheme.pillRadius),
          border: Border.all(color: AppTheme.outlineVariant, width: 0.8),
        ),
        child: Row(
          children: [
            _segmentTab('All', TransactionFilterBy.all),
            _segmentTab('Expenses', TransactionFilterBy.expense),
            _segmentTab('Income', TransactionFilterBy.income),
          ],
        ),
      ),
    );
  }

  Widget _segmentTab(String label, TransactionFilterBy filter) {
    final isSelected = _currentFilter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _currentFilter = filter);
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 7),
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
                fontSize: 13,
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

  Widget _buildQuickFiltersRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _IosFilterChip(
            icon: CupertinoIcons.calendar,
            label: _dateFilter != null
                ? '${DateFormat('MMM dd').format(_dateFilter!.from)} - ${DateFormat('MMM dd').format(_dateFilter!.to)}'
                : 'Date Range',
            isActive: _dateFilter != null,
            onTap: () => _showDateRangePicker(context),
            onClear: _dateFilter != null
                ? () {
                    HapticFeedback.selectionClick();
                    setState(() => _dateFilter = null);
                  }
                : null,
          ),
          const SizedBox(width: 8),
          _IosFilterChip(
            icon: CupertinoIcons.tag,
            label: _selectedCategory ?? 'Category',
            isActive: _selectedCategory != null,
            onTap: () => _showCategoryFilter(context),
            onClear: _selectedCategory != null
                ? () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedCategory = null);
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(List<Transaction> transactions) {
    double income = 0;
    double expense = 0;
    for (final tx in transactions) {
      if (tx.type == TransactionType.credit) {
        income += tx.amount;
      } else {
        expense += tx.amount;
      }
    }
    final net = income - expense;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6B8F62), Color(0xFF5A7853), Color(0xFF45633E)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppTheme.dashboardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'NET LEDGER BALANCE',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${transactions.length} entries',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${net >= 0 ? '' : '-'}${CurrencyHelper.symbol}${CurrencyHelper.format(net.abs())}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.arrow_down_left,
                          size: 14,
                          color: AppTheme.mintAccent,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TOTAL INCOME',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '${CurrencyHelper.symbol}${CurrencyHelper.format(income)}',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.arrow_up_right,
                          size: 14,
                          color: Color(0xFFFFD5D0),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TOTAL EXPENSES',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '${CurrencyHelper.symbol}${CurrencyHelper.format(expense)}',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFFFD5D0),
                              ),
                            ),
                          ],
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
    );
  }

  Widget _buildTransactionList(List<Transaction> transactions) {
    final grouped = _groupByDate(transactions);
    final labels = grouped.keys.toList();

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 6, bottom: 120),
      itemCount: labels.length,
      itemBuilder: (context, index) {
        final label = labels[index];
        final txs = grouped[label]!;

        double groupTotal = 0;
        for (final tx in txs) {
          if (tx.type == TransactionType.debit) {
            groupTotal -= tx.amount;
          } else {
            groupTotal += tx.amount;
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '${groupTotal >= 0 ? '+' : ''}${CurrencyHelper.symbol}${CurrencyHelper.format(groupTotal.abs())}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: groupTotal >= 0
                          ? AppTheme.income
                          : AppTheme.expense,
                    ),
                  ),
                ],
              ),
            ),
            ...txs.map(
              (tx) => TransactionTile(
                transaction: tx,
                onTap: () => _showTransactionDetails(context, tx),
                onDelete: () => _confirmDelete(context, tx),
              ),
            ),
          ],
        );
      },
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                CupertinoIcons.doc_plaintext,
                size: 32,
                color: AppTheme.outline,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Transactions Found',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add a transaction manually or wait\nfor automatic SMS tracking.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                height: 1.4,
                color: AppTheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.errorContainer,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                CupertinoIcons.exclamationmark_triangle,
                size: 32,
                color: AppTheme.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppTheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.read<TransactionBloc>().add(
                TransactionLoadRequested(),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDateRangePicker(BuildContext context) async {
    HapticFeedback.selectionClick();
    final from = await showDatePicker(
      context: context,
      initialDate: _dateFilter?.from ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              onSurface: AppTheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (from != null && context.mounted) {
      final to = await showDatePicker(
        context: context,
        initialDate: _dateFilter?.to ?? DateTime.now(),
        firstDate: from,
        lastDate: DateTime.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppTheme.primary,
                onPrimary: Colors.white,
                onSurface: AppTheme.onSurface,
              ),
            ),
            child: child!,
          );
        },
      );
      if (to != null) {
        setState(() {
          _dateFilter = DateSpan(from: from, to: to);
        });
      }
    }
  }

  void _showCategoryFilter(BuildContext context) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      showDragHandle: false,
      sheetAnimationStyle: appSheetAnimationStyle,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.sheetRadius),
        ),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4.5,
                  margin: const EdgeInsets.only(bottom: 16),
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
                    'Filter by Category',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  if (_selectedCategory != null)
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        setState(() => _selectedCategory = null);
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Clear',
                        style: TextStyle(color: AppTheme.primary),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _categories.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, color: AppTheme.outlineVariant),
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = _selectedCategory == category;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      title: Text(
                        category,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.onSurface,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              CupertinoIcons.checkmark_alt,
                              color: AppTheme.primary,
                            )
                          : null,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedCategory = category);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Transaction> _filterTransactions(List<Transaction> transactions) {
    var filtered = transactions;
    switch (_currentFilter) {
      case TransactionFilterBy.all:
        break;
      case TransactionFilterBy.expense:
        filtered = filtered
            .where((tx) => tx.type == TransactionType.debit)
            .toList();
      case TransactionFilterBy.income:
        filtered = filtered
            .where((tx) => tx.type == TransactionType.credit)
            .toList();
    }
    if (_selectedCategory != null) {
      filtered = filtered
          .where((tx) => tx.category == _selectedCategory)
          .toList();
    }
    if (_dateFilter != null) {
      final fromStart = DateTime(
        _dateFilter!.from.year,
        _dateFilter!.from.month,
        _dateFilter!.from.day,
      );
      final toEnd = DateTime(
        _dateFilter!.to.year,
        _dateFilter!.to.month,
        _dateFilter!.to.day,
        23,
        59,
        59,
      );
      filtered = filtered.where((tx) {
        return tx.dateAD.isAfter(fromStart.subtract(const Duration(days: 1))) &&
            tx.dateAD.isBefore(toEnd.add(const Duration(days: 1)));
      }).toList();
    }
    return filtered;
  }

  Map<String, List<Transaction>> _groupByDate(List<Transaction> transactions) {
    final grouped = <String, List<Transaction>>{};
    for (final tx in transactions) {
      final date = tx.dateAD;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final txDate = DateTime(date.year, date.month, date.day);
      String label;
      if (txDate == today) {
        label = 'Today';
      } else if (txDate == yesterday) {
        label = 'Yesterday';
      } else if (date.year == now.year) {
        label = DateFormat('MMMM dd').format(date);
      } else {
        label = DateFormat('MMMM dd, yyyy').format(date);
      }
      grouped.putIfAbsent(label, () => []).add(tx);
    }
    return grouped;
  }

  void _showTransactionDetails(BuildContext context, Transaction tx) {
    final dateFormat = DateFormat('MMMM dd, yyyy');
    final outerBloc = context.read<TransactionBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      sheetAnimationStyle: appSheetAnimationStyle,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.sheetRadius),
        ),
      ),
      builder: (sheetContext) => BlocProvider.value(
        value: outerBloc,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: tx.type == TransactionType.debit
                            ? AppTheme.tertiaryContainer
                            : AppTheme.mint,
                        borderRadius: BorderRadius.circular(
                          AppTheme.squircleRadius,
                        ),
                      ),
                      child: Icon(
                        tx.type == TransactionType.debit
                            ? CupertinoIcons.arrow_down_right
                            : CupertinoIcons.arrow_up_right,
                        color: tx.type == TransactionType.debit
                            ? AppTheme.expense
                            : AppTheme.income,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${tx.type == TransactionType.debit ? '-' : '+'}${CurrencyHelper.symbol}${CurrencyHelper.format(tx.amount)}',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: tx.type == TransactionType.debit
                                  ? AppTheme.expense
                                  : AppTheme.income,
                            ),
                          ),
                          Text(
                            tx.type == TransactionType.debit
                                ? 'Expense'
                                : 'Income',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _detailRow('Category', tx.category),
                if (tx.bank != null && tx.bank!.isNotEmpty)
                  _detailRow('Bank / Account', tx.bank!),
                if (tx.note != null && tx.note!.isNotEmpty)
                  _detailRow('Note', tx.note!),
                _detailRow('Date', dateFormat.format(tx.dateAD)),
                _detailRow(
                  'Source',
                  tx.source == TransactionSource.sms
                      ? 'SMS Automatic'
                      : 'Manual Entry',
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          Navigator.push(
                            sheetContext,
                            CupertinoPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: outerBloc,
                                child: AddTransactionScreen(transaction: tx),
                              ),
                            ),
                          );
                        },
                        icon: const Icon(CupertinoIcons.pencil, size: 16),
                        label: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _confirmDelete(sheetContext, tx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.error,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(CupertinoIcons.trash, size: 16),
                        label: const Text('Delete'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext ctx, Transaction tx) {
    final bloc = ctx.read<TransactionBloc>();
    showSmoothDialog(
      context: ctx,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Delete Transaction'),
        content: Text(
          'Are you sure you want to delete this ${tx.type == TransactionType.debit ? 'expense' : 'income'} of ${CurrencyHelper.symbol}${CurrencyHelper.format(tx.amount)}?',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              bloc.add(TransactionDeleteRequested(id: tx.id));
              Navigator.pop(dialogContext);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportTransactions(
    BuildContext context,
    TransactionType? filter,
  ) async {
    final state = context.read<TransactionBloc>().state;
    if (state is! TransactionLoaded || state.transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No transactions to export')),
      );
      return;
    }
    final filteredTransactions = filter == null
        ? state.transactions
        : state.transactions.where((tx) => tx.type == filter).toList();
    if (filteredTransactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No ${filter == TransactionType.debit ? 'expenses' : 'income'} to export',
          ),
        ),
      );
      return;
    }
    final buffer = StringBuffer();
    final typeLabel = filter == null
        ? 'All'
        : filter == TransactionType.debit
        ? 'Expenses'
        : 'Income';
    buffer.writeln('Date,Type,Amount,Category,Bank,Note,Source');
    for (final tx in filteredTransactions) {
      final date = DateFormat('yyyy-MM-dd').format(tx.dateAD);
      final type = tx.type == TransactionType.debit ? 'Expense' : 'Income';
      final category = tx.category.replaceAll(',', ';');
      final bank = (tx.bank ?? '').replaceAll(',', ';');
      final note = (tx.note ?? '').replaceAll(',', ';');
      final source = tx.source == TransactionSource.sms ? 'SMS' : 'Manual';
      buffer.writeln('$date,$type,${tx.amount},$category,$bank,$note,$source');
    }
    try {
      final directory = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd').format(DateTime.now());
      final fileName = 'sajilo_khata_${typeLabel.toLowerCase()}_$timestamp.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(buffer.toString());
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Sajilo Khata $typeLabel Export');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }
}

class _IosFilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _IosFilterChip({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.mint : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.pillRadius),
          border: Border.all(
            color: isActive ? AppTheme.primary : AppTheme.outlineVariant,
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive
                  ? AppTheme.primaryDark
                  : AppTheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                color: isActive ? AppTheme.primaryDark : AppTheme.onSurface,
              ),
            ),
            if (onClear != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onClear,
                child: const Icon(
                  CupertinoIcons.xmark_circle_fill,
                  size: 14,
                  color: AppTheme.primaryDark,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
