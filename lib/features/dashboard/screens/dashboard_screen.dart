import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/constants/app_theme.dart' show CurrencyHelper, AppTheme;
import '../../../core/services/firebase_service.dart';
import '../../../core/models/transaction_model.dart';
import '../../transactions/bloc/transaction_bloc.dart';
import '../../transactions/bloc/transaction_event.dart';
import '../../transactions/bloc/transaction_state.dart';
import '../../transactions/screens/transaction_list_screen.dart';
import '../../transactions/screens/add_transaction_screen.dart';
import '../../goals/bloc/goal_bloc.dart';
import '../../goals/bloc/goal_event.dart';
import '../../goals/bloc/goal_state.dart';
import '../../goals/screens/goal_detail_screen.dart';
import '../../goals/screens/goals_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime _selectedMonth = DateTime.now();
  final _firebaseService = FirebaseService.instance;

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              TransactionBloc(_firebaseService)
                ..add(TransactionLoadRequested()),
        ),
        BlocProvider(
          create: (_) => GoalBloc(_firebaseService)..add(GoalLoadRequested()),
        ),
      ],
      child: Builder(
        builder: (ctx) {
          final transactionBloc = ctx.read<TransactionBloc>();
          final goalBloc = ctx.read<GoalBloc>();
          return Scaffold(
            appBar: _buildAppBar(ctx),
            body: RefreshIndicator(
              color: AppTheme.primary,
              onRefresh: () async {
                transactionBloc.add(TransactionLoadRequested());
                goalBloc.add(GoalLoadRequested());
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMonthSelector(ctx),
                    const SizedBox(height: 20),
                    _buildSummaryCards(ctx),
                    const SizedBox(height: 28),
                    _buildCharts(ctx),
                    const SizedBox(height: 24),
                    _buildDailySpendChart(ctx),
                    const SizedBox(height: 28),
                    _buildGoalsSummary(ctx),
                    const SizedBox(height: 24),
                    _buildRecentTransactions(ctx),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _greeting(),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.onSurfaceVariant),
          ),
          Text('Sajilo Khata', style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.add_circle_outline_rounded, size: 26),
          color: AppTheme.primary,
          tooltip: 'Add Transaction',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<TransactionBloc>(),
                child: const AddTransactionScreen(),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildMonthSelector(BuildContext context) {
    final monthFormat = DateFormat('MMMM yyyy');
    final prevMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    final nextMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    final isCurrentMonth =
        _selectedMonth.year == DateTime.now().year &&
        _selectedMonth.month == DateTime.now().month;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.surfaceContainerLow),
      ),
      child: Row(
        children: [
          _MonthNavButton(
            icon: Icons.chevron_left_rounded,
            onPressed: () => setState(() => _selectedMonth = prevMonth),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedMonth,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  initialDatePickerMode: DatePickerMode.year,
                );
                if (picked != null) {
                  setState(() => _selectedMonth = picked);
                }
              },
              child: Center(
                child: Text(
                  monthFormat.format(_selectedMonth).toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: AppTheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
          _MonthNavButton(
            icon: Icons.chevron_right_rounded,
            onPressed: isCurrentMonth
                ? null
                : () => setState(() => _selectedMonth = nextMonth),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context) {
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

        return Column(
          children: [
            // Net balance card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.signatureGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NET BALANCE',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.onPrimary.withValues(alpha: 0.7),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${net < 0 ? '-' : ''}${CurrencyHelper.symbol}${CurrencyHelper.format(net.abs())}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.onPrimary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniStat(
                          label: 'Income',
                          value:
                              '${CurrencyHelper.symbol}${CurrencyHelper.format(income)}',
                          icon: Icons.south_west_rounded,
                          onPrimary: true,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 32,
                        color: AppTheme.onPrimary.withValues(alpha: 0.2),
                      ),
                      Expanded(
                        child: _MiniStat(
                          label: 'Expenses',
                          value:
                              '${CurrencyHelper.symbol}${CurrencyHelper.format(expense)}',
                          icon: Icons.north_east_rounded,
                          onPrimary: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCharts(BuildContext context) {
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
          return _EmptyCard(
            icon: Icons.pie_chart_outline_rounded,
            title: 'No expenses yet',
            subtitle: 'Expenses by category will appear here',
          );
        }

        final totalExpense = categoryTotals.values.fold(0.0, (a, b) => a + b);
        final topCategoryEntry = categoryTotals.entries.reduce(
          (a, b) => a.value > b.value ? a : b,
        );
        final topCategoryPercentage =
            (topCategoryEntry.value / totalExpense) * 100;

        final sections = categoryTotals.entries.map((e) {
          return PieChartSectionData(
            value: e.value,
            showTitle: false,
            color: _getCategoryColor(e.key),
            radius: 28,
          );
        }).toList();

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(title: 'Spending by Category'),
              const SizedBox(height: 24),
              SizedBox(
                height: 180,
                child: Stack(
                  children: [
                    PieChart(
                      PieChartData(
                        sections: sections,
                        centerSpaceRadius: 60,
                        sectionsSpace: 2,
                        pieTouchData: PieTouchData(enabled: false),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            topCategoryEntry.key.split(' ').first.toUpperCase(),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: AppTheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                ),
                          ),
                          Text(
                            '${topCategoryPercentage.toStringAsFixed(0)}%',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.onSurface,
                                  letterSpacing: -0.5,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ...categoryTotals.entries.map((e) {
                final percent = (e.value / totalExpense) * 100;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _getCategoryColor(e.key),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          e.key,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.onSurfaceVariant),
                        ),
                      ),
                      Text(
                        '${percent.toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
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

  Widget _buildDailySpendChart(BuildContext context) {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        if (state is! TransactionLoaded) return const SizedBox.shrink();

        final now = DateTime.now();
        final thirtyDaysAgo = now.subtract(const Duration(days: 30));

        final dailyTotals = <DateTime, double>{};
        for (int i = 0; i < 30; i++) {
          final date = thirtyDaysAgo.add(Duration(days: i));
          dailyTotals[DateTime(date.year, date.month, date.day)] = 0;
        }

        for (final tx in state.transactions) {
          if (tx.type == TransactionType.debit) {
            final txDate = DateTime(
              tx.dateAD.year,
              tx.dateAD.month,
              tx.dateAD.day,
            );
            if (txDate.isAfter(thirtyDaysAgo) &&
                txDate.isBefore(now.add(const Duration(days: 1)))) {
              dailyTotals[txDate] = (dailyTotals[txDate] ?? 0) + tx.amount;
            }
          }
        }

        final spots = dailyTotals.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));

        if (spots.isEmpty || spots.every((e) => e.value == 0)) {
          return _EmptyCard(
            icon: Icons.bar_chart_rounded,
            title: 'No daily data yet',
            subtitle: 'Daily spending trends will appear here',
          );
        }

        final maxY = spots.map((e) => e.value).reduce((a, b) => a > b ? a : b);

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(title: 'Daily Spending (30 days)'),
              const SizedBox(height: 20),
              SizedBox(
                height: 180,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxY > 0 ? maxY * 1.2 : 100,
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${CurrencyHelper.symbol}${CurrencyHelper.format(rod.toY)}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= spots.length) {
                              return const Text('');
                            }
                            final date = spots[index].key;
                            if (date.day == 1 ||
                                date.day == 10 ||
                                date.day == 20) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '${date.day}',
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              );
                            }
                            return const Text('');
                          },
                          reservedSize: 22,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value == 0) return const Text('');
                            return Text(
                              '${(value / 1000).toStringAsFixed(0)}k',
                              style: Theme.of(context).textTheme.labelSmall,
                            );
                          },
                          reservedSize: 32,
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: AppTheme.surfaceContainerLow,
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(spots.length, (index) {
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: spots[index].value,
                            color: spots[index].value > 0
                                ? AppTheme.primary
                                : AppTheme.surfaceContainerLow,
                            width: 5,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGoalsSummary(BuildContext context) {
    return BlocBuilder<GoalBloc, GoalState>(
      builder: (context, state) {
        if (state is! GoalLoaded) return const SizedBox.shrink();

        final activeGoals = state.activeGoals;
        if (activeGoals.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SectionHeader(title: 'Savings Goals'),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: context.read<GoalBloc>(),
                        child: const GoalsListScreen(),
                      ),
                    ),
                  ),
                  child: const Text('View all'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...activeGoals.take(3).map((goal) {
              final daysLeft = goal.deadlineAD
                  .difference(DateTime.now())
                  .inDays;
              final remaining = goal.targetAmount - goal.savedAmount;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        goal.emoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                  title: Text(goal.name),
                  subtitle: Text(
                    daysLeft > 0
                        ? '$daysLeft days left · ${CurrencyHelper.symbol}${remaining.toStringAsFixed(0)} to go'
                        : 'Deadline passed',
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: context.read<GoalBloc>(),
                        child: GoalDetailScreen(initialGoal: goal),
                      ),
                    ),
                  ),
                  trailing: SizedBox(
                    width: 44,
                    height: 44,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: goal.progressPercent,
                          strokeWidth: 4,
                          backgroundColor: AppTheme.surfaceContainerLow,
                          color: AppTheme.primary,
                        ),
                        Text(
                          '${(goal.progressPercent * 100).toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 9,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
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

        final recentTxs = List<TransactionModel>.from(transactions)
          ..sort((a, b) => b.dateAD.compareTo(a.dateAD));
        final latestTxs = recentTxs.take(4).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SectionHeader(title: 'Recent Transactions'),
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
                  child: const Text('View all'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: List.generate(latestTxs.length, (i) {
                  final tx = latestTxs[i];
                  final isDebit = tx.type == TransactionType.debit;
                  return Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isDebit
                                ? AppTheme.error.withValues(alpha: 0.08)
                                : AppTheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isDebit
                                ? Icons.south_west_rounded
                                : Icons.north_east_rounded,
                            color: isDebit ? AppTheme.error : AppTheme.primary,
                            size: 18,
                          ),
                        ),
                        title: Text(tx.category),
                        subtitle: Text(
                          tx.note ??
                              tx.bank ??
                              DateFormat('MMM dd').format(tx.dateAD),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider.value(
                              value: context.read<TransactionBloc>(),
                              child: AddTransactionScreen(transaction: tx),
                            ),
                          ),
                        ),
                        trailing: Text(
                          '${isDebit ? '-' : '+'}${CurrencyHelper.symbol}${CurrencyHelper.format(tx.amount)}',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isDebit
                                    ? AppTheme.error
                                    : AppTheme.primary,
                              ),
                        ),
                      ),
                      if (i < latestTxs.length - 1)
                        const Divider(height: 1, indent: 72, endIndent: 16),
                    ],
                  );
                }),
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getCategoryColor(String category) {
    final colors = {
      'Food & Dining': AppTheme.primary,
      'Transport': const Color(0xFF003830),
      'Shopping': AppTheme.secondary,
      'Utilities': AppTheme.outline,
      'Health': AppTheme.error,
      'Education': AppTheme.primaryContainer,
      'Remittance / Transfer': const Color(0xFF162521),
      'Salary / Income': AppTheme.primary,
      'Savings': AppTheme.secondaryContainer,
      'Entertainment': AppTheme.onSurfaceVariant,
      'Groceries': const Color(0xFF8BA6A1),
    };
    return colors[category] ?? AppTheme.outlineVariant;
  }
}

// ─── Reusable widgets ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool onPrimary;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    this.onPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = onPrimary ? AppTheme.onPrimary : AppTheme.onSurface;
    final subColor = onPrimary
        ? AppTheme.onPrimary.withValues(alpha: 0.65)
        : AppTheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(icon, color: subColor, size: 16),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: subColor,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  const _MonthNavButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      color: onPressed == null ? AppTheme.outlineVariant : AppTheme.onSurface,
      onPressed: onPressed,
      splashRadius: 20,
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppTheme.outlineVariant),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
