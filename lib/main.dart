import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BTC Round-Up',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: const Scaffold(
        body: Center(
          child: Text(
            'BTC Round-Up MVP',
            style: TextStyle(fontSize: 22),
          ),
        ),
      ),
    );
  }
}
