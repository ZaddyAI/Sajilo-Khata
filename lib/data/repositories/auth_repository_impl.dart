import '../../../core/error/result.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/repositories/i_auth_repository.dart';
import '../datasources/remote/firebase_auth_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthDataSource _remoteDataSource;

  AuthRepositoryImpl(this._remoteDataSource);

  @override
  Future<Result<AppUser>> signInWithGoogle() async {
    try {
      final userModel = await _remoteDataSource.signInWithGoogle();
      if (userModel == null) return Result.failure('Google sign-in cancelled');
      return Result.success(userModel.toEntity());
    } on Exception catch (e) {
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<AppUser>> signInWithEmail(String email, String password) async {
    try {
      final userModel = await _remoteDataSource.signInWithEmail(
        email,
        password,
      );
      return Result.success(userModel!.toEntity());
    } on Exception catch (e) {
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<AppUser>> signUpWithEmail(
    String email,
    String password,
    String name,
  ) async {
    try {
      final userModel = await _remoteDataSource.signUpWithEmail(
        email,
        password,
        name,
      );
      return Result.success(userModel!.toEntity());
    } on Exception catch (e) {
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _remoteDataSource.signOut();
      return Result.success(null);
    } on Exception catch (e) {
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<AppUser>> getCurrentUser() async {
    try {
      final userModel = await _remoteDataSource.getCurrentUser();
      if (userModel == null) return Result.failure('Not authenticated');
      return Result.success(userModel.toEntity());
    } on Exception catch (e) {
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<void>> saveProfile(String name, String currency) async {
    try {
      await _remoteDataSource.saveProfile(name, currency);
      return Result.success(null);
    } on Exception catch (e) {
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<Map<String, dynamic>?>> getProfile() async {
    try {
      final data = await _remoteDataSource.getProfile();
      return Result.success(data);
    } on Exception catch (e) {
      return Result.failure(e.toString());
    }
  }
}
