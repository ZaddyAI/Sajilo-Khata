import '../../../core/error/result.dart';

abstract class SyncRepository {
  Future<Result<void>> syncAll();
  Future<bool> get isOnline;
  Stream<bool> get connectivityStream;
  bool get hasPendingSync;
  Future<void> init();
  void dispose();
}
