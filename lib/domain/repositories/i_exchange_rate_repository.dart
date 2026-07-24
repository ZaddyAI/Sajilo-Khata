import '../../../core/error/result.dart';

abstract class ExchangeRateRepository {
  Future<Result<double>> getUsdToNprRate();
  double convertNprToUsd(double nprAmount);
  double convertUsdToNpr(double usdAmount);
  bool get isAvailable;
}
