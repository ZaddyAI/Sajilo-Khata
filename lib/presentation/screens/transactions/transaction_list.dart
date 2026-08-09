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
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.outlineVariant),
        ),
        titleSpacing: 16,
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
                child: photoUrl != null && photoUrl.isNotEmpty
                    ? Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppTheme.primaryContainer,
                            child: Center(
                              child: Text(
                                initial,
                                style: GoogleFonts.manrope(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: AppTheme.primaryContainer,
                        child: Center(
                          child: Text(
                            initial,
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Sajilo Khata',
              style: GoogleFonts.manrope(
                fontSize: 24,
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
                icon: const Icon(Icons.notifications_outlined, size: 24),
                color: AppTheme.onSurfaceVariant,
                onPressed: () {},
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppTheme.error,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.surface, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 8,
            onSelected: (value) {
              switch (value) {
                case 'export_all':
                  _exportTransactions(context, null);
                case 'export_expense':
                  _exportTransactions(context, TransactionType.debit);
                case 'export_income':
                  _exportTransactions(context, TransactionType.credit);
              }
            },
            itemBuilder: (context) => [
              _menuItem(
                'export_all',
                Icons.download_outlined,
                'Export All CSV',
              ),
              _menuItem(
                'export_expense',
                Icons.arrow_downward_rounded,
                'Expenses Only',
              ),
              _menuItem(
                'export_income',
                Icons.arrow_upward_rounded,
                'Income Only',
              ),
            ],
          ),
        ],
      ),
      body: BlocBuilder<TransactionBloc, TransactionState>(
        builder: (context, state) {
          if (state is TransactionLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
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
                // Inline Filter Chips
                _buildFilterChips(),
                // Summary Cards
                _buildSummaryCards(filteredTransactions),
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
      floatingActionButton: FloatingActionButton(
        heroTag: 'transaction_fab',
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

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _InlineFilterChip(
            icon: Icons.calendar_month,
            label: _dateFilter != null
                ? '${DateFormat('MMM dd').format(_dateFilter!.from)} - ${DateFormat('MMM dd').format(_dateFilter!.to)}'
                : 'Date Range',
            hasDropdown: true,
            onTap: () => _showDateRangePicker(context),
            isActive: _dateFilter != null,
          ),
          const SizedBox(width: 8),
          _InlineFilterChip(
            icon: Icons.category,
            label: _selectedCategory ?? 'Category',
            hasDropdown: true,
            onTap: () => _showCategoryFilter(context),
            isActive: _selectedCategory != null,
          ),
          const SizedBox(width: 8),
          _InlineFilterChip(
            icon: Icons.filter_list,
            label: _currentFilter == TransactionFilterBy.all
                ? 'All Types'
                : _currentFilter == TransactionFilterBy.expense
                ? 'Expenses'
                : 'Income',
            hasDropdown: true,
            onTap: () => _showTypeFilter(context),
            isActive: _currentFilter != TransactionFilterBy.all,
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
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              label: 'Current Balance',
              amount: net,
              isPositive: net >= 0,
              icon: Icons.account_balance_wallet,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SummaryCard(
              label: 'Income',
              amount: income,
              isPositive: true,
              icon: Icons.arrow_upward,
              color: AppTheme.secondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SummaryCard(
              label: 'Expenses',
              amount: expense,
              isPositive: false,
              icon: Icons.arrow_downward,
              color: AppTheme.onTertiaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(List<Transaction> transactions) {
    final grouped = _groupByDate(transactions);
    final labels = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 120),
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                  Text(
                    '${groupTotal >= 0 ? '+' : ''}${CurrencyHelper.symbol}${CurrencyHelper.format(groupTotal.abs())}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: groupTotal >= 0
                          ? AppTheme.secondary
                          : AppTheme.onTertiaryContainer,
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
          Text(label),
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
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 36,
                color: AppTheme.outlineVariant,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No transactions yet',
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add a transaction manually or\nwait for an SMS to be parsed',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
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
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.errorContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 36,
                color: AppTheme.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Something went wrong',
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppTheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
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
    final from = await showDatePicker(
      context: context,
      initialDate: _dateFilter?.from ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (from != null && context.mounted) {
      final to = await showDatePicker(
        context: context,
        initialDate: _dateFilter?.to ?? DateTime.now(),
        firstDate: from,
        lastDate: DateTime.now(),
      );
      if (to != null) {
        setState(() {
          _dateFilter = DateSpan(from: from, to: to);
        });
      }
    }
  }

  void _showTypeFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Filter by Type',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            _FilterOption(
              label: 'All',
              icon: Icons.all_inclusive,
              isSelected: _currentFilter == TransactionFilterBy.all,
              onTap: () {
                setState(() => _currentFilter = TransactionFilterBy.all);
                Navigator.pop(context);
              },
            ),
            _FilterOption(
              label: 'Expenses',
              icon: Icons.arrow_downward,
              isSelected: _currentFilter == TransactionFilterBy.expense,
              onTap: () {
                setState(() => _currentFilter = TransactionFilterBy.expense);
                Navigator.pop(context);
              },
            ),
            _FilterOption(
              label: 'Income',
              icon: Icons.arrow_upward,
              isSelected: _currentFilter == TransactionFilterBy.income,
              onTap: () {
                setState(() => _currentFilter = TransactionFilterBy.income);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter by Category',
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurface,
                  ),
                ),
                if (_selectedCategory != null)
                  TextButton(
                    onPressed: () {
                      setState(() => _selectedCategory = null);
                      Navigator.pop(context);
                    },
                    child: const Text('Clear'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category;
                  return ListTile(
                    leading: Icon(
                      _getCategoryIcon(category),
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.onSurfaceVariant,
                    ),
                    title: Text(
                      category,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.onSurface,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: AppTheme.primary)
                        : null,
                    onTap: () {
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
    );
  }

  IconData _getCategoryIcon(String category) {
    return switch (category) {
      'Food & Dining' => Icons.restaurant,
      'Transport' => Icons.directions_car,
      'Shopping' => Icons.shopping_bag,
      'Utilities' => Icons.bolt,
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
      builder: (sheetContext) => BlocProvider.value(
        value: outerBloc,
        child: Builder(
          builder: (sheetContext) {
            final isDebit = tx.type == TransactionType.debit;
            final color = isDebit ? AppTheme.tertiary : AppTheme.secondary;
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isDebit
                              ? Icons.south_west_rounded
                              : Icons.north_east_rounded,
                          color: color,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${isDebit ? '' : '+'}${CurrencyHelper.symbol}${CurrencyHelper.format(tx.amount)}',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                            Text(
                              isDebit ? 'Expense' : 'Income',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: AppTheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _detailRow(sheetContext, 'Category', tx.category),
                  if (tx.bank != null)
                    _detailRow(sheetContext, 'Bank / Wallet', tx.bank!),
                  if (tx.note != null && tx.note!.isNotEmpty)
                    _detailRow(sheetContext, 'Note', tx.note!),
                  _detailRow(
                    sheetContext,
                    'Date',
                    dateFormat.format(tx.dateAD),
                  ),
                  if (tx.dateBS.isNotEmpty)
                    _detailRow(sheetContext, 'Date (BS)', tx.dateBS),
                  _detailRow(
                    sheetContext,
                    'Source',
                    tx.source == TransactionSource.sms ? 'SMS' : 'Manual',
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            Navigator.push(
                              sheetContext,
                              MaterialPageRoute(
                                builder: (_) => BlocProvider.value(
                                  value: outerBloc,
                                  child: AddTransactionScreen(transaction: tx),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Edit'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _confirmDelete(sheetContext, tx),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.error,
                            foregroundColor: AppTheme.onError,
                          ),
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                          ),
                          label: const Text('Delete'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
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
    showDialog(
      context: ctx,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text(
          'Delete this ${tx.type == TransactionType.debit ? 'expense' : 'income'} of ${CurrencyHelper.symbol}${CurrencyHelper.format(tx.amount)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              bloc.add(TransactionDeleteRequested(id: tx.id));
              Navigator.pop(dialogContext);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
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

class _InlineFilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool hasDropdown;
  final VoidCallback onTap;
  final bool isActive;

  const _InlineFilterChip({
    required this.icon,
    required this.label,
    required this.hasDropdown,
    required this.onTap,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? AppTheme.primary : AppTheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? AppTheme.primary : AppTheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isActive ? AppTheme.primary : AppTheme.onSurface,
              ),
            ),
            if (hasDropdown) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.expand_more,
                size: 16,
                color: isActive ? AppTheme.primary : AppTheme.onSurfaceVariant,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final bool isPositive;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.isPositive,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outlineVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.05,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${CurrencyHelper.symbol}${CurrencyHelper.format(amount.abs())}',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppTheme.primary : AppTheme.onSurfaceVariant,
      ),
      title: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? AppTheme.primary : AppTheme.onSurface,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppTheme.primary)
          : null,
      onTap: onTap,
    );
  }
}
