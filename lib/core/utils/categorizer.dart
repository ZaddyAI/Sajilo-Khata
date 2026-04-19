// Auto-assigns a category to a transaction based on keywords in the note or
// bank name. Add more keywords as you discover common Nepali merchant names.

class Categorizer {
  static const _rules = <String, List<String>>{
    'Food & Dining': [
      'bhatbhateni',
      'bhat bhateni',
      'foodmandu',
      'bhoji',
      'restaurant',
      'cafe',
      'coffee',
      'pizza',
      'burger',
      'momo',
      'thakali',
      'hotel',
      'khaja ghar',
      'daraz food',
      'pathao food',
    ],
    'Transport': [
      'pathao',
      'indrive',
      'tootle',
      'bus',
      'taxi',
      'fuel',
      'petrol',
      'diesel',
      'parking',
      'metro',
    ],
    'Shopping': [
      'daraz',
      'sastodeal',
      'okdam',
      'bigmart',
      'salesways',
      'clothing',
      'fashion',
      'shoe',
      'mall',
      'shop',
      'store',
    ],
    'Utilities': [
      'nea',
      'electricity',
      'water',
      'nepal telecom',
      'ntc',
      'ncell',
      'smartcell',
      'broadband',
      'internet',
      'wifi',
      'dish home',
    ],
    'Health': [
      'hospital',
      'clinic',
      'pharmacy',
      'medical',
      'doctor',
      'lab',
      'bir hospital',
      'norvic',
      'om hospital',
    ],
    'Education': [
      'school',
      'college',
      'university',
      'tuition',
      'book',
      'library',
      'course',
      'exam fee',
    ],
    'Remittance / Transfer': [
      'imepay',
      'western union',
      'money transfer',
      'remit',
      'hundi',
      'transfer to',
      'sent to',
    ],
    'Salary / Income': ['salary', 'payroll', 'wages', 'stipend', 'bonus'],
    'Savings': ['saving', 'deposit', 'fixed deposit', 'fd'],
  };

  /// Returns the best-matching category or 'Other'
  static String categorize({String? note, String? bank}) {
    final haystack = '${note ?? ''} ${bank ?? ''}'.toLowerCase();
    for (final entry in _rules.entries) {
      for (final keyword in entry.value) {
        if (haystack.contains(keyword)) return entry.key;
      }
    }
    return 'Other';
  }
}
