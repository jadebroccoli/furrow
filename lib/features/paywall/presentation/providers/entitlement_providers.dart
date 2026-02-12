import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../settings/presentation/providers/settings_providers.dart';

const _isProKey = 'debug_is_pro';

/// Single source of truth: is the user a Pro subscriber?
/// Currently backed by SharedPreferences for debug/testing.
/// Wire to RevenueCat entitlements when ready for production.
final isProProvider = StateNotifierProvider<ProStatusNotifier, bool>((ref) {
  final prefsAsync = ref.watch(sharedPrefsProvider);
  final prefs = prefsAsync.valueOrNull;
  return ProStatusNotifier(prefs);
});

class ProStatusNotifier extends StateNotifier<bool> {
  ProStatusNotifier(this._prefs) : super(_loadInitial(_prefs));

  final SharedPreferences? _prefs;

  static bool _loadInitial(SharedPreferences? prefs) {
    return prefs?.getBool(_isProKey) ?? false;
  }

  /// Debug toggle
  void toggle() {
    state = !state;
    _prefs?.setBool(_isProKey, state);
  }

  /// Set explicitly (for RevenueCat integration later)
  void setPro(bool value) {
    state = value;
    _prefs?.setBool(_isProKey, value);
  }
}
