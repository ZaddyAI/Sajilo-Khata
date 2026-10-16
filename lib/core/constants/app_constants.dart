class AppConstants {
  static const String appName = 'Sajilo Khata';
  static const String appTagline = 'Smart expense tracking';
  static const String version = '1.0.16';
  static const String privacyPolicyUrl =
      'https://sajilokhata.gambhirpoudel.com.np/privacy-policy';
  static const String termsOfServiceUrl =
      'https://sajilokhata.gambhirpoudel.com.np/terms-of-service';

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
