class OnboardingController {
  int step = 0;

  final List<Map<String, String>> onboardingData = [
    {
      "image": "assets/images/onboard1.png",
      "text": "Organize your daily progress",
    },
    {
      "image": "assets/images/onboard2.png",
      "text": "Track every change effortlessly",
    },
    {"image": "assets/images/onboard3.png", "text": "Your data. Always saved"},
  ];

  bool nextStep() {
    if (step < onboardingData.length - 1) {
      step++;
      return false;
    }
    return true;
  }
}
