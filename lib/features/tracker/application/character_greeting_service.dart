class TrackerCharacter {
  final String name;
  final String emoji;
  final String? imageAsset;

  TrackerCharacter({required this.name, required this.emoji, this.imageAsset});
}

class CharacterGreetingService {
  static final Gigi = TrackerCharacter(name: 'Gigi', emoji: '🌸');
  static final Lily = TrackerCharacter(name: 'Lily', emoji: '🌱');
  static final Maya = TrackerCharacter(name: 'Maya', emoji: '🌪️');

  static TrackerCharacter getCharacter(String mode) {
    switch (mode) {
      case 'watching_waiting':
        return Lily;
      case 'irregular_support':
        return Maya;
      case 'active':
      default:
        return Gigi;
    }
  }

  static String getGreeting({
    required String mode,
    required String phase,
    required int streak,
    required bool hasLoggedToday,
    required int hour,
  }) {
    if (hasLoggedToday) {
      return "Great logging today! Come back tomorrow 🌸";
    }

    if (streak == 7) {
      return "Hey! You've been on a 7-day streak 🎉 Your predictions are getting really accurate now. Ready to log?";
    }
    
    if (streak == 30) {
      return "Unbelievable! A 30-day streak 🏆 You're a tracking pro. Let's keep the momentum going!";
    }

    if (mode == 'watching_waiting') {
      return "I'm in Watching & Waiting too. We're learning what's coming — together 🌱";
    }

    if (mode == 'irregular_support') {
      return "Every body has its own rhythm. Yours is just more unique — and that's completely okay.";
    }

    // Time of day greetings
    String timeGreeting;
    if (hour < 12) {
      timeGreeting = "Morning! ☀️";
    } else if (hour < 17) {
      timeGreeting = "Good afternoon! 🌤️";
    } else {
      timeGreeting = "Good evening! 🌙";
    }

    // Phase specific (Active mode)
    if (phase == 'ovulation') {
      return "Good morning! Your energy is probably peaking today ✨ — you're at ovulation. How are you feeling?";
    }

    if (phase == 'menstrual') {
      return "Your period has started. Remember to be extra kind to yourself today 💜";
    }

    return "$timeGreeting Ready to log your body's signals today?";
  }
}
