import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_gate.dart';
import '../widgets/reusable_onbording_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  //Screen 1 — What the app does
                  OnboardPage(
                    icon: Icons.savings,
                    title: 'Save spare change in Bitcoin',
                    text:
                        'Enter what you spent.\nWe suggest a round-up amount you can save as Bitcoin. '
                            '\nThis app helps you voluntarily set aside small amounts of money and convert them into Bitcoin.\n'
                            'You decide when and how much to save. Nothing happens automatically without your confirmation.',
                  ),
                  //Screen 2 — Control & custody (MOST IMPORTANT)
                  OnboardPage(
                    icon: Icons.lock_outline,
                    title: 'You stay in control',
                    text:
                        'We do not access your bank account.'
                            '\nWe do not hold your Bitcoin.'
                            '\nAll actions require your explicit approval.'
                            '\nYour funds stay in wallets you control.',
                  ),
                  //Screen 3 — Not investment advice
                  OnboardPage(
                    icon: Icons.local_cafe,
                    title: 'Know the risks',
                    text:
                    'Bitcoin prices are volatile.'
                        '\nSavings can go up or down in value.'
                        '\nThis app does not provide financial, legal, or tax advice.',
                  ),
                  OnboardPage(
                    icon: Icons.local_cafe,
                    title: 'Small amounts add up',
                    text:
                        'Coffee €2.70\nRound-up €0.30\nSaved by you as Bitcoin.',
                  ),
                ],
              ),
            ),

            // Page indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                4,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.all(4),
                  width: _page == i ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _page == i ? Colors.orange : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_page < 3) {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    } else {
                      _finishOnboarding();
                    }
                  },

                  child: Text(_page < 3 ? 'Next' : 'Start saving'),
                    ),
                ),
              ),


            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
