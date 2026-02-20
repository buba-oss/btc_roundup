import 'package:btc_roundup/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add this getter
  User? get currentUser => _auth.currentUser;

  Future<User?> register(String email, String password) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = result.user;

    if (user != null) {
      final appUser = AppUser(uid: user.uid, email: email);
      await UserService().createUser(appUser);
    }

    return user;
  }

  Future<User?> login(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return result.user;
  }

  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<bool> isEmailVerified() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  Future<void> checkEmailVerified() async {
    await _auth.currentUser?.reload();
  }
}
