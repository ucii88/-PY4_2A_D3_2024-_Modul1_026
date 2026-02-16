import 'package:flutter/material.dart';
import 'package:logbook_app/features/auth/login_view.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  int step = 1;

  void _nextStep() {
    if (step < 3) {
      setState(() {
        step++;
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginView()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Halaman Onboarding", style: TextStyle(fontSize: 20)),
            const SizedBox(height: 20),

            Text(
              "$step",
              style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 40),

            ElevatedButton(onPressed: _nextStep, child: const Text("Next")),
          ],
        ),
      ),
    );
  }
}
