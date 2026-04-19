import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../core/constants/app_theme.dart';
import '../../../core/models/transaction_model.dart';
import '../bloc/transaction_bloc.dart';
import '../bloc/transaction_event.dart';
import '../bloc/transaction_state.dart';
import '../widgets/transaction_tile.dart';
import 'add_transaction_screen.dart';

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
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _currentFilter = TransactionFilterBy.all;
    _dateFilter = null;
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      _initialized = true;
      _currentFilter = TransactionFilterBy.all;
      _dateFilter = null;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ledger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Filter',
            onPressed: () => _showFilterSheet(context),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
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
          const SizedBox(width: 4),
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
            if (filteredTransactions.isEmpty) {
              return _buildEmpty(context);
            }
            final grouped = _groupByDate(filteredTransactions);
            final labels = grouped.keys.toList();
            return ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 120),
              itemCount: labels.length,
              itemBuilder: (context, index) {
                final label = labels[index];
                final txs = grouped[label]!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
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
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton.extended(
          heroTag: 'transaction_fab',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<TransactionBloc>(),
                child: const AddTransactionScreen(),
              ),
            ),
          ),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add'),
        ),
      ),
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
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Add a transaction manually or\nwait for an SMS to be parsed',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.only(top: 16),
        child: StatefulBuilder(
          builder: (sheetContext, setSheetState) => SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter Transactions',
                        style: Theme.of(sheetContext).textTheme.titleLarge,
                      ),
                      if (_dateFilter != null ||
                          _currentFilter != TransactionFilterBy.all)
                        TextButton(
                          onPressed: () {
                            setSheetState(() {
                              _currentFilter = TransactionFilterBy.all;
                              _dateFilter = null;
                            });
                            setState(() {});
                            Navigator.pop(sheetContext);
                          },
                          child: const Text('Clear all'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Type',
                    style: Theme.of(sheetContext).textTheme.titleSmall
                        ?.copyWith(color: AppTheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FilterChip(
                        label: 'All',
                        selected: _currentFilter == TransactionFilterBy.all,
                        onSelected: (_) {
                          setSheetState(
                            () => _currentFilter = TransactionFilterBy.all,
                          );
                          setState(() {});
                          Navigator.pop(sheetContext);
                        },
                      ),
                      _FilterChip(
                        label: 'Expenses',
                        selected: _currentFilter == TransactionFilterBy.expense,
                        onSelected: (_) {
                          setSheetState(
                            () => _currentFilter = TransactionFilterBy.expense,
                          );
                          setState(() {});
                          Navigator.pop(sheetContext);
                        },
                      ),
                      _FilterChip(
                        label: 'Income',
                        selected: _currentFilter == TransactionFilterBy.income,
                        onSelected: (_) {
                          setSheetState(
                            () => _currentFilter = TransactionFilterBy.income,
                          );
                          setState(() {});
                          Navigator.pop(sheetContext);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Date Range',
                    style: Theme.of(sheetContext).textTheme.titleSmall
                        ?.copyWith(color: AppTheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _DateFilterField(
                          label: 'From',
                          date: _dateFilter?.from,
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: sheetContext,
                              initialDate: _dateFilter?.from ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setSheetState(() {
                                _dateFilter = DateSpan(
                                  from: picked,
                                  to: _dateFilter?.to ?? DateTime.now(),
                                );
                              });
                              setState(() {});
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DateFilterField(
                          label: 'To',
                          date: _dateFilter?.to,
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: sheetContext,
                              initialDate: _dateFilter?.to ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setSheetState(() {
                                _dateFilter = DateSpan(
                                  from: _dateFilter?.from ?? DateTime(2020),
                                  to: picked,
                                );
                              });
                              setState(() {});
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<TransactionModel> _filterTransactions(
    List<TransactionModel> transactions,
  ) {
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

  Map<String, List<TransactionModel>> _groupByDate(
    List<TransactionModel> transactions,
  ) {
    final grouped = <String, List<TransactionModel>>{};
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

  void _showTransactionDetails(BuildContext context, TransactionModel tx) {
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
            final color = isDebit ? AppTheme.error : AppTheme.primary;
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
                          borderRadius: BorderRadius.circular(14),
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
                              style: Theme.of(sheetContext)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                    letterSpacing: -0.5,
                                  ),
                            ),
                            Text(
                              isDebit ? 'Expense' : 'Income',
                              style: Theme.of(sheetContext).textTheme.bodyMedium
                                  ?.copyWith(color: AppTheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _detailRow(context, 'Category', tx.category),
                  if (tx.bank != null)
                    _detailRow(context, 'Bank / Wallet', tx.bank!),
                  if (tx.note != null && tx.note!.isNotEmpty)
                    _detailRow(context, 'Note', tx.note!),
                  _detailRow(context, 'Date', dateFormat.format(tx.dateAD)),
                  if (tx.dateBS.isNotEmpty)
                    _detailRow(context, 'Date (BS)', tx.dateBS),
                  _detailRow(
                    context,
                    'Source',
                    tx.source == TransactionSource.sms ? 'SMS' : 'Manual',
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
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext ctx, TransactionModel tx) {
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });
  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: AppTheme.primary.withValues(alpha: 0.12),
      checkmarkColor: AppTheme.primary,
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: selected ? AppTheme.primary : AppTheme.onSurfaceVariant,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}

class _DateFilterField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  const _DateFilterField({
    required this.label,
    required this.date,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: date != null ? AppTheme.primary : AppTheme.outlineVariant,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: date != null
                  ? AppTheme.primary
                  : AppTheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    date != null
                        ? DateFormat('MMM dd, yy').format(date!)
                        : 'Select',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: date != null
                          ? AppTheme.onSurface
                          : AppTheme.onSurfaceVariant,
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
}
