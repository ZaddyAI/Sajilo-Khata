import '../../../core/error/result.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Result<AppUser>> signInWithGoogle();
  Future<Result<AppUser>> signInWithEmail(String email, String password);
  Future<Result<AppUser>> signUpWithEmail(
    String email,
    String password,
    String name,
  );
  Future<Result<void>> signOut();
  Future<Result<AppUser>> getCurrentUser();
  Future<Result<void>> saveProfile(String name, String currency);
  Future<Result<Map<String, dynamic>?>> getProfile();
}
