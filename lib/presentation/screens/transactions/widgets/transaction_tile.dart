import 'package:flutter/cupertino.dart';
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
    final accentColor = isDebit ? AppTheme.expense : AppTheme.income;
    final containerColor = isDebit ? AppTheme.tertiaryContainer : AppTheme.mint;
    final onContainerColor = isDebit
        ? AppTheme.onTertiaryContainer
        : AppTheme.primaryDark;

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => widget.onDelete?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.expense,
          borderRadius: BorderRadius.circular(AppTheme.tileRadius),
        ),
        child: const Icon(CupertinoIcons.trash, color: Colors.white, size: 20),
      ),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap?.call();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(14),
            decoration: AppTheme.iosCardDecoration,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: containerColor,
                    borderRadius: BorderRadius.circular(
                      AppTheme.squircleRadius,
                    ),
                  ),
                  child: Icon(
                    _getCategoryIcon(transaction.category),
                    color: onContainerColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),

                // Title + Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        transaction.category,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurface,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (transaction.bank != null &&
                              transaction.bank!.isNotEmpty) ...[
                            Text(
                              transaction.bank!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryDark,
                              ),
                            ),
                            if (transaction.note != null &&
                                transaction.note!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                ),
                                child: Container(
                                  width: 3,
                                  height: 3,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.outline,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                          if (transaction.note != null &&
                              transaction.note!.isNotEmpty)
                            Expanded(
                              child: Text(
                                transaction.note!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppTheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            )
                          else if (transaction.bank == null ||
                              transaction.bank!.isEmpty)
                            Text(
                              DateFormat('MMM dd').format(transaction.dateAD),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: AppTheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Amount & Time
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${isDebit ? '-' : '+'}${CurrencyHelper.symbol}${CurrencyHelper.format(transaction.amount)}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      DateFormat(
                        'hh:mm a',
                      ).format(transaction.dateAD).toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                        color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
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

  IconData _getCategoryIcon(String category) {
    return switch (category) {
      'Food & Dining' => CupertinoIcons.cart,
      'Transport' => CupertinoIcons.car_detailed,
      'Shopping' => CupertinoIcons.bag,
      'Utilities' => CupertinoIcons.bolt,
      'Health' => CupertinoIcons.heart,
      'Education' => CupertinoIcons.book,
      'Remittance / Transfer' => CupertinoIcons.paperplane,
      'Salary / Income' => CupertinoIcons.money_dollar_circle,
      'Savings' => CupertinoIcons.archivebox,
      'Entertainment' => CupertinoIcons.film,
      'Groceries' => CupertinoIcons.cart_fill,
      _ => CupertinoIcons.doc_text,
    };
  }
}
