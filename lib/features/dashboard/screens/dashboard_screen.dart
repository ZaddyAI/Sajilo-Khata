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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMonthSelector(ctx),
                    const SizedBox(height: 16),
                    _buildSummaryCards(ctx),
                    const SizedBox(height: 20),
                    _buildCharts(ctx),
                    const SizedBox(height: 20),
                    _buildDailySpendChart(ctx),
                    const SizedBox(height: 24),
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

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.background,
              AppTheme.background.withValues(alpha: 0.95),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _greeting(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Sajilo Khata',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.add_rounded, size: 22),
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
        ),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: const Color(0xFFF0F2F1), width: 1),
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
                  monthFormat.format(_selectedMonth),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppTheme.signatureGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: AppTheme.onPrimary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'NET BALANCE',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          color: AppTheme.onPrimary.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${net < 0 ? '-' : ''}${CurrencyHelper.symbol}${CurrencyHelper.format(net.abs())}',
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.0,
                      color: AppTheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.arrow_downward_rounded,
                                  color: AppTheme.onPrimary,
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Income',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11,
                                      color: AppTheme.onPrimary.withValues(
                                        alpha: 0.65,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${CurrencyHelper.symbol}${CurrencyHelper.format(income)}',
                                    style: const TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.onPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 36,
                          color: AppTheme.onPrimary.withValues(alpha: 0.15),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_upward_rounded,
                                    color: AppTheme.onPrimary,
                                    size: 14,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Expenses',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 11,
                                        color: AppTheme.onPrimary.withValues(
                                          alpha: 0.65,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${CurrencyHelper.symbol}${CurrencyHelper.format(expense)}',
                                      style: const TextStyle(
                                        fontFamily: 'Manrope',
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.onPrimary,
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
            radius: 30,
          );
        }).toList();

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.cardShadow,
            border: Border.all(color: const Color(0xFFF0F2F1), width: 1),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.pie_chart_rounded,
                      color: AppTheme.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Spending by Category',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
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
                            topCategoryEntry.key.split(' ').first,
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
                                  fontWeight: FontWeight.w800,
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
              Wrap(
                spacing: 8,
                runSpacing: 12,
                children: categoryTotals.entries.map((e) {
                  final percent = (e.value / totalExpense) * 100;
                  return SizedBox(
                    width: (MediaQuery.of(context).size.width - 96) / 2,
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _getCategoryColor(e.key),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            e.key,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppTheme.onSurfaceVariant),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${percent.toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.onSurface,
                              ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
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
            boxShadow: AppTheme.cardShadow,
            border: Border.all(color: const Color(0xFFF0F2F1), width: 1),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.trending_down_rounded,
                      color: AppTheme.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Daily Spending',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
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
                        color: const Color(0xFFECEFED),
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
                                : const Color(0xFFECEFED),
                            width: 6,
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
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.savings_rounded,
                      color: AppTheme.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Savings Goals',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
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
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('View all'),
                  ),
                ],
              ),
            ),
            ...activeGoals.take(3).map((goal) {
              final daysLeft = goal.deadlineAD
                  .difference(DateTime.now())
                  .inDays;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.cardShadow,
                  border: Border.all(color: const Color(0xFFF0F2F1), width: 1),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: context.read<GoalBloc>(),
                          child: GoalDetailScreen(initialGoal: goal),
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                goal.emoji,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  goal.name,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${CurrencyHelper.symbol}${CurrencyHelper.format(goal.savedAmount)} / ${CurrencyHelper.symbol}${CurrencyHelper.format(goal.targetAmount)}',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppTheme.onSurfaceVariant,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: goal.progressPercent,
                                    minHeight: 6,
                                    backgroundColor: const Color(0xFFECEFED),
                                    valueColor: const AlwaysStoppedAnimation(
                                      AppTheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${(goal.progressPercent * 100).toStringAsFixed(0)}%',
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.primary,
                                    ),
                              ),
                              if (daysLeft > 0) ...[
                                const SizedBox(height: 2),
                                Text(
                                  '$daysLeft days',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: AppTheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
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
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: AppTheme.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Recent Transactions',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('View all'),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardShadow,
                border: Border.all(color: const Color(0xFFF0F2F1), width: 1),
              ),
              child: Column(
                children: List.generate(latestTxs.length, (i) {
                  final tx = latestTxs[i];
                  final isDebit = tx.type == TransactionType.debit;
                  return Column(
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.vertical(
                            top: i == 0
                                ? const Radius.circular(16)
                                : Radius.zero,
                            bottom: i == latestTxs.length - 1
                                ? const Radius.circular(16)
                                : Radius.zero,
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
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: isDebit
                                        ? AppTheme.error.withValues(alpha: 0.08)
                                        : AppTheme.primary.withValues(
                                            alpha: 0.08,
                                          ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    isDebit
                                        ? Icons.south_west_rounded
                                        : Icons.north_east_rounded,
                                    color: isDebit
                                        ? AppTheme.error
                                        : AppTheme.primary,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tx.category,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        tx.note ??
                                            tx.bank ??
                                            DateFormat(
                                              'MMM dd',
                                            ).format(tx.dateAD),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${isDebit ? '-' : '+'}${CurrencyHelper.symbol}${CurrencyHelper.format(tx.amount)}',
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: isDebit
                                            ? AppTheme.error
                                            : AppTheme.primary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (i < latestTxs.length - 1)
                        const Padding(
                          padding: EdgeInsets.only(left: 70),
                          child: Divider(height: 1),
                        ),
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
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: const Color(0xFFF0F2F1), width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFECEFED),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 28, color: AppTheme.outlineVariant),
          ),
          const SizedBox(height: 14),
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
