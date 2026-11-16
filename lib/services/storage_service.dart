import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyFreeScans = 'free_scans_remaining';
  static const String _keyIsPremium = 'is_premium_user';
  static const int defaultInitialFreeScans = 2;

  static Future<int> getRemainingFreeScans() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_keyFreeScans)) {
      await prefs.setInt(_keyFreeScans, defaultInitialFreeScans);
      return defaultInitialFreeScans;
    }
    return prefs.getInt(_keyFreeScans) ?? 0;
  }

  static Future<bool> isPremium() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsPremium) ?? false;
  }

  static Future<void> setPremium(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsPremium, value);
  }

  static Future<bool> canPerformScan() async {
    if (await isPremium()) return true;
    final remaining = await getRemainingFreeScans();
    return remaining > 0;
  }

  static Future<void> decrementScan() async {
    if (await isPremium()) return;
    final prefs = await SharedPreferences.getInstance();
    final current = await getRemainingFreeScans();
    if (current > 0) {
      await prefs.setInt(_keyFreeScans, current - 1);
    }
  }
}
