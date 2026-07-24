import '../../../core/error/result.dart';

abstract class SmsRepository {
  Future<Result<bool>> processSms(String sender, String body);
  Future<Result<bool>> importSms(String sender, String body);
  Future<Result<bool>> isAutoTrackEnabled();
  Future<Result<void>> setAutoTrackEnabled(bool enabled);
  Stream<bool> autoTrackStream();
}
