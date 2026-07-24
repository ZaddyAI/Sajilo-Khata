import '../../domain/entities/user.dart';

class UserModel {
  final String uid;
  final String? email;
  final String? displayName;
  final String currency;
  final String? photoUrl;

  const UserModel({
    required this.uid,
    this.email,
    this.displayName,
    this.currency = 'NPR',
    this.photoUrl,
  });

  factory UserModel.fromFirebase(
    dynamic firebaseUser, {
    Map<String, dynamic>? profile,
  }) {
    return UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? firebaseUser.phoneNumber,
      displayName: profile?['name'] as String? ?? firebaseUser.displayName,
      currency: profile?['currency'] as String? ?? 'NPR',
      photoUrl: firebaseUser.photoURL,
    );
  }

  AppUser toEntity() {
    return AppUser(
      uid: uid,
      email: email,
      displayName: displayName,
      currency: currency,
      photoUrl: photoUrl,
    );
  }
}
