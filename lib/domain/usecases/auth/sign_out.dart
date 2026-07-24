import '../../repositories/i_auth_repository.dart';

class SignOut {
  final AuthRepository _repository;
  SignOut(this._repository);

  Future<String?> call() async {
    final result = await _repository.signOut();
    return result.error;
  }
}