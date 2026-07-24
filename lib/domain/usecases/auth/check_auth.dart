import '../../entities/user.dart';
import '../../repositories/i_auth_repository.dart';

class CheckAuth {
  final AuthRepository _repository;
  CheckAuth(this._repository);

  Future<({AppUser? user, String? error})> call() async {
    final result = await _repository.getCurrentUser();
    return (user: result.data, error: result.error);
  }
}