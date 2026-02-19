import 'package:flutter/material.dart';
import 'package:logbook_app/features/auth/login_view.dart';
import 'package:logbook_app/features/onboarding/onboarding_controller.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final OnboardingController controller = OnboardingController();

  void _nextStep() {
    bool isFinished = controller.nextStep();

    if (isFinished) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginView()),
      );
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 🔹 Skip Button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginView()),
                  );
                },
                child: const Text("Skip"),
              ),
            ),

            const Spacer(),

            Image.asset(
              controller.onboardingData[controller.step]["image"]!,
              height: 250,
            ),

            const SizedBox(height: 30),

            Text(
              controller.onboardingData[controller.step]["text"]!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 40),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                controller.onboardingData.length,
                (index) => Container(
                  margin: const EdgeInsets.all(4),
                  width: controller.step == index ? 12 : 8,
                  height: controller.step == index ? 12 : 8,
                  decoration: BoxDecoration(
                    color: controller.step == index ? Colors.blue : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 254, 166, 209),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: _nextStep,
              child: Text(
                controller.step == controller.onboardingData.length - 1
                    ? "Mulai"
                    : "Next",
              ),
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}
