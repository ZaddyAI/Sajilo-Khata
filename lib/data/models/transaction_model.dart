import '../../domain/entities/transaction.dart';

class TransactionModel {
  static Transaction fromMap(Map<String, dynamic> map, String id) {
    final typeStr = map['type']?.toString().toLowerCase() ?? '';
    final type = typeStr == 'debit'
        ? TransactionType.debit
        : TransactionType.credit;

    final amountValue = map['amount'];
    final amount = amountValue is num
        ? amountValue.toDouble()
        : (double.tryParse(amountValue?.toString() ?? '') ?? 0.0);

    final sourceStr = map['source']?.toString().toLowerCase() ?? '';
    final source = sourceStr == 'sms'
        ? TransactionSource.sms
        : TransactionSource.manual;

    return Transaction(
      id: id,
      amount: amount,
      type: type,
      source: source,
      category: map['category']?.toString() ?? 'Other',
      bank: map['bank']?.toString(),
      note: map['note']?.toString(),
      dateAD:
          DateTime.tryParse(map['dateAD']?.toString() ?? '') ?? DateTime.now(),
      dateBS: map['dateBS']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  static Map<String, dynamic> toMap(Transaction tx) => {
    'amount': tx.amount,
    'type': tx.type == TransactionType.debit ? 'debit' : 'credit',
    'source': tx.source == TransactionSource.sms ? 'sms' : 'manual',
    'category': tx.category,
    'bank': tx.bank,
    'note': tx.note,
    'dateAD': tx.dateAD.toIso8601String(),
    'dateBS': tx.dateBS,
    'createdAt': tx.createdAt.toIso8601String(),
  };
}
