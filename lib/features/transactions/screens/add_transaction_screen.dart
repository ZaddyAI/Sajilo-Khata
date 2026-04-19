import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/models/transaction_model.dart';
import '../bloc/transaction_bloc.dart';
import '../bloc/transaction_event.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionModel? transaction;

  const AddTransactionScreen({super.key, this.transaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _bankController = TextEditingController();

  late TransactionType _type;
  late String _category;
  late DateTime _date;
  bool _isEditing = false;

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
    final tx = widget.transaction;
    _isEditing = tx != null;
    _type = tx?.type ?? TransactionType.debit;
    _category = tx?.category ?? 'Other';
    _date = tx?.dateAD ?? DateTime.now();

    if (tx != null) {
      final displayAmount = CurrencyHelper.convertFromStored(tx.amount);
      _amountController.text = displayAmount.toStringAsFixed(0);
      _noteController.text = tx.note ?? '';
      _bankController.text = tx.bank ?? '';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _bankController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CurrencyNotifier>(
      builder: (context, currencyNotifier, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(_isEditing ? 'Edit Transaction' : 'Add Transaction'),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              children: [
                // Type Toggle
                _TypeToggle(
                  selected: _type,
                  onChanged: (t) => setState(() => _type = t),
                ),
                const SizedBox(height: 24),

                // Amount
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textAlign: TextAlign.start,
                  style: Theme.of(context).textTheme.titleLarge,
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(currencyNotifier.icon, size: 20),
                    ),
                    hintText: '0',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter an amount';
                    final amount = double.tryParse(v);
                    if (amount == null || amount <= 0) {
                      return 'Enter a valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Category
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v ?? 'Other'),
                ),
                const SizedBox(height: 16),

                // Note
                TextFormField(
                  controller: _noteController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    prefixIcon: Icon(Icons.notes_rounded),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),

                // Bank / Wallet
                TextFormField(
                  controller: _bankController,
                  decoration: const InputDecoration(
                    labelText: 'Bank / Wallet (optional)',
                    prefixIcon: Icon(Icons.account_balance_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                // Date Picker
                _DatePickerField(
                  date: _date,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                    );
                    if (picked != null) setState(() => _date = picked);
                  },
                ),
                const SizedBox(height: 32),

                // Save Button
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _saveTransaction,
                    child: Text(
                      _isEditing ? 'Update Transaction' : 'Add Transaction',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _saveTransaction() {
    if (!_formKey.currentState!.validate()) return;

    final inputAmount = double.parse(_amountController.text);
    final storedAmount = CurrencyHelper.convertToStored(inputAmount);
    final now = DateTime.now();

    final transaction = TransactionModel(
      id: widget.transaction?.id ?? const Uuid().v4(),
      amount: storedAmount,
      type: _type,
      source: TransactionSource.manual,
      category: _category,
      bank: _bankController.text.isEmpty ? null : _bankController.text,
      note: _noteController.text.isEmpty ? null : _noteController.text,
      dateAD: _date,
      dateBS: '',
      createdAt: widget.transaction?.createdAt ?? now,
    );

    if (_isEditing) {
      context.read<TransactionBloc>().add(
        TransactionUpdateRequested(transaction: transaction),
      );
    } else {
      context.read<TransactionBloc>().add(
        TransactionAddRequested(transaction: transaction),
      );
    }

    Navigator.pop(context);
  }
}

// ─── Reusable form widgets ─────────────────────────────────────────────────────

class _TypeToggle extends StatelessWidget {
  final TransactionType selected;
  final ValueChanged<TransactionType> onChanged;

  const _TypeToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _TypeOption(
            label: 'Expense',
            icon: Icons.south_west_rounded,
            selected: selected == TransactionType.debit,
            color: AppTheme.error,
            onTap: () => onChanged(TransactionType.debit),
          ),
          const SizedBox(width: 4),
          _TypeOption(
            label: 'Income',
            icon: Icons.north_east_rounded,
            selected: selected == TransactionType.credit,
            color: AppTheme.primary,
            onTap: () => onChanged(TransactionType.credit),
          ),
        ],
      ),
    );
  }
}

class _TypeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TypeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.surfaceContainerLowest
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppTheme.onSurface.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? color : AppTheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected ? color : AppTheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;

  const _DatePickerField({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.outlineVariant, width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: 18,
              color: AppTheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  DateFormat('MMMM dd, yyyy').format(date),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const Spacer(),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
