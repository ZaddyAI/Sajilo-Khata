enum TransactionType { debit, credit }

enum TransactionSource { sms, manual }

class TransactionModel {
  final String id;
  final double amount;
  final TransactionType type;
  final TransactionSource source;
  final String category;
  final String? bank;
  final String? note;
  final DateTime dateAD;
  final String dateBS; // from nepali_calendar_kit
  final DateTime createdAt;

  TransactionModel({
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

  factory TransactionModel.fromMap(Map<String, dynamic> map, String id) {
    final typeStr = map['type']?.toString().toLowerCase() ?? '';
    final type = typeStr == 'debit' ? TransactionType.debit : TransactionType.credit;
    
    final amountValue = map['amount'];
    final amount = amountValue is num ? amountValue.toDouble() : (double.tryParse(amountValue?.toString() ?? '') ?? 0.0);
    
    final sourceStr = map['source']?.toString().toLowerCase() ?? '';
    final source = sourceStr == 'sms' ? TransactionSource.sms : TransactionSource.manual;
    
    return TransactionModel(
      id: id,
      amount: amount,
      type: type,
      source: source,
      category: map['category']?.toString() ?? 'Other',
      bank: map['bank']?.toString(),
      note: map['note']?.toString(),
      dateAD: DateTime.tryParse(map['dateAD']?.toString() ?? '') ?? DateTime.now(),
      dateBS: map['dateBS']?.toString() ?? '',
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'amount': amount,
    'type': type == TransactionType.debit ? 'debit' : 'credit',
    'source': source == TransactionSource.sms ? 'sms' : 'manual',
    'category': category,
    'bank': bank,
    'note': note,
    'dateAD': dateAD.toIso8601String(),
    'dateBS': dateBS,
    'createdAt': createdAt.toIso8601String(),
  };

  TransactionModel copyWith({
    double? amount,
    TransactionType? type,
    String? category,
    String? note,
    String? dateBS,
  }) {
    return TransactionModel(
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
