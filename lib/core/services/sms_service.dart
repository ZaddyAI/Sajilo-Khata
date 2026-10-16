import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/local/hive_datasource.dart';
import '../../data/datasources/remote/firebase_firestore_datasource.dart';
import '../../domain/entities/transaction.dart';

class SmsService {
  static final SmsService _instance = SmsService._internal();
  factory SmsService() => _instance;
  SmsService._internal();

  FirebaseFirestoreDataSource? _firestore;

  void setFirebaseDataSource(FirebaseFirestoreDataSource ds) {
    _firestore = ds;
  }

  FirebaseFirestoreDataSource get _db {
    _firestore ??= FirebaseFirestoreDataSource();
    return _firestore!;
  }

  /// Safe accessor - `FirebaseAuth.instance` throws when Firebase could not be
  /// initialised (offline start), which must never abort an SMS import.
  User? get _currentUser {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? parseSmsManual(String sender, String body) {
    return _parseSms(sender, body);
  }

  /// Test-only exposure of the internal date extraction.
  @visibleForTesting
  DateTime? extractDateForTest(String body) => _extractDateFromBody(body);

  DateTime? _dateOrNull(int? year, int? month, int? day) {
    if (year == null || month == null || day == null) return null;
    if (year < 2020 || month < 1 || month > 12 || day < 1 || day > 31) {
      return null;
    }
    return DateTime(year, month, day);
  }

  /// Normalises a day/month pair. Nepali banks mostly send DD/MM/YYYY but
  /// several banks and wallets (eSewa) send US style MM/DD/YYYY - detected when
  /// the second slot is above 12 (e.g. 10/15/2026 -> 15/10/2026).
  (int, int) _normaliseDayMonth(int day, int month) {
    if (month > 12 && day >= 1 && day <= 12) {
      return (month, day);
    }
    return (day, month);
  }

  DateTime? _extractDateFromBody(String body) {
    final lowerBody = body.toLowerCase();

    // Pattern 1: ISO date (e.g. 2026-06-11 10:43:20) - checked first so the
    // DD/MM/YY pattern cannot misread "2026-06-25" as 25/06/2011.
    var match = RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})').firstMatch(body);
    if (match != null) {
      final date = _dateOrNull(
        int.tryParse(match.group(1)!),
        int.tryParse(match.group(2)!),
        int.tryParse(match.group(3)!),
      );
      if (date != null) return date;
    }

    // Pattern 2: DD/MM/YYYY or DD-MM-YYYY (e.g. 25/08/2025, 10/15/2026)
    match = RegExp(r'(\d{1,2})[/\-](\d{1,2})[/\-](\d{4})').firstMatch(body);
    if (match != null) {
      final (day, month) = _normaliseDayMonth(
        int.tryParse(match.group(1)!) ?? 0,
        int.tryParse(match.group(2)!) ?? 0,
      );
      final date = _dateOrNull(int.tryParse(match.group(3)!), month, day);
      if (date != null) return date;
    }

    // Pattern 3: DD/MM/YY (e.g. 17/04/26) - Laxmi Sunrise format
    match = RegExp(r'(\d{1,2})[/\-](\d{1,2})[/\-](\d{2})\b').firstMatch(body);
    if (match != null) {
      final (day, month) = _normaliseDayMonth(
        int.tryParse(match.group(1)!) ?? 0,
        int.tryParse(match.group(2)!) ?? 0,
      );
      final date = _dateOrNull(
        2000 + (int.tryParse(match.group(3)!) ?? 0),
        month,
        day,
      );
      if (date != null) return date;
    }

    // Pattern 4: DDMonYY (e.g. 01Dec25, 18Jul25, 26Mar26) - Nepali bank format
    match = RegExp(
      r'(\d{1,2})(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)(\d{2})',
      caseSensitive: false,
    ).firstMatch(lowerBody);
    if (match != null) {
      const monthMap = {
        'jan': 1,
        'feb': 2,
        'mar': 3,
        'apr': 4,
        'may': 5,
        'jun': 6,
        'jul': 7,
        'aug': 8,
        'sep': 9,
        'oct': 10,
        'nov': 11,
        'dec': 12,
      };
      final date = _dateOrNull(
        2000 + (int.tryParse(match.group(3)!) ?? 0),
        monthMap[match.group(2)!],
        int.tryParse(match.group(1)!) ?? 0,
      );
      if (date != null) return date;
    }

    // Pattern 5: on DD/MM/YYYY (e.g. "on 14/04/2026")
    match = RegExp(
      r'on\s+(\d{1,2})[/\-](\d{1,2})[/\-](\d{4})',
    ).firstMatch(body);
    if (match != null) {
      final (day, month) = _normaliseDayMonth(
        int.tryParse(match.group(1)!) ?? 0,
        int.tryParse(match.group(2)!) ?? 0,
      );
      final date = _dateOrNull(int.tryParse(match.group(3)!), month, day);
      if (date != null) return date;
    }

    return null;
  }

  /// Reads the auto-track flag: Firestore when signed in, SharedPreferences for
  /// guests / offline sessions.
  Future<bool> _isAutoTrackEnabled(User? user) async {
    if (user != null) {
      try {
        return await _db.getSmsAutoTrack();
      } catch (e) {
        debugPrint('[SmsService] getSmsAutoTrack error: $e, defaulting to true');
      }
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('smsAutoTrack') ?? true;
  }

  /// True when this transaction was already imported (works for guests too -
  /// the cloud duplicate key is only available when signed in).
  bool _isDuplicateLocal(double amount, String note, DateTime date) {
    return HiveDataSource().containsSmsTransaction(amount, note, date);
  }

  Future<bool> importSmsWithCheck(String sender, String body) async {
    final parsed = _parseSms(sender, body);
    if (parsed == null || parsed['amount'] == null) return false;

    final amount = parsed['amount'] as double;
    final description = parsed['description'] as String;
    final duplicateKey = '${sender}_${amount}_$description';
    final user = _currentUser;

    final now = DateTime.now();
    final txDate = _extractDateFromBody(body) ?? now;

    // Local duplicate check (always) - keeps repeated data-range imports from
    // piling up duplicates, including in guest mode.
    if (_isDuplicateLocal(amount, description, txDate)) {
      debugPrint('[SmsService] Local duplicate skipped: $duplicateKey');
      return false;
    }

    if (user != null) {
      try {
        final isDuplicate = await _db.checkDuplicate(duplicateKey);
        if (isDuplicate) return false;
      } catch (_) {}
    }

    final tx = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      type: parsed['type'] as TransactionType,
      source: TransactionSource.sms,
      category: parsed['category'] as String,
      note: description,
      dateAD: txDate,
      dateBS: '',
      createdAt: now,
    );

    debugPrint('[SmsService] Importing with date: $txDate');
    HiveDataSource().saveTransaction(tx);
    if (user != null) {
      try {
        await _db.addTransaction(duplicateKey, tx);
        HiveDataSource().markAsSynced(tx.id, 'transaction');
      } catch (e) {
        debugPrint(
          '[SmsService] Remote addTransaction error (saved locally): $e',
        );
      }
    }
    return true;
  }

  Future<void> processSms(String sender, String body) async {
    debugPrint('[SmsService] Processing SMS from: $sender');

    final user = _currentUser;
    final autoTrackEnabled = await _isAutoTrackEnabled(user);
    debugPrint('[SmsService] Auto-track enabled: $autoTrackEnabled');
    if (!autoTrackEnabled) return;

    final parsed = _parseSms(sender, body);
    if (parsed == null) {
      debugPrint('[SmsService] Could not parse SMS: $body');
      return;
    }

    debugPrint('[SmsService] Parsed: $parsed');

    final now = DateTime.now();
    final txDate = _extractDateFromBody(body) ?? now;
    final amount = parsed['amount'] as double;
    final description = parsed['description'] as String;

    // Check for duplicate - sender + amount + description as unique key
    final duplicateKey = '${sender}_${amount}_$description';
    if (_isDuplicateLocal(amount, description, txDate)) {
      debugPrint('[SmsService] Duplicate transaction skipped: $duplicateKey');
      return;
    }
    if (user != null) {
      try {
        final isDuplicate = await _db.checkDuplicate(duplicateKey);
        if (isDuplicate) {
          debugPrint(
            '[SmsService] Duplicate transaction skipped: $duplicateKey',
          );
          return;
        }
      } catch (_) {}
    }

    final tx = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      type: parsed['type'] as TransactionType,
      source: TransactionSource.sms,
      category: parsed['category'] as String,
      note: description,
      dateAD: txDate,
      dateBS: '',
      createdAt: now,
    );

    debugPrint('[SmsService] Transaction added with date: $txDate');
    HiveDataSource().saveTransaction(tx);
    if (user != null) {
      try {
        await _db.addTransaction(duplicateKey, tx);
        HiveDataSource().markAsSynced(tx.id, 'transaction');
      } catch (e) {
        debugPrint(
          '[SmsService] Remote add transaction error (saved locally): $e',
        );
      }
    }
    debugPrint('[SmsService] Transaction added: ${tx.id}');
  }

  static List<String> selectedGroups = [];

  void updateSelectedGroups(List<String> groups) {
    selectedGroups = groups.map((g) => g.toLowerCase()).toList();
  }

  Map<String, dynamic>? _parseSms(String sender, String body) {
    final lowerBody = body.toLowerCase();
    final lowerSender = sender.toLowerCase();

    debugPrint('[SmsService] Parsing: sender=$sender body=$body');

    // Check if sender is in selected groups
    bool isSelectedGroup =
        selectedGroups.isEmpty ||
        selectedGroups.any(
          (g) =>
              lowerSender == g.toLowerCase() ||
              lowerSender.contains(g.toLowerCase()),
        );

    if (!isSelectedGroup && selectedGroups.isNotEmpty) {
      debugPrint(
        '[SmsService] Sender not in selected groups, skipping: $sender',
      );
      return null;
    }

    // Only parse transaction-related SMS
    final isTransactionSms =
        lowerBody.contains('withdrawn') ||
        lowerBody.contains('withdraw') ||
        lowerBody.contains('debited') ||
        lowerBody.contains('debit') ||
        lowerBody.contains('deposited') ||
        lowerBody.contains('deposit') ||
        lowerBody.contains('created') ||
        lowerBody.contains('credited') ||
        lowerBody.contains('credit') ||
        lowerBody.contains('payment') ||
        lowerBody.contains('loaded') ||
        lowerBody.contains('paid') ||
        lowerBody.contains('transfer') ||
        lowerBody.contains('esewa load') ||
        lowerBody.contains('atm') ||
        lowerBody.contains('vcp') ||
        lowerBody.contains('casba') ||
        lowerBody.contains('nqr') ||
        lowerBody.contains('nrs') ||
        lowerBody.contains('nrp') ||
        lowerBody.contains('npr');

    if (!isTransactionSms) {
      debugPrint('[SmsService] Not a transaction SMS, skipping');
      return null;
    }

    double? amount;
    String? description;
    String? category;
    TransactionType? type;

    // Ordered amount patterns for Nepali SMS - most specific first, generic
    // thousands-grouped amounts (eSewa "amount 3,000.00", bank "Deposited
    // 11,000.00 from A/C:...") as the final fallback.
    final amountPatterns = [
      RegExp(r'NPR\s*([\d,]+(?:\.\d+)?)', caseSensitive: false),
      RegExp(r'NRP\s*([\d,]+(?:\.\d+)?)', caseSensitive: false),
      RegExp(r'by\s*npr\s*([\d,]+(?:\.\d+)?)', caseSensitive: false),
      RegExp(r'amount[:\s]*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false),
      RegExp(r'rs\.?\s*([\d,]+(?:\.\d+)?)', caseSensitive: false),
      RegExp(r'deposited[:\s]*npr\s*([\d,]+)', caseSensitive: false),
      RegExp(
        r'deposited(?:\s+by)?[:\s]+([\d,]+(?:\.\d{1,2})?)',
        caseSensitive: false,
      ),
      RegExp(r'withdrawn[:\s]*npr\s*([\d,]+)', caseSensitive: false),
      RegExp(r'amount[:\s]*rs\.?\s*([\d,]+)', caseSensitive: false),
      RegExp(r'debited[:\s]*rs\.?\s*([\d,]+)', caseSensitive: false),
      RegExp(r'credited[:\s]*rs\.?\s*([\d,]+)', caseSensitive: false),
      RegExp(r'paid[:\s]*rs\.?\s*([\d,]+)', caseSensitive: false),
      RegExp(r'transferred[:\s]*rs\.?\s*([\d,]+)', caseSensitive: false),
      RegExp(r'rs\s*([\d,]+)', caseSensitive: false),
      RegExp(r'\b(\d{1,3}(?:,\d{3})+(?:\.\d{1,2})?)\b'),
    ];

    for (final pattern in amountPatterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        final amountStr = match.group(1)?.replaceAll(',', '');
        amount = double.tryParse(amountStr ?? '');
        debugPrint('[SmsService] Found amount: $amount');
        if (amount != null && amount > 0) break;
      }
    }

    if (amount == null || amount <= 10) {
      debugPrint('[SmsService] Amount too small (<=10), skipping');
      return null;
    }

    // Skip promotional amount (WorldLink Rs 12,995)
    if (amount >= 12000 && lowerBody.contains('limited-time')) {
      debugPrint('[SmsService] Skipping promotional SMS');
      return null;
    }

    // Transaction type detection (Dr = Debit/Withdrawal, Cr = Credit/Deposit)
    final isDr = RegExp(r'\bDr\b').hasMatch(body);
    final isCr = RegExp(r'\bCr\b').hasMatch(body);

    final hasCreditMarker =
        isCr ||
        lowerBody.contains('credited') ||
        lowerBody.contains('received') ||
        lowerBody.contains('deposited') ||
        lowerBody.contains('deposit') ||
        lowerBody.contains('transfer received') ||
        lowerBody.contains('loaded') ||
        lowerBody.contains('refund');

    final hasDebitMarker =
        isDr ||
        lowerBody.contains('debited') ||
        lowerBody.contains('paid') ||
        lowerBody.contains('payment') ||
        lowerBody.contains('transfer sent') ||
        lowerBody.contains('withdrawn') ||
        lowerBody.contains('withdraw') ||
        lowerBody.contains('purchase') ||
        lowerBody.contains('spent') ||
        lowerBody.contains(' wd') ||
        lowerBody.contains('-cash');

    if (isDr && !isCr) {
      type = TransactionType.debit;
    } else if (isCr && !isDr) {
      type = TransactionType.credit;
    } else if (hasCreditMarker && hasDebitMarker) {
      // Both markers present (e.g. "payment received") - prefer the wording
      // that names the money movement.
      type =
          lowerBody.contains('credited') ||
              lowerBody.contains('deposited') ||
              lowerBody.contains('received')
          ? TransactionType.credit
          : TransactionType.debit;
    } else if (hasCreditMarker) {
      type = TransactionType.credit;
    } else {
      type = TransactionType.debit;
    }

    debugPrint('[SmsService] Type: $type (Dr=$isDr, Cr=$isCr)');

    // Extract sender name for prefix
    String senderName = sender;

    // Extract remarks from SMS
    String remarks = '';
    final remarksMatch = RegExp(
      r'Remarks?[:\s]*(.+?)(?:\n|$)',
      caseSensitive: false,
    ).firstMatch(body);
    if (remarksMatch != null) {
      remarks = remarksMatch.group(1)?.trim() ?? '';
    }

    // Fallback reference: "Txn ID : BYZVMDUPOYH", "TX ID: 4Z6SQPS3KXU", ...
    if (remarks.isEmpty) {
      final refMatch = RegExp(
        r'(?:txn|tx|transaction|ref(?:erence)?|utr|ibft)\s*(?:id|no\.?|#)?\s*[:#-]?\s*([A-Za-z0-9]{4,})',
        caseSensitive: false,
      ).firstMatch(body);
      if (refMatch != null) {
        remarks = refMatch.group(1) ?? '';
      }
    }

    // Category and description based on sender and content
    if (lowerBody.contains('esewa load')) {
      category = 'Food & Dining';
      description = remarks.isNotEmpty ? '$senderName - $remarks' : senderName;
    } else if (lowerBody.contains('esewa') || lowerSender.contains('esewa')) {
      category = 'Food & Dining';
      description = remarks.isNotEmpty ? '$senderName - $remarks' : senderName;
    } else if (lowerBody.contains('khalti') || lowerSender.contains('khalti')) {
      category = 'Shopping';
      description = remarks.isNotEmpty ? '$senderName - $remarks' : senderName;
    } else if (lowerBody.contains('imepay') || lowerBody.contains('ime pay')) {
      category = 'Shopping';
      description = remarks.isNotEmpty ? '$senderName - $remarks' : senderName;
    } else if (lowerBody.contains('fonepay') ||
        lowerBody.contains('fone pay')) {
      category = type == TransactionType.credit
          ? 'Salary / Income'
          : 'Remittance / Transfer';
      description = remarks.isNotEmpty
          ? '$senderName - $remarks'
          : '$senderName - FonePay';
    } else if (lowerBody.contains('atm withdrawal') ||
        lowerBody.contains('atm wdl')) {
      category = 'Transport';
      description = '$senderName - ATM';
    } else if (lowerBody.contains('nic asia') ||
        lowerSender.contains('nic asia')) {
      category = type == TransactionType.credit
          ? 'Salary / Income'
          : 'Remittance / Transfer';
      description = remarks.isNotEmpty ? '$senderName - $remarks' : senderName;
    } else if (lowerBody.contains('nabil') || lowerSender.contains('nabil')) {
      category = type == TransactionType.credit
          ? 'Salary / Income'
          : 'Remittance / Transfer';
      description = remarks.isNotEmpty ? '$senderName - $remarks' : senderName;
    } else if (lowerBody.contains('laxmi sunrise') ||
        lowerSender.contains('laxmi sunrise')) {
      category = type == TransactionType.credit
          ? 'Salary / Income'
          : 'Remittance / Transfer';
      description = remarks.isNotEmpty ? '$senderName - $remarks' : senderName;
    } else if (lowerBody.contains('bank') || lowerSender.contains('bank')) {
      category = type == TransactionType.credit
          ? 'Salary / Income'
          : 'Remittance / Transfer';
      description = remarks.isNotEmpty ? '$senderName - $remarks' : senderName;
    } else if (lowerBody.contains('mpay')) {
      category = 'Remittance / Transfer';
      description = remarks.isNotEmpty ? '$senderName - $remarks' : senderName;
    } else if (lowerBody.contains('casba') || lowerBody.contains('asba fee')) {
      category = 'Other';
      description = '$senderName - ASBA';
    } else if (lowerBody.contains('nqr')) {
      category = 'Remittance / Transfer';
      description = remarks.isNotEmpty
          ? '$senderName - $remarks'
          : '$senderName - NQR';
    } else if (lowerSender.contains('wlink') ||
        lowerSender.contains('worldlink')) {
      category = 'Utilities';
      description = '$senderName - Internet';
    } else if (lowerSender.contains('ncell')) {
      category = 'Utilities';
      description = '$senderName - Recharge';
    } else {
      category = 'Other';
      description = remarks.isNotEmpty ? '$senderName - $remarks' : senderName;
    }

    return {
      'amount': amount,
      'description': description,
      'category': category,
      'type': type,
    };
  }
}
