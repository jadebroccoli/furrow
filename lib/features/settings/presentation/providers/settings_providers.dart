import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Keys ────────────────────────────────────────────────────────
const _themeModeKey = 'theme_mode'; // 'system', 'light', 'dark'
const _tempUnitKey = 'temp_unit'; // 'F' or 'C'

/// Temperature unit enum
enum TempUnit {
  fahrenheit('F', '°F'),
  celsius('C', '°C');

  const TempUnit(this.code, this.label);
  final String code;
  final String label;
}

// ─── SharedPreferences provider (async init) ─────────────────────
final sharedPrefsProvider = FutureProvider<SharedPreferences>((ref) {
  return SharedPreferences.getInstance();
});

// ─── Theme mode ──────────────────────────────────────────────────
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final prefsAsync = ref.watch(sharedPrefsProvider);
  final prefs = prefsAsync.valueOrNull;
  return ThemeModeNotifier(prefs);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._prefs) : super(_loadInitial(_prefs));

  final SharedPreferences? _prefs;

  static ThemeMode _loadInitial(SharedPreferences? prefs) {
    final stored = prefs?.getString(_themeModeKey);
    switch (stored) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    _prefs?.setString(_themeModeKey, mode.name);
  }
}

// ─── Temperature unit ────────────────────────────────────────────
final tempUnitProvider =
    StateNotifierProvider<TempUnitNotifier, TempUnit>((ref) {
  final prefsAsync = ref.watch(sharedPrefsProvider);
  final prefs = prefsAsync.valueOrNull;
  return TempUnitNotifier(prefs);
});

class TempUnitNotifier extends StateNotifier<TempUnit> {
  TempUnitNotifier(this._prefs) : super(_loadInitial(_prefs));

  final SharedPreferences? _prefs;

  static TempUnit _loadInitial(SharedPreferences? prefs) {
    final stored = prefs?.getString(_tempUnitKey);
    if (stored == 'C') return TempUnit.celsius;
    return TempUnit.fahrenheit;
  }

  void setUnit(TempUnit unit) {
    state = unit;
    _prefs?.setString(_tempUnitKey, unit.code);
  }

  void toggle() {
    final next =
        state == TempUnit.fahrenheit ? TempUnit.celsius : TempUnit.fahrenheit;
    setUnit(next);
  }
}
