import '../../entities/user.dart';
import '../../repositories/i_auth_repository.dart';

class SignInWithGoogle {
  final AuthRepository _repository;
  SignInWithGoogle(this._repository);

  Future<({AppUser? user, String? error})> call() async {
    final result = await _repository.signInWithGoogle();
    return (user: result.data, error: result.error);
  }
}