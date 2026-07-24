import '../../entities/user.dart';
import '../../repositories/i_auth_repository.dart';

class SignInWithEmail {
  final AuthRepository _repository;
  SignInWithEmail(this._repository);

  Future<({AppUser? user, String? error})> call(String email, String password) async {
    final result = await _repository.signInWithEmail(email, password);
    return (user: result.data, error: result.error);
  }
}