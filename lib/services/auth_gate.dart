import 'package:btc_roundup/screens/biometric_lock_screen.dart';
import 'package:btc_roundup/screens/email_verification_screen.dart';
import 'package:btc_roundup/screens/home_page.dart';
import 'package:btc_roundup/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        // Not logged in
        if (user == null) {
          return const LoginScreen();
        }

        // Email not verified
        if (!user.emailVerified) {
          return const EmailVerificationScreen();
        }

        // Logged in + verified → biometric → home
        return BiometricLockScreen(
          child: HomePage(user: user),
        );
      },
    );
  }
}
