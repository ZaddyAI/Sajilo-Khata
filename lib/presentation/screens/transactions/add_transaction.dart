part of 'transactions_imports.dart';

class AddTransactionScreen extends StatefulWidget {
  final Transaction? transaction;

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
    ('Food & Dining', CupertinoIcons.cart),
    ('Transport', CupertinoIcons.car_detailed),
    ('Shopping', CupertinoIcons.bag),
    ('Utilities', CupertinoIcons.bolt),
    ('Health', CupertinoIcons.heart),
    ('Education', CupertinoIcons.book),
    ('Remittance', CupertinoIcons.paperplane),
    ('Salary', CupertinoIcons.money_dollar_circle),
    ('Savings', CupertinoIcons.archivebox),
    ('Entertainment', CupertinoIcons.film),
    ('Groceries', CupertinoIcons.cart_fill),
    ('Other', CupertinoIcons.doc_text),
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
          backgroundColor: AppTheme.background,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.background.withValues(alpha: 0.9),
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Text(
                            _isEditing ? 'Edit Entry' : 'New Transaction',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onSurface,
                              letterSpacing: -0.3,
                            ),
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: _saveTransaction,
                            child: Text(
                              'Save',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildIosTypeToggle(),
                  const SizedBox(height: 16),
                  _buildAmountCard(currencyNotifier),
                  const SizedBox(height: 20),
                  _buildCategoryGrid(),
                  const SizedBox(height: 20),
                  _buildIosGroupedMetadataSection(),
                ],
              ),
            ),
          ),
          bottomSheet: Container(
            color: AppTheme.background.withValues(alpha: 0.95),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  _isEditing ? 'Save Changes' : 'Confirm Transaction',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIosTypeToggle() {
    final isExpense = _type == TransactionType.debit;
    return Container(
      height: 48,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
        border: Border.all(color: AppTheme.outlineVariant, width: 0.8),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _type = TransactionType.debit);
              },
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isExpense ? AppTheme.expense : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                  boxShadow: isExpense
                      ? [
                          BoxShadow(
                            color: AppTheme.expense.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.arrow_down,
                      size: 15,
                      color: isExpense
                          ? Colors.white
                          : AppTheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Expense',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isExpense
                            ? Colors.white
                            : AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _type = TransactionType.credit);
              },
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: !isExpense ? AppTheme.income : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                  boxShadow: !isExpense
                      ? [
                          BoxShadow(
                            color: AppTheme.income.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.arrow_up,
                      size: 15,
                      color: !isExpense
                          ? Colors.white
                          : AppTheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Income',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: !isExpense
                            ? Colors.white
                            : AppTheme.onSurfaceVariant,
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
  }

  Widget _buildAmountCard(CurrencyNotifier currencyNotifier) {
    final isExpense = _type == TransactionType.debit;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.iosCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AMOUNT',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.mint,
                  borderRadius: BorderRadius.circular(AppTheme.pillRadius),
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
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                CurrencyHelper.symbol,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  autofocus: !_isEditing,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 38,
                    fontWeight: FontWeight.w700,
                    color: isExpense ? AppTheme.expense : AppTheme.income,
                  ),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: GoogleFonts.jetBrainsMono(
                      fontSize: 38,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.outlineVariant,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
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
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'SELECT CATEGORY',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            Text(
              _category,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.92,
          ),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final (catName, icon) = _categories[index];
            final isSelected = _category == catName;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _category = catName);
              },
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.mint : Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.squircleRadius),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primary
                        : AppTheme.outlineVariant,
                    width: isSelected ? 1.5 : 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.surfaceContainerLow,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: 18,
                        color: isSelected ? Colors.white : AppTheme.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      catName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? AppTheme.primaryDark
                            : AppTheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildIosGroupedMetadataSection() {
    return Container(
      decoration: AppTheme.iosCardDecoration,
      child: Column(
        children: [
          // Date Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppTheme.mint,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    CupertinoIcons.calendar,
                    size: 16,
                    color: AppTheme.primaryDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      HapticFeedback.selectionClick();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 1)),
                      );
                      if (picked != null) setState(() => _date = picked);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DATE',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('EEEE, MMM dd, yyyy').format(_date),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(
            height: 0.8,
            indent: 52,
            color: AppTheme.outlineVariant,
          ),

          // Account / Bank Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppTheme.mint,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    CupertinoIcons.creditcard,
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
                        'ACCOUNT / BANK',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      TextField(
                        controller: _bankController,
                        decoration: InputDecoration(
                          hintText: 'e.g. Nabil Bank, Cash, eSewa',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: AppTheme.onSurfaceVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(
            height: 0.8,
            indent: 52,
            color: AppTheme.outlineVariant,
          ),

          // Notes Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppTheme.mint,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    CupertinoIcons.pencil,
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
                        'NOTE (OPTIONAL)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      TextField(
                        controller: _noteController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Add an optional note...',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: AppTheme.onSurfaceVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.onSurface,
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
    );
  }

  void _saveTransaction() {
    HapticFeedback.lightImpact();
    if (!_formKey.currentState!.validate()) return;

    final inputAmount = double.parse(_amountController.text);
    final storedAmount = CurrencyHelper.convertToStored(inputAmount);
    final now = DateTime.now();

    final transaction = Transaction(
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
