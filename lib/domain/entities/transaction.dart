enum TransactionType { debit, credit }
enum TransactionSource { sms, manual }

class Transaction {
  final String id;
  final double amount;
  final TransactionType type;
  final TransactionSource source;
  final String category;
  final String? bank;
  final String? note;
  final DateTime dateAD;
  final String dateBS;
  final DateTime createdAt;

  const Transaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.source,
    required this.category,
    this.bank,
    this.note,
    required this.dateAD,
    required this.dateBS,
    required this.createdAt,
  });

  Transaction copyWith({
    double? amount,
    TransactionType? type,
    String? category,
    String? note,
    String? dateBS,
  }) {
    return Transaction(
      id: id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      source: source,
      category: category ?? this.category,
      bank: bank,
      note: note ?? this.note,
      dateAD: dateAD,
      dateBS: dateBS ?? this.dateBS,
      createdAt: createdAt,
    );
  }
}