class AppConstants {
  static const String appName = 'Sajilo Khata';
  static const String companyName = 'RedPixel Labs';
  static const String appTagline = 'Smart expense tracking';
  static const String version = '1.0.1+2';

  static const Duration cacheDuration = Duration(hours: 1);
  static const Duration syncDebounce = Duration(seconds: 10);

  static const double defaultExchangeRate = 148.0;

  static const List<String> currencies = ['NPR', 'USD'];

  static const List<String> transactionCategories = [
    'Food & Dining',
    'Transport',
    'Shopping',
    'Utilities',
    'Health',
    'Education',
    'Remittance / Transfer',
    'Salary / Income',
    'Savings',
    'Entertainment',
    'Groceries',
    'Other',
  ];
}