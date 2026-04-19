import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/models/goal_model.dart';
import '../bloc/goal_bloc.dart';
import '../bloc/goal_event.dart';

class AddGoalScreen extends StatefulWidget {
  final GoalModel? goal;

  const AddGoalScreen({super.key, this.goal});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  late DateTime _deadline;
  String _emoji = '🎯';

  @override
  void initState() {
    super.initState();
    if (widget.goal != null) {
      _nameController.text = widget.goal!.name;
      final displayAmount = CurrencyHelper.convertFromStored(
        widget.goal!.targetAmount,
      );
      _amountController.text = displayAmount > 0
          ? displayAmount.toStringAsFixed(0)
          : '';
      _deadline = widget.goal!.deadlineAD;
      _emoji = widget.goal!.emoji;
    } else {
      _deadline = DateTime.now().add(const Duration(days: 90));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  static const _emojis = [
    '🎯',
    '💻',
    '📱',
    '🏠',
    '🚗',
    '✈️',
    '💍',
    '🎓',
    '🏥',
    '🎁',
  ];

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.goal != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Goal' : 'New Savings Goal')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'What are you saving for?',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primary.withValues(alpha: 0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.outlineVariant,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Goal Name',
                hintText: 'e.g., New Laptop',
                prefixIcon: Icon(Icons.flag_outlined),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a goal name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Target Amount (${CurrencyHelper.currency})',
                prefixIcon: Icon(CurrencyHelper.icon),
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
            const SizedBox(height: 16),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.outlineVariant,
                    width: 1.5,
                  ),
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
                          'Target Date',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: AppTheme.onSurfaceVariant),
                        ),
                        Text(
                          DateFormat('MMMM dd, yyyy').format(_deadline),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
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
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _saveGoal,
                child: Text(isEditing ? 'Update Goal' : 'Create Goal'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveGoal() {
    if (!_formKey.currentState!.validate()) return;

    final inputAmount = double.parse(_amountController.text);
    final storedAmount = CurrencyHelper.convertToStored(inputAmount);
    final isEditing = widget.goal != null;

    if (isEditing) {
      final updatedGoal = widget.goal!.copyWith(
        name: _nameController.text.trim(),
        emoji: _emoji,
        targetAmount: storedAmount,
        deadlineAD: _deadline,
      );
      context.read<GoalBloc>().add(GoalUpdateRequested(goal: updatedGoal));
    } else {
      final goal = GoalModel(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        emoji: _emoji,
        targetAmount: storedAmount,
        savedAmount: 0,
        deadlineAD: _deadline,
        deadlineBS: '',
        status: GoalStatus.onTrack,
        createdAt: DateTime.now(),
      );
      context.read<GoalBloc>().add(GoalAddRequested(goal: goal));
    }
    Navigator.pop(context);
  }
}
