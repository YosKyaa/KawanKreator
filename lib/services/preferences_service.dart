import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const _kIsFirstOpen = 'is_first_open';
  static const _kIsGuest = 'is_guest';
  static const _kNiche = 'pref_niche';
  static const _kPlatform = 'pref_platform';
  static const _kWeeklyTarget = 'pref_weekly_target';
  static const _kLastEmail = 'last_email';

  Future<bool> getIsFirstOpen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kIsFirstOpen) ?? true;
  }

  Future<void> setIsFirstOpen(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsFirstOpen, value);
  }

  Future<bool> getIsGuest() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kIsGuest) ?? false;
  }

  Future<void> setIsGuest(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsGuest, value);
  }

  Future<void> savePreferences({
    required String niche,
    required String platform,
    required int weeklyTarget,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kNiche, niche);
    await prefs.setString(_kPlatform, platform);
    await prefs.setInt(_kWeeklyTarget, weeklyTarget);
  }

  Future<Map<String, Object?>> getPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'niche': prefs.getString(_kNiche),
      'platform': prefs.getString(_kPlatform),
      'weeklyTarget': prefs.getInt(_kWeeklyTarget),
    };
  }

  Future<void> rememberEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastEmail, email);
  }

  Future<String?> getLastEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLastEmail);
  }
}
