import 'package:flutter/material.dart';

class OnboardPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const OnboardPage({
    super.key,
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 72, color: Colors.orange),
          const SizedBox(height: 32),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}