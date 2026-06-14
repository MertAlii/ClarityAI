class UserProfile {
  String name;
  String aiProvider;
  bool onboardingCompleted;
  bool setupCompleted;
  String themeMode; // 'system', 'dark', 'light'

  UserProfile({
    required this.name,
    required this.aiProvider,
    this.onboardingCompleted = false,
    this.setupCompleted = false,
    this.themeMode = 'system',
  });
}
