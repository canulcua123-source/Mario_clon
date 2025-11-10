import 'package:shared_preferences/shared_preferences.dart';

class ProgressManager {
  static const String _levelKey = 'highestUnlockedLevel';

  /// Gets the highest unlocked level for the player.
  /// Defaults to '1-1' if no progress is saved yet.
  static Future<String> getHighestUnlockedLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_levelKey) ?? '1-1';
  }

  /// Saves the highest unlocked level for the player.
  static Future<void> saveHighestUnlockedLevel(String levelId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_levelKey, levelId);
  }
}
