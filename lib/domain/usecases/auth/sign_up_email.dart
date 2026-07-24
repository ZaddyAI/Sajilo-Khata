import '../../entities/user.dart';
import '../../repositories/i_auth_repository.dart';

class SignUpWithEmail {
  final AuthRepository _repository;
  SignUpWithEmail(this._repository);

  Future<({AppUser? user, String? error})> call(String email, String password, String name) async {
    final result = await _repository.signUpWithEmail(email, password, name);
    return (user: result.data, error: result.error);
  }
}