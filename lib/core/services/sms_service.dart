import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../models/transaction_model.dart';

class SmsService {
  static final SmsService _instance = SmsService._internal();
  factory SmsService() => _instance;
  SmsService._internal();

  FirebaseService? _firebaseService;

  FirebaseService get firebaseService {
    _firebaseService ??= FirebaseService.instance;
    return _firebaseService!;
  }

  Map<String, dynamic>? parseSmsManual(String sender, String body) {
    return _parseSms(sender, body);
  }

  DateTime? _extractDateFromBody(String body) {
    final lowerBody = body.toLowerCase();

    // Pattern 1: DD/MM/YYYY or DD-MM-YYYY (e.g., 25/08/2025) - most common
    var match = RegExp(r'(\d{1,2})[/\-](\d{1,2})[/\-](\d{4})').firstMatch(body);
    if (match != null) {
      try {
        final day = int.parse(match.group(1)!);
        final month = int.parse(match.group(2)!);
        final year = int.parse(match.group(3)!);
        if (day >= 1 &&
            day <= 31 &&
            month >= 1 &&
            month <= 12 &&
            year >= 2020) {
          return DateTime(year, month, day);
        }
      } catch (_) {}
    }

    // Pattern 1b: DD/MM/YY (e.g., 17/04/26) - Laxmi Sunrise format
    match = RegExp(r'(\d{1,2})[/\-](\d{1,2})[/\-](\d{2})\b').firstMatch(body);
    if (match != null) {
      try {
        final day = int.parse(match.group(1)!);
        final month = int.parse(match.group(2)!);
        final yearShort = int.parse(match.group(3)!);
        final year = 2000 + yearShort;
        if (day >= 1 &&
            day <= 31 &&
            month >= 1 &&
            month <= 12 &&
            year >= 2020) {
          return DateTime(year, month, day);
        }
      } catch (_) {}
    }

    // Pattern 2: DDMonYY (e.g., 01Dec25, 18Jul25, 26Mar26) - Nepali bank format
    match = RegExp(
      r'(\d{1,2})(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)(\d{2})',
      caseSensitive: false,
    ).firstMatch(lowerBody);
    if (match != null) {
      try {
        final day = int.parse(match.group(1)!);
        final monthStr = match.group(2)!;
        final yearShort = int.parse(match.group(3)!);
        final year = 2000 + yearShort;

        final monthMap = {
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
        final month = monthMap[monthStr];
        if (month != null && day >= 1 && day <= 31 && year >= 2020) {
          return DateTime(year, month, day);
        }
      } catch (_) {}
    }

    // Pattern 3: YYYY-MM-DD (ISO format)
    match = RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})').firstMatch(body);
    if (match != null) {
      try {
        final year = int.parse(match.group(1)!);
        final month = int.parse(match.group(2)!);
        final day = int.parse(match.group(3)!);
        if (day >= 1 &&
            day <= 31 &&
            month >= 1 &&
            month <= 12 &&
            year >= 2020) {
          return DateTime(year, month, day);
        }
      } catch (_) {}
    }

    // Pattern 4: on DD/MM/YYYY (e.g., "on 14/04/2026")
    match = RegExp(
      r'on\s+(\d{1,2})[/\-](\d{1,2})[/\-](\d{4})',
    ).firstMatch(body);
    if (match != null) {
      try {
        final day = int.parse(match.group(1)!);
        final month = int.parse(match.group(2)!);
        final year = int.parse(match.group(3)!);
        if (day >= 1 &&
            day <= 31 &&
            month >= 1 &&
            month <= 12 &&
            year >= 2020) {
          return DateTime(year, month, day);
        }
      } catch (_) {}
    }

    return null;
  }

  Future<bool> importSmsWithCheck(String sender, String body) async {
    final parsed = _parseSms(sender, body);
    if (parsed == null || parsed['amount'] == null) return false;

    final duplicateKey =
        '${sender}_${parsed['amount']}_${parsed['description']}';
    final isDuplicate = await firebaseService.checkDuplicateTransaction(
      duplicateKey,
    );
    if (isDuplicate) return false;

    final now = DateTime.now();
    final txDate = _extractDateFromBody(body) ?? now;
    final tx = TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: parsed['amount'] as double,
      type: parsed['type'] as TransactionType,
      source: TransactionSource.sms,
      category: parsed['category'] as String,
      note: parsed['description'] as String,
      dateAD: txDate,
      dateBS: '',
      createdAt: now,
    );

    debugPrint('[SmsService] Importing with date: $txDate');
    await firebaseService.addTransaction(duplicateKey, tx);
    return true;
  }

  Future<void> processSms(String sender, String body) async {
    debugPrint('[SmsService] Processing SMS from: $sender');

    bool autoTrackEnabled = true;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('[SmsService] No user logged in');
        return;
      }
      autoTrackEnabled = await firebaseService.getSmsAutoTrack();
    } catch (e) {
      debugPrint('[SmsService] getSmsAutoTrack error: $e, defaulting to true');
    }
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

    // Check for duplicate - use sender + amount + description as unique key
    final duplicateKey =
        '${sender}_${parsed['amount']}_${parsed['description']}';
    final isDuplicate = await firebaseService.checkDuplicateTransaction(
      duplicateKey,
    );
    if (isDuplicate) {
      debugPrint('[SmsService] Duplicate transaction skipped: $duplicateKey');
      return;
    }

    final tx = TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: parsed['amount'] as double,
      type: parsed['type'] as TransactionType,
      source: TransactionSource.sms,
      category: parsed['category'] as String,
      note: parsed['description'] as String,
      dateAD: txDate,
      dateBS: '',
      createdAt: now,
    );

    debugPrint('[SmsService] Transaction added with date: $txDate');
    await firebaseService.addTransaction(duplicateKey, tx);
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
        lowerBody.contains('deposited') ||
        lowerBody.contains('created') ||
        lowerBody.contains('credited') ||
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

    // More flexible amount patterns for Nepali SMS
    final amountPatterns = [
      RegExp(r'NPR\s*([\d,]+(?:\.\d+)?)', caseSensitive: false),
      RegExp(r'NRP\s*([\d,]+(?:\.\d+)?)', caseSensitive: false),
      RegExp(r'NPR\s*([\d,]+)', caseSensitive: false),
      RegExp(r'rs\.?\s*([\d,]+(?:\.\d+)?)', caseSensitive: false),
      RegExp(r'deposited[:\s]*npr\s*([\d,]+)', caseSensitive: false),
      RegExp(r'withdrawn[:\s]*npr\s*([\d,]+)', caseSensitive: false),
      RegExp(r'by\s*npr\s*([\d,]+)', caseSensitive: false),
      RegExp(r'amount[:\s]*rs\.?\s*([\d,]+)', caseSensitive: false),
      RegExp(r'debited[:\s]*rs\.?\s*([\d,]+)', caseSensitive: false),
      RegExp(r'credited[:\s]*rs\.?\s*([\d,]+)', caseSensitive: false),
      RegExp(r'paid[:\s]*rs\.?\s*([\d,]+)', caseSensitive: false),
      RegExp(r'transferred[:\s]*rs\.?\s*([\d,]+)', caseSensitive: false),
      RegExp(r'rs\s*([\d,]+)', caseSensitive: false),
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

    final isDebit =
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

    final isCredit =
        isCr ||
        lowerBody.contains('credited') ||
        lowerBody.contains('received') ||
        lowerBody.contains('deposit') ||
        lowerBody.contains('deposited') ||
        lowerBody.contains('transfer received') ||
        lowerBody.contains('loaded') ||
        lowerBody.contains('refund');

    if (isDebit) {
      type = TransactionType.debit;
    } else if (isCredit) {
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

    // Extract transaction ID for Laxmi Sunrise
    final txIdMatch = RegExp(r'#(\d+)').firstMatch(body);
    if (txIdMatch != null) {
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
    } else if (lowerBody.contains('laxmi sunrise') || lowerSender.contains('laxmi sunrise')) {
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
