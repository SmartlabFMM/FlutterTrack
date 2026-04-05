import 'package:shared_preferences/shared_preferences.dart';

/// Cache local léger via SharedPreferences.
/// Pour une vraie persistance offline, migrer vers sqflite.
class LocalDbService {
  LocalDbService._();

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // ── Booléens (réglages) ──────────────────────────────────
  static Future<void> setBool(String key, bool value) async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    await p.setBool(key, value);
  }

  static Future<bool> getBool(String key, {bool defaultValue = true}) async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    return p.getBool(key) ?? defaultValue;
  }

  // ── Chaînes ──────────────────────────────────────────────
  static Future<void> setString(String key, String value) async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    await p.setString(key, value);
  }

  static Future<String?> getString(String key) async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    return p.getString(key);
  }

  // ── Nettoyage ────────────────────────────────────────────
  static Future<void> clear() async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    await p.clear();
  }
}
