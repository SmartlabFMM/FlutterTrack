import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  final bool vibrationEnabled;
  final bool soundEnabled;
  final bool autoSmsEnabled;

  const AppSettings({
    this.vibrationEnabled = true,
    this.soundEnabled     = true,
    this.autoSmsEnabled   = true,
  });

  AppSettings copyWith({
    bool? vibrationEnabled,
    bool? soundEnabled,
    bool? autoSmsEnabled,
  }) => AppSettings(
    vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    soundEnabled:     soundEnabled     ?? this.soundEnabled,
    autoSmsEnabled:   autoSmsEnabled   ?? this.autoSmsEnabled,
  );
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings()) {
    _load();
  }

  static const _kVib  = 'settings_vibration';
  static const _kSnd  = 'settings_sound';
  static const _kSms  = 'settings_auto_sms';

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    state = AppSettings(
      vibrationEnabled: p.getBool(_kVib) ?? true,
      soundEnabled:     p.getBool(_kSnd) ?? true,
      autoSmsEnabled:   p.getBool(_kSms) ?? true,
    );
  }

  Future<void> setVibration(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kVib, v);
    state = state.copyWith(vibrationEnabled: v);
  }

  Future<void> setSound(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kSnd, v);
    state = state.copyWith(soundEnabled: v);
  }

  Future<void> setAutoSms(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kSms, v);
    state = state.copyWith(autoSmsEnabled: v);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>(
      (_) => SettingsNotifier());
