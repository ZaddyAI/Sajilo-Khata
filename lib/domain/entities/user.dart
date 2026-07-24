class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String currency;
  final String? photoUrl;

  const AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.currency = 'NPR',
    this.photoUrl,
  });

  AppUser copyWith({
    String? displayName,
    String? currency,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      currency: currency ?? this.currency,
      photoUrl: photoUrl,
    );
  }
}