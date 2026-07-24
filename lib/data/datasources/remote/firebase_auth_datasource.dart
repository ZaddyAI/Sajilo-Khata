import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../models/user_model.dart';
import 'firebase_firestore_datasource.dart';

class FirebaseAuthDataSource {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _db;

  FirebaseAuthDataSource()
    : _auth = FirebaseAuth.instance,
      _googleSignIn = GoogleSignIn(
        serverClientId:
            '437548364812-gr0i8oigkuesqi5di6mp4trhsu8nebe0.apps.googleusercontent.com',
      ),
      _db = FirebaseFirestore.instance;

  Future<UserModel?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    await _ensureProfile(userCredential.user!);
    final profile = await _getProfileData(userCredential.user!.uid);
    return UserModel.fromFirebase(userCredential.user!, profile: profile);
  }

  Future<UserModel?> signInWithEmail(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final profile = await _getProfileData(credential.user!.uid);
    return UserModel.fromFirebase(credential.user!, profile: profile);
  }

  Future<UserModel?> signUpWithEmail(
    String email,
    String password,
    String name,
  ) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user!.updateDisplayName(name);
    await _saveProfileData(credential.user!.uid, name, 'NPR');
    return UserModel.fromFirebase(credential.user!);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    try {
      await _googleSignIn.disconnect();
    } catch (_) {
      await _googleSignIn.signOut();
    }
  }

  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    await _ensureProfile(user);
    final profile = await _getProfileData(user.uid);
    return UserModel.fromFirebase(user, profile: profile);
  }

  Future<void> saveProfile(String name, String currency) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _saveProfileData(uid, name, currency);
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _getProfileData(user.uid);
  }

  Future<void> _ensureProfile(User user) async {
    final doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) {
      await _saveProfileData(user.uid, user.displayName ?? 'User', 'NPR');
      await FirebaseFirestoreDataSource().createSampleData();
    }
  }

  Future<void> _saveProfileData(
    String uid,
    String name,
    String currency,
  ) async {
    await _db.collection('users').doc(uid).set({
      'name': name,
      'currency': currency,
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> _getProfileData(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }
}
