import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'email_verification_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool isLogin = true;
  bool _loading = false;

  void submit() async {
    setState(() => _loading = true);

    try {
      if (isLogin) {
        // Login
        await _authService.login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        // Check if verified after login
        final isVerified = await _authService.isEmailVerified();
        if (!isVerified && mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const EmailVerificationScreen()),
          );
          return;
        }
      } else {
        // Register - create account and send verification
        await _authService.register(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        await _authService.sendEmailVerification();

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const EmailVerificationScreen()),
          );
          return;
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text('BTC Round-Up')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Text(
                isLogin ? 'Welcome Back' : 'Create Account',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(),
              ),
              const SizedBox(height: 32),
              Text(
                isLogin
                    ? 'Login to access your Bitcoin savings'
                    : 'Start saving Bitcoin with round-ups',
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isLogin ? 'Login' : 'Create Account',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _loading
                    ? null
                    : () {
                        setState(() => isLogin = !isLogin);
                      },
                child: Text(
                  isLogin
                      ? 'Create an account'
                      : 'Already have an account? Login',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
