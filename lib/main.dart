import 'package:btc_roundup/screens/home_page.dart';
import 'package:btc_roundup/screens/login_screen.dart';
import 'package:btc_roundup/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BTC Round-Up',
      theme: ThemeData(primarySwatch: Colors.orange),
      home: StreamBuilder(
        stream: AuthService().authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }

          if (snapshot.hasData) {
            return const HomePage();
          }

          return const LoginScreen();
        },
      ),
    );
  }
}
