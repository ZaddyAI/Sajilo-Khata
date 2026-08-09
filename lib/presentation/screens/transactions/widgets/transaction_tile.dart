import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../domain/entities/transaction.dart';
import '../../../../../core/constants/app_theme.dart';

class TransactionTile extends StatefulWidget {
  final Transaction transaction;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
    this.onDelete,
  });

  @override
  State<TransactionTile> createState() => _TransactionTileState();
}

class _TransactionTileState extends State<TransactionTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final transaction = widget.transaction;
    final isDebit = transaction.type == TransactionType.debit;
    // Stitch: bg-error for debit, bg-secondary for credit (NOT tertiary)
    final accentColor = isDebit ? AppTheme.error : AppTheme.secondary;
    final containerColor = isDebit
        ? AppTheme.errorContainer
        : AppTheme.secondaryContainer;
    final onContainerColor = isDebit
        ? AppTheme.onErrorContainer
        : AppTheme.onSecondaryContainer;

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => widget.onDelete?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.error,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 22,
        ),
      ),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap?.call();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          // Stitch: transaction-card:active { transform: scale(0.98) }
          scale: _pressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            // Stitch: p-md bg-surface-container-lowest rounded-xl border border-outline-variant shadow-sm relative overflow-hidden
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: Border.all(color: AppTheme.outlineVariant, width: 1),
              boxShadow: AppTheme.cardShadow,
            ),
            clipBehavior: Clip.antiAlias,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Stitch: absolute left-0 top-0 bottom-0 w-1 (w-1 = 4px in tailwind)
                  Container(width: 4, color: accentColor),

                  Expanded(
                    child: Padding(
                      // Stitch: p-md = 16px
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Stitch: w-12 h-12 flex items-center justify-center rounded-full
                          // bg-secondary-container / bg-error-container text-on-secondary-container
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: containerColor.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getCategoryIcon(transaction.category),
                              color: onContainerColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Title + subtitle
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Stitch: font-body-lg font-bold text-primary leading-tight
                                Text(
                                  transaction.category,
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primary,
                                    height: 1.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                // Stitch: text-body-sm text-on-surface-variant flex items-center gap-xs
                                // bank · note format
                                Row(
                                  children: [
                                    if (transaction.bank != null) ...[
                                      Text(
                                        transaction.bank!,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          // Stitch: text-primary-fixed-variant
                                          color: AppTheme.onPrimaryFixedVariant,
                                        ),
                                      ),
                                      if (transaction.note != null)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                          child: Container(
                                            width: 3,
                                            height: 3,
                                            decoration: BoxDecoration(
                                              color: AppTheme.outline,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                    ],
                                    if (transaction.note != null)
                                      Expanded(
                                        child: Text(
                                          transaction.note!,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: AppTheme.onSurfaceVariant,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      )
                                    else if (transaction.bank == null)
                                      Text(
                                        DateFormat(
                                          'MMM dd',
                                        ).format(transaction.dateAD),
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: AppTheme.onSurfaceVariant,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Amount + time
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Stitch: font-data-mono text-body-lg font-bold text-secondary/error
                              Text(
                                '${isDebit ? '-' : '+'}${CurrencyHelper.symbol}${CurrencyHelper.format(transaction.amount)}',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: accentColor,
                                ),
                              ),
                              const SizedBox(height: 3),
                              // Stitch: text-[10px] uppercase tracking-wider font-label-bold text-on-surface-variant opacity-60
                              Text(
                                DateFormat(
                                  'hh:mm a',
                                ).format(transaction.dateAD).toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: AppTheme.onSurfaceVariant.withValues(
                                    alpha: 0.6,
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
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    return switch (category) {
      'Food & Dining' => Icons.restaurant_rounded,
      'Transport' => Icons.directions_car_rounded,
      'Shopping' => Icons.shopping_cart_rounded,
      'Utilities' => Icons.electric_bolt_rounded,
      'Health' => Icons.health_and_safety_rounded,
      'Education' => Icons.school_rounded,
      'Remittance / Transfer' => Icons.send_rounded,
      'Salary / Income' => Icons.payments_rounded,
      'Savings' => Icons.savings_rounded,
      'Entertainment' => Icons.movie_rounded,
      'Groceries' => Icons.local_grocery_store_rounded,
      _ => Icons.receipt_rounded,
    };
  }
}
