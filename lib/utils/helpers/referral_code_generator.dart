import 'dart:math';

class ReferralCodeGenerator {
  static final _random = Random();
  static const _characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  /// Generates a unique 7-character alphanumeric referral code
  /// Uses uppercase letters and numbers for better readability
  static String generateReferralCode() {
    return List.generate(
      7,
      (index) => _characters[_random.nextInt(_characters.length)],
    ).join();
  }

  /// Generates a referral code with custom length
  static String generateCustomLengthCode(int length) {
    return List.generate(
      length,
      (index) => _characters[_random.nextInt(_characters.length)],
    ).join();
  }
}
