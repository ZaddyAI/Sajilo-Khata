import 'dart:convert';
import 'package:http/http.dart' as http;

class ExchangeRateService {
  static final ExchangeRateService instance = ExchangeRateService._();
  factory ExchangeRateService() => instance;
  ExchangeRateService._();

  static const String _baseUrl = 'https://api.frankfurter.dev/v2';

  double? _usdToNpr;
  double? _nprToUsd;
  DateTime? _lastUpdated;
  static const Duration _cacheDuration = Duration(hours: 1);

  double? get usdToNpr => _usdToNpr;
  DateTime? get lastUpdated => _lastUpdated;

  Future<void> fetchUsdToNprRate() async {
    try {
      final now = DateTime.now();
      if (_lastUpdated != null &&
          now.difference(_lastUpdated!) < _cacheDuration &&
          _usdToNpr != null) {
        return;
      }

      final response = await http
          .get(Uri.parse('$_baseUrl/rate/USD/NPR'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _usdToNpr = (data['rate'] as num).toDouble();
        _nprToUsd = _usdToNpr != null && _usdToNpr! > 0 ? 1 / _usdToNpr! : null;
        _lastUpdated = now;
        print("data of usd $data");
      }
    } catch (e) {
      // Default fallback rate if API fails: 1 USD = 148 NPR
      if (_usdToNpr == null) {
        _usdToNpr = 148.0;
        _nprToUsd = 1 / _usdToNpr!;
      }
    }
  }

  double convertUsdToNpr(double usdAmount) {
    if (_usdToNpr == null) return usdAmount;
    return usdAmount * _usdToNpr!;
  }

  double convertNprToUsd(double nprAmount) {
    if (_nprToUsd == null) return nprAmount;
    return nprAmount * _nprToUsd!;
  }

  double convert(double amount, String fromCurrency, String toCurrency) {
    if (fromCurrency == toCurrency) return amount;

    if (fromCurrency == 'USD' && toCurrency == 'NPR') {
      return convertUsdToNpr(amount);
    }
    if (fromCurrency == 'NPR' && toCurrency == 'USD') {
      return convertNprToUsd(amount);
    }
    if (fromCurrency == 'USD' && toCurrency == 'NPR') {
      return convertUsdToNpr(amount);
    }

    return amount;
  }

  bool get isAvailable => _usdToNpr != null;
}
